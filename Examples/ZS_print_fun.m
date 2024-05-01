function ZS_print_fun(funName)
%-------------------------------------------------------------------------------
% Name:           ZS_print_fun
% Purpose:        This function prints one of the functions contained in 
%                 Examples/Functions with the name 'funName'
% Last Update:    25.04.2024
%-------------------------------------------------------------------------------
path = ZS_G_rootPath;
path = [path,'\Examples\Functions'];

addpath(path)

names  = ZS_get_fun_names;
Inputs = ZS_createInput_fun;
Models = ZS_createModel_fun;

try
    current_input = Inputs.(funName);
catch
    str = 'The requested function does not exist. Please select one in the following list : ';
    for i = 1:length(names)
        temp = strcat("\n - '",names{i},"'");
        temp = char(temp);
        str = [str,temp];
    end
    error('foo:bar',str)
end

current_model = Models.(funName);

d = length(current_input.Marginals);
n = 70;

if d == 2
    X = uq_getSample(current_input,10^4);
    x1 = minmax(X(:,1)');
    x1 = linspace(x1(1),x1(2),n);
    x2 = minmax(X(:,2)');
    x2 = linspace(x2(1),x2(2),n);
    [X1,X2] = meshgrid(x1,x2);

    X = [X1(:),X2(:)];
    Y = uq_evalModel(current_model,X);
    Y = reshape(Y,[n n]);

    figure
    surf(X1,X2,Y)
    pbaspect([1 1 1])

elseif d == 3

    error("Not implemented yet.")

else 
    error("Function visualization works only for d = 2 and d = 3.")
end

end