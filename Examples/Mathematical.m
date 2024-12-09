clc
clear all
uqlab
ZS_G
addpath(genpath('C:\Users\jocelyn.minini\switchdrive\MetaG\4_MATLAB\ZS+G\Examples'))
warning ('off','all');

% Replicates
replicates = 100;

% Configure parallel execution
if replicates > 1
    try
        p = parpool(64);
    catch
        try 
            p = parpool(8);
        end
    end
end

%% Core execution

% Load all models and inputs
All_Inputs = ZS_createInput_fun;
All_Models = ZS_createModel_fun;
clc

% Model selection
modelNames = {'franke','rastrigin','ishigami','gfunc','friedman'};
models     = cellfun(@(x) All_Models.(x), modelNames, 'UniformOutput', false);

% Input selection
inputs = cellfun(@(x) All_Inputs.(x), modelNames, 'UniformOutput', false);

% Family selection
families   = {'linspace','linspace','chebyshev_1','chebyshev_2','leja'};
boundaries = {'true','false','true','true','true'};

% Surrogate model options
metaOpts.MetaType = 'PCE';
metaOpts.Solver   = 'OLS';

% Here start the two main loop : MODEL & FAMILY. The loop over the levels
% and the degrees are driven in a separate file

for i = 1:length(models) % Loop over the models

    currentModel = models{i};
    currentInput = inputs{i};

    fprintf(' # Model : %s\n',modelNames{i})

    for j = 1:length(families) % Loop over the family
    
        currentFamily     = families{j};
        currentBoundaries = boundaries{j};

        if ~eval(currentBoundaries)
            familyName = [currentFamily,'NB'];
        else
            familyName = currentFamily;
        end
        
        fprintf('   - %s',familyName)
        fprintf(repmat(' ',1,12-length(familyName)))

        try
            tempRES = ZS_Bennchmark(currentModel,currentInput,currentFamily,currentBoundaries,replicates,metaOpts);
        catch
            tempRES = [];
        end
        
        RES.(modelNames{i}).(familyName) = tempRES;

        ZS_save("Mathematical.mat",RES)

        fprintf('\n')
    end

end

delete(p)




















