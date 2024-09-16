function PCOpts = ZS_createPCOpts(opts,replicates)

metaType  = opts.MetaType;
trueModel = opts.Model;
input     = opts.Input;
alpha     = opts.alpha;
mu        = opts.mu;

% Set the sparse grid
family = 'leja';
d  = size(input.Marginals,2);
f  = ZS_Points.get_growth(family);

OPTS.Mapping.RandomVector = input;
OPTS.Mapping.Type         = 'Rectangular';
OPTS.Mapping.CI           = alpha;

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




scenarios = {'Natural','Uniform','Smolyak','Isoprobabilistic'};

PCOpts    = cell(1,(length(scenarios)-2)*replicates+2);


% Now create the common surrogate options
OPTS.Type               = 'Metamodel';
OPTS.Display            = 'quiet';
OPTS.MetaType           = metaType;

switch metaType
    case 'PCE'
        OPTS.TruncOptions.qNorm = 1;
        OPTS.Degree             = 1:MaxDegree;
        OPTS.DegreeEarlyStop    = false;
        OPTS.qNormEarlyStop     = false;
        OPTS.Method             = 'OLS';
    otherwise
        error('This surrogate model is not supported yet.')
end

PCOpts(:) = {OPTS};


count = 1;
for k = 1:length(scenarios)

    switch scenarios{k}

        case 'Natural' % LHS design according to the natural random vector
            
            for j = 1:replicates
                PCOpts{count}.Input       = input;
                X_ED                      = uq_getSample(input,N,'lhs','LHSiterations',20);
                PCOpts{count}.ExpDesign.X = X_ED;
                PCOpts{count}.ExpDesign.Y = evalModel(trueModel,X_ED);
                count = count + 1;
            end

        case 'Uniform' % LHS design according to uniformly distributed points on HDR alpha

            for j = 1:replicates
                PCOpts{count}.Input       = input;
                X_ED                      = uq_getSample(U_input,N,'lhs','LHSiterations',20);
                PCOpts{count}.ExpDesign.X = X_ED;
                PCOpts{count}.ExpDesign.Y = evalModel(trueModel,X_ED);
                count = count + 1;
            end

        case 'Beta' % LHS design according to beta distributed points on HDR alpha
            
            beta = opts.beta;
            for j = 1:d
                InputOPTS.Marginals(j).Type       = 'Beta';
                InputOPTS.Marginals(j).Parameters = [beta,beta,support(j,1),support(j,2)]; 
            end

            betaInput = uq_createInput(InputOPTS,'-private');

            for j = 1:replicates
                PCOpts{count}.Input       = input;
                X_ED                      = uq_getSample(betaInput,N,'lhs','LHSiterations',20);
                PCOpts{count}.ExpDesign.X = X_ED;
                PCOpts{count}.ExpDesign.Y = evalModel(trueModel,X_ED);
                count = count + 1;
            end

        case 'Smolyak'

            PCOpts{count}.Input       = input;
            X_ED                      = recGrid;
            PCOpts{count}.ExpDesign.X = X_ED;
            PCOpts{count}.ExpDesign.Y = evalModel(trueModel,X_ED);
            count = count + 1;

        case 'Isoprobabilistic'

            PCOpts{count}.Input       = input;
            X_ED                      = isoGrid;
            PCOpts{count}.ExpDesign.X = X_ED;
            PCOpts{count}.ExpDesign.Y = evalModel(trueModel,X_ED);

    end

end





function Y = evalModel(trueModel,X)
    switch trueModel.Type
        case 'uq_default_model'
            Y = uq_evalModel(trueModel,X);
        case 'uq_uqlink'
            Y = ZS_R_evalModel;
    end
end


end