clc
clear all
uqlab
ZS_G
addpath(genpath('C:\Users\jocelyn.minini\switchdrive\MetaG\4_MATLAB\ZS+G\Examples'))
warning('off','all')

myCluster = parcluster('local');
myCluster.NumWorkers = 8;
p = parpool(myCluster);

% Load all models and inputs
All_Inputs = ZS_createInput_fun;
All_Models = ZS_createModel_fun;

index = [1 2 3 5 6 7 8 9];

model_names  = fieldnames(All_Models);
model_names  = model_names(index);
family_names = {'linspace','linspace','chebyshev_1','chebyshev_2','leja'};
bounds       = {true,false,true,true,true};
growth       = {@(k) 2.^k+1, @(k) 2.^k-1, @(k) 3.^(k), @(k) 2.^k+1, @(k) 2.*k+1};

%RES = repmat(struct('Model', '', 'Family', '', 'Level', []),N);
count = 1;
tic
for i = 1:length(model_names) % Model iterator

    current_Model = model_names{i};
     
    Input         = All_Inputs.(current_Model);
    Model         = All_Models.(current_Model); 
    d             = length(Input.Marginals);

    fprintf('# Calculation N°%d\n',i);
    fprintf('   Model : %s - %dD\n',current_Model,d);

    for k = 1:length(family_names)

        current_family = family_names{k};
        current_growth = growth{k};
        current_bounds = bounds{k};

        fprintf('   Family : %s\n',current_family);

        switch current_family
            case 'linspace'
                mus = 0:5;
            case 'chebyshev_1'
                mus = 1:2;
            case 'chebyshev_2'
                mus = 0:5;
            case 'leja'
                mus = 0:5;
        end

        if d > 3
            mus = mus-2;
            mus(mus<0) = [];
        end
    
        fprintf('   Mu : [');

        for j = 1:length(mus) % Mu iterator
    
                current_mu   = mus(j);
                fprintf(' %d ',current_mu);
                

                mu = current_mu;
                alpha = 0.01;
                
                OPTS.Grid.Class = 'Sparse';
                OPTS.Grid.D     = d;
                OPTS.Grid.Level = mu;
                
                OPTS.Basis.Family = current_family;
                OPTS.Basis.Growth = current_growth;
                OPTS.Basis.Bounds = current_bounds;
                OPTS.Basis.PNorm  = 1;
                
                OPTS.Mapping.RandomVector = Input;
                OPTS.Mapping.Type         = 'Rectangular';
                OPTS.Mapping.CI           = alpha;
                
                OPTS.Surrogate.Type       = 'PCE';
                OPTS.Surrogate.Model      = Model;
                OPTS.Surrogate.Degree     = 1:20;
                OPTS.Surrogate.Replicates = 1;
                
                this = ZS_createGrid(OPTS);
                
                RES(count).Model  = current_Model;
                RES(count).Family = current_family;
                RES(count).Level  = current_mu;
                RES(count).Bounds = current_bounds;
                RES(count).Size   = this.Internal.Grid.Dimensions;
                
                try
                    res = ZS_createAnalysis(this);
                    RES(count).Result = res;
                catch me
                    RES(count).Result = me;
                end
                
                clear OPTS this res
                count = count + 1;
        
        end
        fprintf(']\n');


    end

    fprintf('   Model : %s - Terminated\n',current_Model);
    
end
toc


%%
tot = 0;
for i = 1:length(RES)
    temp = RES(i).Result;
    try
        temp = [temp.T];
    catch
        temp = 0;
    end
    tot = tot + 1000*sum(temp);
end