clc
clear 
ZS_G

% Load all models and inputs
All_Inputs = ZS_createInput_fun;
All_Models = ZS_createModel_fun;

model = 'shortcolumn';

Input     = All_Inputs.(model);
trueModel = All_Models.(model);

d = size(Input.Marginals,2);

clear All_Models All_Inputs

%% Sensitivity analysis
OPTS.Type                  = 'Sensitivity';
OPTS.Method                = 'Kucherenko';
OPTS.Model                 = trueModel;
OPTS.Input                 = Input;
OPTS.Kucherenko.SampleSize = 100000;
OPTS.Kucherenko.Sampling   = 'lhs';
Kucherenko                 = uq_createAnalysis(OPTS,'-private');
clear OPTS

RES.Kucherenko.Total = Kucherenko.Results.Total;
RES.Kucherenko.First = Kucherenko.Results.FirstOrder;

%% Error analysis
% Options for surrogate model
opts.MetaType = 'PCE';
opts.Model    = trueModel;
opts.Input    = Input;
opts.alpha    = 0.05;
opts.mu       = 6;
Replicates    = 1;
PCOpts        = ZS_createPCOpts(opts,Replicates);

n = length(PCOpts);

[R_01,level,errorInput] = ZS_Grid.get_credible_interval(Input,0.01);

% Options for L1 norm
L1_Opts.Input    = Input;
L1_Opts.NSamples = 10^5;
L1_Opts.Type     = 'L1';
L1_Opts.Level    = level;

% Options for C0 solver
C0_Opts.optimOpts.Display     = 'off';
C0_Opts.optimOpts.SwarmSize   = 300;
optim_opts.UseVectorized      = true;
C0_Opts.support               = R_01;
C0_Opts.d                     = size(Input.Marginals,2);
C0_Opts.Input                 = Input;
C0_Opts.Level                 = level;

L1    = zeros(n,1);
C0    = L1;
LOO   = L1;
XC0   = zeros(n,d);

for i = 1:n
    PCE                = uq_createModel(PCOpts{i},'-private');
    LOO(i)             = PCE.Error.ModifiedLOO;
    L1(i)              = ZS_get_L_norm(trueModel,PCE,L1_Opts);
    [XC0(i,:),C0(i)]   = ZS_get_C0(trueModel,PCE,C0_Opts);
end


%% Save results
errors = {'LOO','L1','C0','XC0'};
for i = 1:length(errors)
        C = cell(1,8);
        C(:) = {errors{i}};
        toEval = ['RES.%s.Random  = %s(1:Replicates,:);\n'...
                  'RES.%s.Uniform = %s(Replicates+1:2*Replicates,:);\n'...
                  'RES.%s.Smolyak = %s(end-1,:);\n'...
                  'RES.%s.Isoprob = %s(end,:);\n'...
                  ];
        toEval = sprintf(toEval,C{:});
        eval(toEval)
end

filename = ['model_',model,'_',opts.MetaType,'_',char(string(opts.mu))];
ZS_save(filename,RES)