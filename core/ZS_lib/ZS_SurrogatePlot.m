function OUT = ZS_SurrogatePlot(uq_model,uq_input,metaType,solver,degree,samplingOpts)

arguments
        uq_model            {mustBeA(uq_model,'uq_model')}
        uq_input            {mustBeA(uq_input,'uq_input')}
        metaType            (1,:) char
        solver              (1,:) char
        degree              (1,1) {mustBeInteger}
        samplingOpts.Method (1,:) char           % can be 'Sparse' or 'Random'
        samplingOpts.Level          % Level of the grid or number of samples
        samplingOpts.Bounds (1,1) logical = true % Boundaries
        samplingOpts.Family (1,:) char           % Grid family or random sampling family
end

% Load all models and inputs

d = length(uq_input.Marginals);

if d>3
    error("This function is not defined for d > 3.")
end

switch lower(samplingOpts.Method)

    case 'sparse'

        family = samplingOpts.Family;

        if isequal(family,'linspace') & ~samplingOpts.Bounds
            growth = ZS_Points.get_growth([family,'_noBounds']);
        else
            growth = ZS_Points.get_growth(family);
        end

        OPTS.Grid.Class = 'Sparse';
        OPTS.Grid.D     = d;
        OPTS.Grid.Level = samplingOpts.Level;
        
        OPTS.Basis.Family = family;
        OPTS.Basis.Growth = growth;
        OPTS.Basis.Bounds = samplingOpts.Bounds;
        OPTS.Basis.PNorm  = 1;
        
        OPTS.Mapping.RandomVector = uq_input;
        OPTS.Mapping.Type         = 'Rectangular';
        OPTS.Mapping.CI           = 0.05;
        
        this = ZS_createGrid(OPTS);
        clear OPTS

        X_ED = this.Grid;
        Y_ED = uq_evalModel(uq_model,X_ED);

    case 'random'

        X_ED = uq_getSample(uq_input,samplingOpts.Level,lower(samplingOpts.Family));
        Y_ED = uq_evalModel(uq_model,X_ED);

    otherwise

        error("Sampling method must be 'Sparse' or 'Random'")

end


qNorm  = 1;

OPTS.Type     = 'Metamodel';
OPTS.MetaType = metaType;
OPTS.Input    = uq_input;

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

OPTS.ExpDesign.X = X_ED;
OPTS.ExpDesign.Y = Y_ED;

PCE = uq_createModel(OPTS,'-private');
clear OPTS


try
    support = this.Internal.Grid.Mapping.Support;
catch me
    idx = ZS_Grid.get_all_uniform(uq_input);
    if sum(idx) == d
        support = {uq_input.Marginals(idx).Parameters}';
        support = cell2mat(support);
    else
        xTemp   = uq_getSample(uq_input,10^6);
        support = ZS_Grid.get_Bounds(xTemp);
        clear xTemp
    end
end




switch d
    case 2
        MAT      = ZS_Grid2Plot(uq_model,'mathematica',support(1,:),support(2,:));
        OUT.X    = MAT(:,[1 2]);
        OUT.Y    = MAT(:,3);
        MAT      = ZS_Grid2Plot(PCE,'mathematica',support(1,:),support(2,:));
        OUT.YPCE = MAT(:,3);
    case 3
        MAT      = ZS_Grid2Plot(uq_model,'mathematica',support(1,:),support(2,:),support(3,:));
        OUT.X    = MAT(:,[1 2 3]);
        OUT.Y    = MAT(:,4);
        MAT      = ZS_Grid2Plot(PCE,'mathematica',support(1,:),support(2,:),support(3,:));
        OUT.YPCE = MAT(:,4);
end

OUT.X_ED = X_ED;
OUT.Y_ED = Y_ED;
OUT.D    = d;
OUT.DX = support;
end



