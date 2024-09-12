function PCOpts = ZS_createPCOpts(trueModel,input,mu,replicates)
PCOpts = cell(1,2*replicates+2);

% Set the sparse grid
family = 'leja';
d  = size(input.Marginals,2);
f  = ZS_Points.get_growth(family);

OPTS.Mapping.RandomVector = input;
OPTS.Mapping.Type         = 'Rectangular';
OPTS.Mapping.CI           = 0.05;

OPTS.Grid.Class   = 'Sparse';
OPTS.Grid.D       = d;
OPTS.Grid.Level   = mu;

OPTS.Basis.Growth = f;
OPTS.Basis.Family = family;
OPTS.Basis.Bounds = true;
OPTS.Basis.PNorm  = 1;

this     = ZS_createGrid(OPTS);
recGrid  = this.Grid;
support  = this.Internal.Grid.Mapping.Support;

OPTS.Mapping.Type = 'Isoprobabilistic';
this              = ZS_createGrid(OPTS);
isoGrid           = this.Grid;
clear OPTS

% Get the uniform input over support
U_input = this.Internal.Grid.Mapping.U_RandomVector;


% Set the max degree such that ratio > 1.5
N         = size(recGrid,1);
MaxDegree = 1;

while true
    P     = nchoosek(d+MaxDegree,MaxDegree);
    ratio = N/P;
    if ratio < 1.5
        break
    end
    MaxDegree = MaxDegree + 1;
end



% Now create the common PCE options
for i = 1:length(PCOpts)
    OPTS.Type               = 'Metamodel';
    OPTS.Display            = 'quiet';
    OPTS.MetaType           = 'PCE';
    OPTS.TruncOptions.qNorm = 1;
    OPTS.Degree             = 1:MaxDegree;
    OPTS.DegreeEarlyStop    = false;
    OPTS.qNormEarlyStop     = false;
    OPTS.Method             = 'OLS';
    PCOpts{i} = OPTS;
end

% LHS design according to random vector
i = 1;
for k = 1:replicates
    PCOpts{i}.Input       = input;
    X_ED                  = uq_getSample(input,N,'lhs','LHSiterations',20);
    PCOpts{i}.ExpDesign.X = X_ED;
    PCOpts{i}.ExpDesign.Y = evalModel(trueModel,X_ED);
    i = i + 1;
end

% LHS design according to uniformly distributed points on R
for k = 1:replicates
    PCOpts{i}.Input       = input;
    X_ED                  = uq_getSample(U_input,N,'lhs','LHSiterations',20);
    PCOpts{i}.ExpDesign.X = X_ED;
    PCOpts{i}.ExpDesign.Y = evalModel(trueModel,X_ED);
    i = i + 1;
end


PCOpts{i}.Input       = input;
X_ED                  = recGrid;
PCOpts{i}.ExpDesign.X = X_ED;
PCOpts{i}.ExpDesign.Y = evalModel(trueModel,X_ED);
i = i + 1;

PCOpts{i}.Input       = input;
X_ED                  = isoGrid;
PCOpts{i}.ExpDesign.X = X_ED;
PCOpts{i}.ExpDesign.Y = evalModel(trueModel,X_ED);


function Y = evalModel(trueModel,X)
    switch trueModel.Type
        case 'uq_default_model'
            Y = uq_evalModel(trueModel,X);
        case 'uq_uqlink'
            Y = ZS_R_evalModel;
    end
end


end