function RES = ZS_Bennchmark(model,metaType,input,family,mu,bounds,metaOpts,replicates)

% Définit la valeur par défaut pour replicates si non spécifié
if nargin < 8
    replicates = 50;
end

switch family
    case 'linspace'
        if bounds
            growth = @(k) 2.^k+1;
        else
            growth = @(k) 2.^k-1;
        end
    case 'chebyshev_2'
        growth = @(k) 2.^k+1;
    case 'leja'
        growth = @(k) 2.*k+1;
end

d = length(input.Marginals);

OPTS.Grid.Class = 'Sparse';
OPTS.Grid.D     = d;
OPTS.Grid.Level = mu;

OPTS.Basis.Family = family;
OPTS.Basis.Growth = growth;
OPTS.Basis.Bounds = bounds;
OPTS.Basis.PNorm  = 1;

OPTS.Mapping.RandomVector = input;
OPTS.Mapping.Type         = 'Rectangular';
OPTS.Mapping.CI           = 0.01;

OPTS.Surrogate.Model      = model;
OPTS.Surrogate.Replicates = replicates;
OPTS.Surrogate.MetaType   = metaType;
OPTS.Surrogate.OPTS       = metaOpts;

this = ZS_createGrid(OPTS);

RES.Model  = model;
RES.Family = family;
RES.Level  = mu;
RES.Bounds = bounds;
RES.Size   = this.Internal.Grid.Dimensions;

res = ZS_get_compare(this);

try
    RES.Result = res;
catch me
    RES.Result = me;
end

clear OPTS this res
end