clc
clear 
ZS_G
uqlab

t0 = tic;

% Load all models and inputs
All_Inputs = ZS_createInput_fun;
All_Models = ZS_createModel_fun;

model = 'trussstructure';

Input       = All_Inputs.(model);
trueModel   = All_Models.(model);
trueModelFE = All_Models.trussstructureFE;

clear All_Models All_Inputs
clc

%% Sensitivity analysis
RES.Sensitivity.Total = [0.374 0.0126 0.371 0.0125 0.004 0.0377 0.0777 0.0778 0.0376 0.0047];
RES.Sensitivity.First = [0.3638 0.0051 0.3624 0.0055 -0.0019 0.02922 0.0717 0.0692 0.0297 -0.0025];

%% Redefining the input
keep         = [1 3]; % keep these variables
reducedInput = ZS_reduceInput(Input,keep);
d            = size(reducedInput.Marginals,2);

%% Common options both analytical and FE
metaType   = 'PCE';
alpha      = 0.05;
HDR        = ZS_Grid.get_credible_interval(reducedInput,0.01);
R_01       = HDR.Support;
level      = HDR.Level;

%% Error analysis - Analytical model
rng("default")
% Options for surrogate model
opts.MetaType = metaType;
opts.alpha    = alpha;
opts.Model    = trueModel;
opts.Input    = reducedInput;
Replicates    = 100;

% Options for L1 norm
L1_Opts.Method   = 'Continous';
L1_Opts.Type     = 'L1';
L1_Opts.Input    = reducedInput;
L1_Opts.NSamples = 10^5;
L1_Opts.Level    = level;

% Options for C0 solver
C0_Opts.Method                   = 'Continous';
C0_Opts.Support                  = R_01;
C0_Opts.Input                    = reducedInput;
C0_Opts.Level                    = level;
C0_Opts.optimOpts.Display        = 'off';
C0_Opts.optimOpts.SwarmSize      = 300;
C0_Opts.optimOpts.UseVectorized  = false;

try
p = parpool(64);
end

fprintf('\n\n')
fprintf('   MU = [')

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
        [minLOO,idx]     = min(PCE.Internal.PCE.OLS.LOO);
        if PCE.Internal.PCE.Degree ~= PCE.Internal.PCE.DegreeArray(idx)
            disp('DEGREE ADAPTIVITY FAILS !')
        end
        LOO(i)           = PCE.Error.ModifiedLOO;
        Degree(i)        = PCE.Internal.PCE.BestDegree;
        MaxDegree(i)     = max(PCE.Internal.PCE.DegreeArray);
        L1(i)            = ZS_get_L_norm(trueModel,PCE,L1_Opts);
        [XC0(i,:),C0(i)] = ZS_get_C0(trueModel,PCE,C0_Opts);
    end
    RES = ZS_storeResults(RES,mu,LOO,L1,C0,XC0,N,Degree,MaxDegree);

    mu = mu + 1;

end
ZS_save('Trussstructure_analytical_01.mat',RES)
try
delete(p)
end