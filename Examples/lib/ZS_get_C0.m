function [xstar,ystar] = ZS_get_C0(trueModel,surrogateModel,opts)
%-------------------------------------------------------------------------------
% Name:           ZS_get_C0
% Purpose:        This function computes the C0-norm using particle swarm
%                 optimization solver or discrete C0
% Last Update:    12.09.2024
%-------------------------------------------------------------------------------

d          = opts.d;
support    = opts.support;
optim_opts = opts.optimOpts;

optim_opts.Display       = 'none';


if ~isfield(optim_opts,"MaxIterations")
    optim_opts.MaxIterations = 200*d;
end

if ~isfield(optim_opts,"SwarmSize")
    optim_opts.SwarmSize = min(300,20*d);
end

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

    % Initial points
    optim_opts.InitialPoints = getInitialPoints(Input,level,optim_opts.SwarmSize);
else
    fun = @(x) -abs(uq_evalModel(trueModel,x) - uq_evalModel(surrogateModel,x));
end

trials = 1;
while true
    [xstar,ystar,exitFlag] = particleswarm(fun,d,support(:,1)' , support(:,2)', optim_opts);
    if exitFlag == 1 || trials >= 5
        break
    else
        optim_opts.MaxIterations = optim_opts.MaxIterations + 100*d;
        optim_opts.SwarmSize     = optim_opts.SwarmSize + 10*d;
        optim_opts.InitialPoints = getInitialPoints(Input,level,optim_opts.SwarmSize);
        trials = trials + 1;
    end
end

if exitFlag ~= 1
    fprintf('PSO warning : The minimization could not end with exitFlag = 1.')
end

% This is the transformed model with penalty term = inf
function Y = modelPenalty(X,trueModel,surrogateModel,uq_input,level)
    pdf = uq_evalPDF(X,uq_input);
    idx = pdf >= level;
    Y   = -abs(uq_evalModel(trueModel,X) - uq_evalModel(surrogateModel,X));
    Y(~idx,:) = inf;
end

    function IP = getInitialPoints(uq_input,level,N)
    IP = ZS_getSubsample(uq_input,level,N);
end

end