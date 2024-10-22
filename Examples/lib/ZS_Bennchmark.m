function RES = ZS_Bennchmark(uq_model,uq_input,family,boundaries,replicates,metaOpts)

schemes = {'MC','LHS','Sobol'};
mu      = 1;

% Options for L1 norm
L1_Opts.Method   = 'Continous';
L1_Opts.Type     = 'L1';
L1_Opts.Input    = uq_input;
L1_Opts.NSamples = 10^5;

% Options for C0 norm
C0_Opts.Method                   = 'Continous';
C0_Opts.optimOpts.Display        = 'off';
C0_Opts.optimOpts.SwarmSize      = 300;
C0_Opts.optimOpts.UseVectorized  = true;

fprintf('| Mu ->')

while true

    % First construct the grid
    this = createGrid(mu,family,boundaries);

    % Extract the grid
    grid = this.Grid;

    % Extract the cardinality
    n = this.Internal.Grid.Dimensions(1);

    % Setting up the experimental designs
    count = 1;

    for i = 1:length(schemes)
        for j = 1:replicates
            X = createExpDesign(n,schemes{i});
            Y = uq_evalModel(uq_model,X);
            
            ExpDesign(count).X = X;
            ExpDesign(count).Y = Y;

            count = count + 1;
        end
    end

    ExpDesign(count).X = grid;
    ExpDesign(count).Y = uq_evalModel(uq_model,grid);
    
    % Kill the calculation if n > 1100
    if n > 1100
        break
    end

    fprintf(' %s',string(mu))

    % Create the surrogate options
    surrogateOpts = createSurrogate(ExpDesign,metaOpts);

    N = size(surrogateOpts,1);
    M = size(surrogateOpts,2);

    C0_Opts.Support = this.Internal.Grid.Mapping.Support;

    for j = 1:M
        
        L1  = zeros(N,1);
        C0  = L1;
        LOO = L1;
        XC0 = cell(N,1);

        for i = 1:N
            PCE              = uq_createModel(surrogateOpts{i,j},'-private');
            LOO(i)           = PCE.Error.ModifiedLOO;
            L1(i)            = ZS_get_L_norm(uq_model,PCE,L1_Opts);
            [XC0{i,:},C0(i)] = ZS_get_C0(uq_model,PCE,C0_Opts);
        end

        RES.LOO.(['MU_',char(string(mu))])(:,j) = LOO;
        RES.L1.(['MU_',char(string(mu))])(:,j)  = L1;
        RES.C0.(['MU_',char(string(mu))])(:,j)  = C0;
        RES.XC0.(['MU_',char(string(mu))])(:,j) = XC0;

    end

mu = mu + 1;
end


% Helper functions
function this = createGrid(mu,family,boundaries)

    d = length(uq_input.Marginals);

    if ~eval(boundaries)
        growth = ZS_Points.get_growth([family,'_noBounds']);
    else
        growth = ZS_Points.get_growth(family);
    end
    
    gridOpts.Grid.Class = 'Sparse';
    gridOpts.Grid.D     = d;
    gridOpts.Grid.Level = mu;
    
    gridOpts.Basis.Family = family;
    gridOpts.Basis.Growth = growth;
    gridOpts.Basis.Bounds = eval(boundaries);
    gridOpts.Basis.PNorm  = 1;
    
    gridOpts.Mapping.RandomVector = uq_input;
    gridOpts.Mapping.Type         = 'Rectangular';
    gridOpts.Mapping.CI           = 0.01;
    
    this = ZS_createGrid(gridOpts);
end


function X = createExpDesign(n,scheme)

    switch scheme
        case 'LHS'
            X = uq_getSample(uq_input,n,scheme,'LHSiterations',50);
        otherwise
            X = uq_getSample(uq_input,n,scheme);
    end

end


function surrogateOpts = createSurrogate(ED,metaOpts)

    d         = length(uq_input.Marginals);
    currentN  = length(ED(1).Y);
    K         = length(ED);

    % Configure the maximal degree (for OLS)
    maxDegree = 1;
    while true
        P     = nchoosek(d+maxDegree,maxDegree);
        ratio = currentN/P;
        if ratio > 1.5
            maxDegree = maxDegree + 1;
        else
            maxDegree = maxDegree - 1;
            break
        end
        
    end
    maxDegree = min(maxDegree,20);


    surrogateOpts = cell(K,maxDegree);

    % Common surrogate options
    OPTS.Type     = 'Metamodel';
    OPTS.Display  = 'quiet';
    OPTS.MetaType = metaOpts.MetaType;
    OPTS.Input    = uq_input;
    
    switch metaOpts.MetaType

        case 'PCE'
            OPTS.TruncOptions.qNorm = 1;
            OPTS.DegreeEarlyStop    = false;
            OPTS.qNormEarlyStop     = false;
            OPTS.Method             = metaOpts.Solver;

            for k = 1:length(ED)
        
                OPTS.ExpDesign = ED(k);
        
                for nu = 1:maxDegree
                    OPTS.Degree = nu;
                    surrogateOpts{k,nu} = OPTS;
                end
        
            end

        otherwise
            error('This surrogate model is not supported yet.')
    end

end

















end