clc
clear 
ZS_G
uqlab
clc
t0 = tic;

% Load all models and inputs
All_Inputs = ZS_createInput_fun;
All_Models = ZS_createModel_fun;

model = 'tunnel';

Input       = All_Inputs.(model);
trueModel   = All_Models.(model);
%trueModelFE = All_Models.([model,'FE']);

clear All_Models All_Inputs
clc

%% Sensitivity analysis
%{
OPTS.Type                  = 'Sensitivity';
OPTS.Method                = 'Sobol';
OPTS.Model                 = trueModel;
OPTS.Input                 = Input;
OPTS.Sobol.SampleSize      = 100000;
OPTS.Sobol.Sampling        = 'lhs';
Kucherenko                 = uq_createAnalysis(OPTS,'-private');
clear OPTS

RES.Sensitivity.Total = Kucherenko.Results.Total;
RES.Sensitivity.First = Kucherenko.Results.FirstOrder;
%}

RES.Sensitivity.Total = [0.0549221397294056 0.00101788965498939 0.326082695923257 0.000733436570370505 0.0295918177621310 0.226681801069092 0.000240434702789560 0.482881794532767];
RES.Sensitivity.First = [0.0169018698538586 0.00263923132288153 0.263879293345380 0.00227473977030512 0.0185174271965168 0.176260609943854 0.00253947596818229 0.385939614264741];


%% Redefining the input
keep = [3 6 8]; % keep these variables
rmv  = setdiff(1:length(Input.Marginals),keep); % remove these

OPTS.Marginals = Input.Marginals(keep);
OPTS.Marginals = rmfield(OPTS.Marginals,{'Parameters'});

reducedInput = uq_createInput(OPTS,'-private');
clear OPTS
d = size(reducedInput.Marginals,2);

%% Common options both analytical and FE
metaType   = 'PCE';
alpha      = 0.05;
HDR        = ZS_Grid.get_credible_interval(reducedInput,0.01);
R_01       = HDR.Support;
level      = HDR.Level;

%% Error analysis - Analytical model
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
ZS_save('Tunnel_analytical_01.mat',RES)
try
delete(p)
end
toc(t0)