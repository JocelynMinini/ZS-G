clc
clear 
ZS_G

modelName = 'franke';
mu = 10;

Models = ZS_createModel_fun;

OPTS.Marginals(1).Type       = 'Gaussian';
OPTS.Marginals(1).Parameters = [0.5,0.1];

OPTS.Marginals(2).Type       = 'Gaussian';
OPTS.Marginals(2).Parameters = [0.5,0.05];

Input = uq_createInput(OPTS,'-private');
trueModel = Models.(modelName);


[R_01,level01,~] = ZS_Grid.get_credible_interval(Input,0.01);
[~,level05,~]    = ZS_Grid.get_credible_interval(Input,0.05);

f   = @(x) uq_evalPDF(x,Input);
PDF = ZS_Grid2Plot(f,'mathematica',R_01(1,:),R_01(1,:));
levels = [level01,level05];

PCOpts = ZS_createPCOpts(trueModel,Input,mu,1);

MAT = {};
ED  = {};


MAT{end+1} = ZS_Grid2Plot(trueModel,'mathematica',[0 1],[0 1]);

for i = 1:4
    PCE        = uq_createModel(PCOpts{i},'-private');
    MAT{end+1} = ZS_Grid2Plot(PCE,'mathematica',[0 1],[0 1]);
    ED{end+1}  = [PCE.ExpDesign.X,PCE.ExpDesign.Y];
end