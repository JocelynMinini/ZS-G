function [xstar,ystar] = ZS_get_C0(trueModel,surrogateModel,opts)
%-------------------------------------------------------------------------------
% Name:           ZS_get_C0
% Purpose:        This function computes the C0-norm using minimazation
%                 solver
% Last Update:    17.07.2024
%-------------------------------------------------------------------------------
d          = opts.d;
support    = opts.support;
optim_opts = opts.optimOpts;

fun   = @(x) -abs(uq_evalModel(trueModel,x) - uq_evalModel(surrogateModel,x));
%[xstar,ystar] = uq_gso(fun, [], d , support(:,1)' , support(:,2)' , optim_opts);
[xstar,ystar] = particleswarm(fun,d,support(:,1)' , support(:,2)', optim_opts);

%{
Just for graphical check
x1 = linspace(support(1,1),support(1,2));
x2 = linspace(support(2,1),support(2,2));
[X,Y] = meshgrid(x1,x2);
Z = fun([X(:),Y(:)]);
Z = reshape(Z,size(X));
surf(X,Y,Z)
hold on
scatter3(xstar(1),xstar(2),ystar,'red','filled')
%}
end

