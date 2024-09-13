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
    OPTS.isVectorized = true;
    Models.(names{i}) = uq_createModel(OPTS,'-private');
end

end