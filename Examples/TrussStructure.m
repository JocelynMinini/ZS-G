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

OPTS.Type             = 'Sensitivity';
OPTS.Method           = 'Sobol';
OPTS.Sobol.SampleSize = 100000;
OPTS.Model            = trueModel;
OPTS.Input            = Input;
Sobol                 = uq_createAnalysis(OPTS);
uq_display(Sobol)
