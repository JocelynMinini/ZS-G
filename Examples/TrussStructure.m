clc
clear 
ZS_G
uqlab


% Load all models and inputs
All_Inputs = ZS_createInput_fun;
All_Models = ZS_createModel_fun;

model = 'trussstructure';

Input       = All_Inputs.(model);
trueModel   = All_Models.(model);
trueModelFE = All_Models.trussstructureFE;

clear All_Models All_Inputs

%% Sensitivity analysis
RES.Sensitivity.Total = [0.374 0.0126 0.371 0.0125 0.004 0.0377 0.0777 0.0778 0.0376 0.0047];
RES.Sensitivity.First = [0.3638 0.0051 0.3624 0.0055 -0.0019 0.02922 0.0717 0.0692 0.0297 -0.0025];

%% Redefining the input
keep = [1 3]; % keep these variables
rmv  = setdiff(1:length(Input.Marginals),keep); % remove these

OPTS.Marginals = Input.Marginals(keep);
OPTS.Marginals = rmfield(OPTS.Marginals,{'Parameters'});

reducedInput = uq_createInput(OPTS,'-private');
clear OPTS
d = size(reducedInput.Marginals,2);