function OPTS = ZS_get_PC_opts(this,samplingMethod)
%-------------------------------------------------------------------------------
% Name:           ZS_create_PCE_opts
% Purpose:        This function builts the options structure for creating
%                 the PCE with uqlab
% Last Update:    17.07.2024
%-------------------------------------------------------------------------------
% General options
trueModel      = this.Options.Surrogate.Model;
OPTS.Type      = 'Metamodel';
OPTS.Display   = 'quiet';
OPTS.MetaType  = this.Options.Surrogate.MetaType;
OPTS.Input     = this.Options.Mapping.RandomVector;

% Set the experimental design
switch samplingMethod
    case 'Smolyak'
        X_ED = this.Grid;
    otherwise
        X_ED  = uq_getSample(this.Options.Mapping.RandomVector,this.Internal.Grid.Dimensions(1),samplingMethod,'LHSiterations',20);
end
Y_ED  = uq_evalModel(trueModel,X_ED);

OPTS.ExpDesign.X = X_ED;
OPTS.ExpDesign.Y = Y_ED;

% Set the validation set using MC sampling
OPTS.ValidationSet.X = uq_getSample(this.Options.Mapping.RandomVector,10^5);
OPTS.ValidationSet.Y = uq_evalModel(trueModel,OPTS.ValidationSet.X);

% Surrogate specific options
switch OPTS.MetaType

    case 'PCE'

        OPTS.TruncOptions.qNorm = 1;
        OPTS.Degree             = this.Options.Surrogate.OPTS.Degree;
        OPTS.DegreeEarlyStop    = false;
        OPTS.qNormEarlyStop     = false;
        OPTS.Method             = this.Options.Surrogate.OPTS.Solver;

        switch OPTS.Method
            case 'OLS'
                % nothing
            case 'LARS'
                OPTS.LARS.LarsEarlyStop = false;
                OPTS.LARS.HybridLoo     = false;
            case 'SP'
                OPTS.SP.NNZ = floor(length(X_ED)/2);
            otherwise
                error("This solver is currently not supported.")
        end

    case 'Kriging'

        OPTS.ExpDesign.Sampling  = 'User';
        OPTS.Regression.SigmaNSQ = 'none';
        OPTS.Trend.Type          = this.Options.Surrogate.OPTS.Trend;

    case 'PCK'

        OPTS.Mode       = 'optimal';
        OPTS.PCE.Degree = this.Options.Surrogate.OPTS.Degree;

    otherwise

        error("This surrogate type is currently not supported.")

end


end