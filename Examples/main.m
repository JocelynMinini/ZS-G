clc
clear all
uqlab
ZS_G
addpath(genpath('C:\Users\jocelyn.minini\switchdrive\MetaG\4_MATLAB\ZS+G\Examples'))

try
    p = parpool(32);
end


warning ('off','all');

clc

% Load all models and inputs
All_Inputs = ZS_createInput_fun;
All_Models = ZS_createModel_fun;

% model iterations
model_names = fieldnames(All_Models);
model_index = [3 5 6 9 4];
%model_index = [ 4];

% solver iteration
metaType = 'PCE';
switch metaType
    case 'PCE'
        solver_names = {'OLS'};
    case 'Kriging'
        solver_names = {'ordinary'};
    otherwise
        %
end

for k = model_index
for j = 1:length(solver_names)


model    = model_names{k};
family   = 'chebyshev_1';
bounds   = 'true';
solver   = solver_names{j};
d        = length(All_Inputs.(model).Marginals);

switch family
    case 'linspace'
        if eval(bounds)
            growth = @(k) 2.^k+1;
        else
            growth = @(k) 2.^k-1;
        end
    case 'chebyshev_1'
        growth = @(k) 3.^k;
    case 'chebyshev_2'
        growth = @(k) 2.^k+1;
    case 'leja'
        growth = @(k) 2.*k-1;
end



fprintf('### Starting calculation ###\n\n')
fprintf(' - Model     : %s\n',model)
fprintf(' - MetaType  : %s\n',metaType)
fprintf(' - Family    : %s\n',family)
fprintf(' - Bounds    : %s\n',bounds)
fprintf(' - Solver    : %s\n',solver)
fprintf(' - Mu        : [');


if strcat(bounds,'true')
    boole_bounds = true;
else
    boole_bounds = false;
end

mu = 0;

while true 

mu = mu + 1;

RES = {};

done      = false;
Degree    = 1;
maxDegree = 20;

N = ZS_SparseGrid.get_number_of_nodes(d,mu,growth);

if N > 1100
    break
end

while true

    switch metaType % We explore all degrees up to maxDegree

        case {'PCE','PCK'}

            opts.Degree = Degree;
            opts.Solver = solver;

            temp = ZS_Bennchmark(All_Models.(model),metaType,All_Inputs.(model),family,mu,boole_bounds,opts);
            temp = temp.Result;

            if strcmp(solver,'OLS')
                
                % To avoid singular matrix
                P     = nchoosek(d+Degree,Degree);
                ratio = N/P;
            
                if ratio < 1.5 || Degree > maxDegree
                    break
                else
                    Degree = Degree + 1;
                    RES{end+1} = temp;
                end
        
            else
 
                if Degree >= maxDegree
                    break
                else
                    Degree = Degree + 1;
                    RES{end+1} = temp;
                end
            end

        case 'Kriging'

            opts.Trend  = solver;

            temp = ZS_Bennchmark(All_Models.(model),metaType,All_Inputs.(model),family,mu,boole_bounds,opts);
            temp = temp.Result;
            RES  = temp;
            break

    end

end

fprintf(' %d ',mu);

filename = ['fun_',model,'_',metaType,'_',family,'_',char(string(mu)),'_',bounds,'_',solver,'.mat'];
ZS_save(filename,RES)
end

fprintf(']\n');

end
end





%{
index = [1 2 3 6 7 8 9];
index = 1;

model_names  = fieldnames(All_Models);
model_names  = model_names(index);
family_names = {'linspace','linspace','chebyshev_2','leja'};
bounds       = {true,false,true,true};
growth       = {@(k) 2.^k+1, @(k) 2.^k-1, @(k) 2.^k+1, @(k) 2.*k+1};

%RES = repmat(struct('Model', '', 'Family', '', 'Level', []),N);
count = 1;
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
                
                OPTS.Surrogate.Model      = Model;
                OPTS.Surrogate.Replicates = 1;
                OPTS.Surrogate.Method     = 'OLS';
                
                this = ZS_createGrid(OPTS);
                
                RES(count).Model  = current_Model;
                RES(count).Family = current_family;
                RES(count).Level  = current_mu;
                RES(count).Bounds = current_bounds;
                RES(count).Size   = this.Internal.Grid.Dimensions;

                res = ZS_createAnalysis(this);
                
                try
                    
                    RES(count).Result = res;
                catch me
                    RES(count).Result = me;
                end
                
                %save("Results.mat","RES")
                clear OPTS this res
                count = count + 1;
        
        end
        fprintf(']\n');


    end

    fprintf('   Model : %s - Terminated\n',current_Model);
    
end



%% 
clc
clear all
load("Results.mat")

for i = 1:length(RES)
    boole = isa(RES(i).Result,'ParallelException');
    if boole
        RES(i).Result = [];
    end

end

save("Results_Post.mat","RES")
%}