function [xstar,ystar] = ZS_get_C0(trueModel,surrogateModel,opts)
%-------------------------------------------------------------------------------
% Name:           ZS_get_C0
% Purpose:        This function computes the C0-norm using particle swarm
%                 optimization solver
% Last Update:    12.09.2024
%-------------------------------------------------------------------------------
d          = opts.d;
support    = opts.support;
optim_opts = opts.optimOpts;

% For a levelset optimization
if isfield(opts,"Input") && isfield(opts,"Level")
    levelOptim = true;  
else
    levelOptim = false;
end

if levelOptim
    level = opts.Level;
    Input = opts.Input;
    fun = @(x) modelPenalty(x,trueModel,surrogateModel,Input,level);
else
    fun = @(x) -abs(uq_evalModel(trueModel,x) - uq_evalModel(surrogateModel,x));
end

[xstar,ystar] = particleswarm(fun,d,support(:,1)' , support(:,2)', optim_opts);

% This is the transformed model with penalty term = inf
function Y = modelPenalty(X,trueModel,surrogateModel,uq_input,level)
    pdf = uq_evalPDF(X,uq_input);
    idx = pdf >= level;
    Y   = -abs(uq_evalModel(trueModel,X) - uq_evalModel(surrogateModel,X));
    Y(~idx,:) = inf;
end

end

