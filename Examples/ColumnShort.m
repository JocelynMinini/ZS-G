clc
clear 
ZS_G
uqlab
clc

t0 = tic;

% Load all models and inputs
All_Inputs = ZS_createInput_fun;
All_Models = ZS_createModel_fun;

model = 'shortcolumn';

Input       = All_Inputs.(model);
trueModel   = All_Models.(model);
trueModelFE = All_Models.shortcolumnFE;

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


%% Common options both analytical and FE
metaType = 'PCE';
mu       = 6;
alpha    = 0.05;
[R_01,level,errorInput] = ZS_Grid.get_credible_interval(Input,0.01);

%% Error analysis - Analytical model
% Options for surrogate model
opts.MetaType = metaType;
opts.alpha    = alpha;
opts.mu       = mu;
opts.Model    = trueModel;
opts.Input    = Input;
Replicates    = 1;
PCOpts        = ZS_createPCOpts(opts,Replicates);
n             = length(PCOpts);

% Options for L1 norm
L1_Opts.Input    = Input;
L1_Opts.NSamples = 10^5;
L1_Opts.Type     = 'L1';
L1_Opts.Level    = level;

% Options for C0 solver
C0_Opts.optimOpts.Display        = 'off';
C0_Opts.optimOpts.SwarmSize      = 300;
C0_Opts.optim_opts.UseVectorized = true;
C0_Opts.support                  = R_01;
C0_Opts.d                        = size(Input.Marginals,2);
C0_Opts.Input                    = Input;
C0_Opts.Level                    = level;

L1   = zeros(n,1);
C0   = L1;
LOO  = L1;
XC0  = zeros(n,d);

%p = parpool(64);

for i = 1:n
    PCE                = uq_createModel(PCOpts{i},'-private');
    LOO(i)             = PCE.Error.ModifiedLOO;
    L1(i)              = ZS_get_L_norm(trueModel,PCE,L1_Opts);
    [XC0(i,:),C0(i)]   = ZS_get_C0(trueModel,PCE,C0_Opts);
end
%RES = ZS_storeResults('MATLAB',RES,LOO,L1,C0,XC0);
%delete(p)

%{
%% Error analysis - FE model

p = parpool(32);
opts.Model    = trueModelFE;
Replicates    = 10;
opts.nThread  = 32;
PCOpts        = ZS_createPCOpts(opts,Replicates);
n             = length(PCOpts);
X_Validation  = ZS_getSubsample(Input,level,100);
Y_FE          = cell2mat(ZS_parallel_evalModel(trueModelFE,X_Validation));

for i = 1:length(PCOpts)
    PCE          = uq_createModel(PCOpts{i},'-private');
    Y_Meta       = uq_evalModel(PCE,X_Validation);
    
    % LOO error
    LOO(end+1)       = PCE.Error.ModifiedLOO;

    % C0 error
    [tempC0,idx] = max(abs(Y_FE-Y_Meta)); 
    XC0(end+1,:)     = X_Validation(idx,:);
    C0(end+1)        = tempC0; 
    
    % L1 error
    L1(end+1)        = mean(abs(Y_FE-Y_Meta));
end
%RES = ZS_storeResults('FE',RES,LOO,L1,C0,XC0);


delete(p)
toc(t0)

%{
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
%}
%}