clc
clear 
ZS_G

modelName = 'franke';
mu = 10;

Models = ZS_createModel_fun;

OPTS.Marginals(1).Type       = 'Gaussian';
OPTS.Marginals(1).Parameters = [0.5,0.1];

OPTS.Marginals(2).Type       = 'Lognormal';
OPTS.Marginals(2).Moments    = [0.5,0.05];

%OPTS.Copula.Type = 'Gaussian';
%OPTS.Copula.Parameters = [1 0.5; 0.5 1];

Input = uq_createInput(OPTS,'-private');
trueModel = Models.(modelName);


[R_01,level01,~] = ZS_Grid.get_credible_interval(Input,0.01);
[~,level05,~]    = ZS_Grid.get_credible_interval(Input,0.05);

f   = @(x) uq_evalPDF(x,Input);
PDF = ZS_Grid2Plot(f,'mathematica',R_01(1,:),R_01(1,:));
levels = [level01,level05];

opts.MetaType = 'PCE';
opts.Model    = trueModel;
opts.Input    = Input;
opts.alpha    = 0.05;
opts.mu       = 10;
Replicates    = 1;
PCOpts        = ZS_createPCOpts(opts,Replicates);


MAT = {};
ED  = {};


MAT{end+1} = ZS_Grid2Plot(trueModel,'mathematica',[0 1],[0 1]);

LOO = [];
L1  = [];

L1_Opts.Input    = Input;
L1_Opts.NSamples = 10^5;
L1_Opts.Type     = 'L1';
L1_Opts.Level    = levels(1);

for i = 1:4
    PCE        = uq_createModel(PCOpts{i},'-private');
    LOO(end+1) = PCE.Error.ModifiedLOO;
    L1(end+1)  = ZS_get_L_norm(trueModel,PCE,L1_Opts);
    MAT{end+1} = ZS_Grid2Plot(PCE,'mathematica',[0 1],[0 1]);
    ED{end+1}  = [PCE.ExpDesign.X,PCE.ExpDesign.Y];
end

