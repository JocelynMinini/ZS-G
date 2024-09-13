clc
clear
ZS_G

modelName = 'franke';

Inputs = ZS_createInput_fun;
Models = ZS_createModel_fun;

OPTS.Marginals(1).Type       = 'Gaussian';
OPTS.Marginals(1).Parameters = [0.5,0.1];

OPTS.Marginals(2).Type       = 'Gaussian';
OPTS.Marginals(2).Parameters = [0.5,0.05];

Input = uq_createInput(OPTS,'-private');
Model   = Models.(modelName);

% Find the level
[~,level] = ZS_Grid.get_credible_interval(Input,0.05);

clear OPTS Models Inputs


% C0 optimization
optimOpts.SwarmSize     = 300;

fun = @(x) Model_Penalty(x,Model,Input,level);
[xstar,ystar] = particleswarm(fun,2,[0 0],[1 1],optimOpts);

[X,Y,Z] = ZS_Grid2Plot(Model,'matlab',[0 1],[0 1]);
contour(X,Y,Z,20)
hold on
pdf = @(x) uq_evalPDF(x,Input);
[X,Y,Z] = ZS_Grid2Plot(pdf,'matlab',[0 1],[0 1]);
contour(X,Y,Z,[level level],'black')
plot(xstar(1), xstar(2), '+', 'LineWidth', 2, 'MarkerSize', 10)

% L1 integration
OPTS.mString = 'sin( X(:,1) + (X(:,2)).^2 )';
OPTS.isVectorized = true;
meta = uq_createModel(OPTS,'-private');

% Options for L1 norm
L1_Opts.Input    = Input;
L1_Opts.NSamples = 10^6;
L1_Opts.Type     = 'L1';
L1_Opts.Level    = level;

L1 = ZS_get_L_norm(Model,meta,L1_Opts);

function Y = Model_Penalty(X,uq_model,uq_input,level)
    
    pdf = uq_evalPDF(X,uq_input);
    idx = pdf >= level;
    Y   = uq_evalModel(uq_model,X);

    Y(~idx,:) = inf;
end
