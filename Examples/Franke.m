clc
clear 
ZS_G

Models = ZS_createModel_fun;
Inputs = ZS_createInput_fun;

trueModel = Models.franke;
Input     = Inputs.franke;

d  = 2;
dx = [0 1 ; 0 1];
replicates = 10;
metaType = 'PCE';
n = 100;

for i = 1:d
    OPTS.Marginals(i).Type = 'beta';
    OPTS.Marginals(i).Parameters = [0.5 0.5 0 1];
end

betaInput = uq_createInput(OPTS,'-private');
clear OPTS


for i = 1:2*replicates

    % General
    OPTS{i}.Type     = 'Metamodel';
    OPTS{i}.Display  = 'quiet';

    % Input and true model
    OPTS{i}.Input = Input;
    OPTS{i}.FullModel = trueModel;

    % Experimental design
    if i < replicates
        X_ED = uq_getSample(Input,n,'lhs');
    else
        X_ED = uq_getSample(betaInput,n,'lhs');
    end
    Y_ED = uq_evalModel(trueModel,X_ED);
    OPTS{i}.ExpDesign.X = X_ED;
    OPTS{i}.ExpDesign.Y = Y_ED;

    % Validation set
    valX = uq_getSample(Input,10^6);
    valY = uq_evalModel(trueModel,valX);
    OPTS{i}.ValidationSet.X = valX;
    OPTS{i}.ValidationSet.Y = valY;


    % Surrogate options
    OPTS{i}.MetaType = metaType;

    switch metaType

        case 'PCE'

            OPTS{i}.TruncOptions.qNorm = 1;
            OPTS{i}.Degree             = 1:20;
            OPTS{i}.DegreeEarlyStop    = false;

            OPTS{i}.Method = 'OLS';

        case 'Kriging'

        case 'PCK'

    end


end


N = length(OPTS);

% Options for L1 norm
L1_Opts.Method   = 'Continous';
L1_Opts.Type     = 'L1';
L1_Opts.Input    = Input;
L1_Opts.NSamples = 10^5;

% Options for C0 solver
C0_Opts.Method                   = 'Continous';
C0_Opts.Support                  = [0 1; 0 1];
C0_Opts.Input                    = Input;
C0_Opts.optimOpts.Display        = 'off';
C0_Opts.optimOpts.SwarmSize      = 300;
C0_Opts.optimOpts.UseVectorized  = true;

L1  = zeros(N,1);
LOO = L1;
Val = L1;
C0  = L1;
XC0 = zeros(N,d);


try
p = parpool(64);
catch
    try
    p = parpool(8);
    end
end

for i = 1:N
    disp(i)
    PCE = uq_createModel(OPTS{i},'-private');

    try
        LOO(i) = PCE.Error.ModifiedLOO;
    catch
        LOO(i) = PCE.Error.LOO;
    end
    Val(i)           = PCE.Error.Val;
end