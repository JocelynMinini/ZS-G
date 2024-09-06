function OUT = ZS_ContourPlot(model,metaType,family,mu,bounds,seed,solver,degree)
% Load all models and inputs
All_Inputs = ZS_createInput_fun;
All_Models = ZS_createModel_fun;

current_Model = model;
 
Input         = All_Inputs.(current_Model);
Model         = All_Models.(current_Model); 
d             = length(Input.Marginals);

if d > 3
    error('This function works only for d = 2')
end

if isequal(family,'linspace') & ~bounds
    growth = ZS_Points.get_growth([family,'_noBounds']);
else
    growth = ZS_Points.get_growth(family);
end


OPTS.Grid.Class = 'Sparse';
OPTS.Grid.D     = d;
OPTS.Grid.Level = mu;

OPTS.Basis.Family = family;
OPTS.Basis.Growth = growth;
OPTS.Basis.Bounds = bounds;
OPTS.Basis.PNorm  = 1;

OPTS.Mapping.RandomVector = Input;
OPTS.Mapping.Type         = 'Rectangular';
OPTS.Mapping.CI           = 0.01;

this = ZS_createGrid(OPTS);
clear OPTS

X_ED = {uq_getSample(Input,this.Internal.Grid.Dimensions(1),seed),this.Grid};

fields = {'Random','Smolyak'};

qNorm  = 1;

for i = 1:length(X_ED)

    OPTS.Type                   = 'Metamodel';
    OPTS.MetaType               = metaType;
    OPTS.Input                  = Input;

    switch metaType
        case 'PCE'
            OPTS.Degree                 = degree;
            OPTS.TruncOptions.qNorm     = qNorm;
            OPTS.Method                 = solver;
            OPTS.DegreeEarlyStop        = false;
            OPTS.qNormEarlyStop         = false;
        case 'PCK'
            OPTS.Mode                   = 'optimal';
            OPTS.PCE.Degree             = degree;
            OPTS.PCE.TruncOptions.qNorm = qNorm;
            OPTS.PCE.DegreeEarlyStop    = false;
            OPTS.PCE.qNormEarlyStop     = false;
        case 'Kriging'
            OPTS.ExpDesign.Sampling     = 'User';
            OPTS.Regression.SigmaNSQ    = 'auto';
            OPTS.Trend.Type             = solver;
    end

    OPTS.ExpDesign.X = X_ED{i};
    Y_ED{i}          = uq_evalModel(Model,OPTS.ExpDesign.X);
    OPTS.ExpDesign.Y = Y_ED{i};

    PCE.(fields{i}) = uq_createModel(OPTS,'-private');
    clear OPTS

end

support  = this.Internal.Grid.Mapping.Support;
switch d
    case 2
        sub     = 200;
        x1      = linspace(support(1,1),support(1,2),sub);
        x2      = linspace(support(2,1),support(2,2),sub);
        [X1,X2] = meshgrid(x1,x2);
        X       = [X1(:),X2(:)];
    case 3
        sub        = 50;
        x1         = linspace(support(1,1),support(1,2),sub);
        x2         = linspace(support(2,1),support(2,2),sub);
        x3         = linspace(support(3,1),support(3,2),sub);
        [X1,X2,X3] = ndgrid(x1,x2,x3);
        X          = [X1(:),X2(:),X3(:)];
end

OUT.X               = X;
OUT.Y               = uq_evalModel(Model,X);
OUT.DX              = support;

OUT.Random.Y        = uq_evalModel(PCE.Random,X);
OUT.Random.ED       = PCE.Random.ExpDesign.X;
try
    OUT.Random.LOO  = PCE.Random.Error.ModifiedLOO;
catch
    OUT.Random.LOO  = PCE.Random.Error.LOO;
end

OUT.Smolyak.Y       = uq_evalModel(PCE.Smolyak,X);
OUT.Smolyak.ED      = PCE.Smolyak.ExpDesign.X;
try
    OUT.Smolyak.LOO = PCE.Smolyak.Error.ModifiedLOO;
catch
    OUT.Smolyak.LOO = PCE.Smolyak.Error.LOO;
end

end