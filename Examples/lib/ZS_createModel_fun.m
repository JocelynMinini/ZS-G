function Models = ZS_createModel_fun
%-------------------------------------------------------------------------------
% Name:           ZS_createAllModel
% Purpose:        This functions creates all uq_model based on the
%                 functions contained in Examples/Functions
% Last Update:    25.04.2024
%-------------------------------------------------------------------------------
names = ZS_get_fun_names;

for i = 1:length(names)
    name = names{i};
    name = ['ZS_fun_',name];
    OPTS.mFile        = name;
    if isequal(name,'ZS_fun_trussstructure')
        OPTS.isVectorized = false;
    else
        OPTS.isVectorized = true;
    end
    Models.(names{i}) = uq_createModel(OPTS,'-private');
    clear OPTS
end


% Here start the FE models
ZS_R

% Short column FE model
OPTS.Name        = 'shortColumn';
OPTS.Parser.Name = 'shortColumnParser';
OPTS.Parser.Path = fullfile(ZS_G_rootPath,'Examples','Functions');

path = strsplit(ZS_G_rootPath,'\');
path = path(1:end-2);
path = fullfile(path{:},'8_ZSoil','1_Short column');
OPTS.Template.Path = path;
addpath(path)

OPTS.ExecutionPath = fullfile(ZS_G_rootPath,'Examples');

Models.shortcolumnFE = ZS_createModel(OPTS);

% Truss structure FE model
OPTS.Name        = 'trussStructure';
OPTS.Parser.Name = 'trussStructureParser';
OPTS.Parser.Path = fullfile(ZS_G_rootPath,'Examples','Functions');

path = strsplit(ZS_G_rootPath,'\');
path = path(1:end-2);
path = fullfile(path{:},'8_ZSoil','2_Truss structure');
OPTS.Template.Path = path;
addpath(path)

OPTS.ExecutionPath = fullfile(ZS_G_rootPath,'Examples');

Models.trussstructureFE = ZS_createModel(OPTS);


end