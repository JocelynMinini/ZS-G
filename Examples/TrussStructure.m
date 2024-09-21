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

X = uq_getSample(Input,100000);
Y = uq_evalModel(trueModel,X);