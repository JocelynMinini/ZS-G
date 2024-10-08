clc
clear 
ZS_G
uqlab

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
clc

%% Sensitivity analysis
%{
OPTS.Type                  = 'Sensitivity';
OPTS.Method                = 'Kucherenko';
OPTS.Model                 = trueModel;
OPTS.Input                 = Input;
OPTS.Kucherenko.SampleSize = 100000;
OPTS.Kucherenko.Sampling   = 'lhs';
Kucherenko                 = uq_createAnalysis(OPTS,'-private');
clear OPTS

RES.Sensitivity.Total = Kucherenko.Results.Total;
RES.Sensitivity.First = Kucherenko.Results.FirstOrder;
%}

RES.Sensitivity.Total = [0.263449900577155 0.0542529616337359 0.369734032889432];
RES.Sensitivity.First = [0.246042193928020 0.371156614813515 0.675758987997602];


%% Common options both analytical and FE
metaType   = 'PCE';
alpha      = 0.05;
HDR        = ZS_Grid.get_credible_interval(Input,0.01);
R_01       = HDR.Support;
level      = HDR.Level;

%% Error analysis - Analytical model
% Options for surrogate model
opts.MetaType = metaType;
opts.alpha    = alpha;
opts.Model    = trueModel;
opts.Input    = Input;
Replicates    = 100;

% Options for L1 norm
L1_Opts.Method   = 'Continous';
L1_Opts.Type     = 'L1';
L1_Opts.Input    = Input;
L1_Opts.NSamples = 10^5;
L1_Opts.Level    = level;

% Options for C0 solver
C0_Opts.Method                   = 'Continous';
C0_Opts.Support                  = R_01;
C0_Opts.Input                    = Input;
C0_Opts.Level                    = level;
C0_Opts.optimOpts.Display        = 'off';
C0_Opts.optimOpts.SwarmSize      = 300;
C0_Opts.optimOpts.UseVectorized  = true;

try
p = parpool(64);
end

fprintf('\n\n')
fprintf('MU = ')

mu = 1;
while true

    N = ZS_SparseGrid.get_number_of_nodes(d,mu,@(k)2.*k-1);
    if N > 1000
        break
    end

    fprintf(string(mu))
    fprintf(' ')

    opts.mu   = mu;
    PCOpts    = ZS_createPCOpts(opts,Replicates);
    n         = length(PCOpts);
    L1        = zeros(n,1);
    C0        = L1;
    LOO       = L1;
    Degree    = L1;
    MaxDegree = L1;
    XC0       = zeros(n,d);

    parfor i = 1:n
        PCE              = uq_createModel(PCOpts{i},'-private');
        LOO(i)           = PCE.Error.ModifiedLOO;
        Degree(i)        = PCE.Internal.PCE.BestDegree;
        MaxDegree(i)     = max(PCE.Internal.PCE.DegreeArray);
        L1(i)            = ZS_get_L_norm(trueModel,PCE,L1_Opts);
        [XC0(i,:),C0(i)] = ZS_get_C0(trueModel,PCE,C0_Opts);
    end
    RES = ZS_storeResults(RES,mu,LOO,L1,C0,XC0,N,Degree,MaxDegree);

    mu = mu + 1;

end
fprintf('\n\n')
ZS_save('ColumnShort_analytical_01.mat',RES)
try
delete(p)
end
toc(t0)

%% Error analysis - FE model
%{
try
p = parpool(32);
end

opts.Model    = trueModelFE;
Replicates    = 10;
PCOpts        = ZS_createPCOpts(opts,Replicates);
n             = length(PCOpts);

% Seting up the validation set
X_Validation  = ZS_getSubsample(Input,level,300);
Y_Validation  = cell2mat(ZS_parallel_evalModel(trueModelFE,X_Validation));

% Options for L1 norm
L1_Opts.Method       = 'Discrete';
L1_Opts.X_Validation = X_Validation; 
L1_Opts.Y_Validation = Y_Validation; 

% Options for C0 solver
C0_Opts.Method       = 'Discrete';
C0_Opts.X_Validation = X_Validation; 
C0_Opts.Y_Validation = Y_Validation; 

for i = 1:n
    PCE              = uq_createModel(PCOpts{i},'-private');
    LOO(i)           = PCE.Error.ModifiedLOO;
    L1(i)            = ZS_get_L_norm(trueModel,PCE,L1_Opts);
    [XC0(i,:),C0(i)] = ZS_get_C0(trueModel,PCE,C0_Opts);
end
RES = ZS_storeResults('FE',RES,LOO,L1,C0,XC0);

try
delete(p)
end

ZS_save('model_ShortColumn.mat',RES)
%}