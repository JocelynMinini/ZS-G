function PCOpts = ZS_createPCOpts(opts,replicates)

metaType  = opts.MetaType;
trueModel = opts.Model;
input     = opts.Input;
alpha     = opts.alpha;
mu        = opts.mu;

isFE = isequal(trueModel.Type,'uq_uqlink');
if isFE
    toEval = 'cell2mat(ZS_parallel_evalModel(trueModel,X_ED))';
else
    toEval = 'uq_evalModel(trueModel,X_ED)';
end

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
R        = this.Internal.Grid.Mapping.HDR.R;
S        = this.Internal.Grid.Mapping.HDR.S;
M        = this.Internal.Grid.Mapping.HDR.M;

%{
X_alpha  = uq_getSample(input,10^5);
fX_alpha = uq_evalPDF(X_alpha,input);
X_alpha  = X_alpha(fX_alpha>this.Internal.Grid.Mapping.Level,:);
scatter3(X_alpha(:,1),X_alpha(:,2),X_alpha(:,3))
hold on
scatter3(recGrid(:,1),recGrid(:,2),recGrid(:,3))
%}

for i = 1:d
    OPTS.Marginals(i).Type       = 'Uniform';
    OPTS.Marginals(i).Parameters = [-1,1];
end
U_input = uq_createInput(OPTS,'-private');

OPTS.Mapping.Type = 'Isoprobabilistic';
this              = ZS_createGrid(OPTS);
isoGrid           = this.Grid;
clear OPTS


% Set the max degree such that ratio > 1.5
N         = size(recGrid,1);
MaxDegree = 1;

while true
    P     = nchoosek(d+MaxDegree,MaxDegree);
    ratio = N/P;
    if ratio < 1
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
                PCOpts{count}.ExpDesign.Y = eval(toEval);
                count = count + 1;
            end

        case 'Uniform' % LHS design according to uniformly distributed points on HDR alpha

            for j = 1:replicates
                PCOpts{count}.Input       = input;
                X_ED                      = uq_getSample(U_input,N,'lhs','LHSiterations',20);
                X_ED = X_ED * S;
                X_ED = X_ED / R;
                X_ED = X_ED + M;
                PCOpts{count}.ExpDesign.X = X_ED;
                PCOpts{count}.ExpDesign.Y = eval(toEval);
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
                PCOpts{count}.ExpDesign.Y = eval(toEval);
                count = count + 1;
            end

        case 'Smolyak'

            PCOpts{count}.Input       = input;
            X_ED                      = recGrid;
            PCOpts{count}.ExpDesign.X = X_ED;
            PCOpts{count}.ExpDesign.Y = eval(toEval);
            count = count + 1;

        case 'Isoprobabilistic'

            PCOpts{count}.Input       = input;
            X_ED                      = isoGrid;
            PCOpts{count}.ExpDesign.X = X_ED;
            PCOpts{count}.ExpDesign.Y = eval(toEval);

    end

end


end