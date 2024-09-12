function RES = ZS_get_compare(this)
%-------------------------------------------------------------------------------
% Name:           ZS_get_compare
% Purpose:        ...
% Last Update:    31.05.2024
%-------------------------------------------------------------------------------
sampling = {'MC','LHS','Sobol'};
% create multiple OPTS for the parfor
d         = this.Internal.Grid.Dimensions(2);
rep       = this.Options.Surrogate.Replicates;
n         = length(sampling)*rep+1;
support   = this.Internal.Grid.Mapping.Support;
trueModel = this.Options.Surrogate.Model;


% Set options for the C0-norm
x_size = [];
for i = 1:d
    x_size(end+1) = support(i,2)-support(i,1);
end
%C0_opts.optimOpts.Display    = 'none';
%C0_opts.optimOpts.DiscPoints = ceil(100000^(1/d));
C0_opts.optimOpts.Display     = 'off';
C0_opts.optimOpts.SwarmSize   = 150;
C0_opts.optimOpts.UseParallel = false;
C0_opts.support               = support;
C0_opts.d                     = d;


% Set options for the L2-norm
for i = 1:d
    IOpts.Marginals(i).Type       = 'Uniform';
    IOpts.Marginals(i).Parameters = support(i,:);
end
L_Input = uq_createInput(IOpts,'-private');

L_opts.Input    = L_Input;
L_opts.NSamples = 5*10^4;
L_opts.Type     = 'L1';



OPTS = cell(1,n);

for i = 1:n
    if i == n
        seed = 'Smolyak';
    else
        j = ceil(i/rep);
        seed = sampling{j};
    end
    OPTS{i} = ZS_get_PC_opts(this,seed);
end

% Preallocation
LOO     = zeros(n,1);
L1      = zeros(n,1);
L1_norm = zeros(n,1);
%L2      = zeros(n,1);
%L2_norm = zeros(n,1);
C0      = zeros(n,1);
X_C0    = zeros(n,d);
VS      = zeros(n,1);
T       = zeros(n,1);


parfor i = 1:n
    tic

    % Surrogate creation
    surrogateModel = uq_createModel(OPTS{i},'-private');

    % Polynomial degree Mean and variance
    %try
    %    D(i,:) = surrogateModel.PCE.Basis.Degree;
    %end

    % LOO error
    try
        LOO(i) = surrogateModel.Error.ModifiedLOO;
    catch
        LOO(i) = surrogateModel.Error.LOO;
    end

    % VS error
    VS(i) = surrogateModel.Error.Val;

    % C0 error
    [temp_xstar,temp_ystar] = ZS_get_C0(trueModel,surrogateModel,C0_opts);
    X_C0(i,:)               = temp_xstar;
    C0(i,:)                 = abs(temp_ystar);
   
    % L1 error using MCS
    [L1(i,:),L1_norm(i,:)] = ZS_get_L_norm(trueModel,surrogateModel,L_opts);
    
    % L2 error using MCS - no more used
    %[L2(i,:),L2_norm(i,:)] = ZS_get_L_norm(trueModel,surrogateModel,L2_opts,'L2');

    t = toc;
    T(i,:) = t;
    %clear surrogateModel
end

count = 1;
% Store the results according to the sampling method
for i = 1:length(sampling)
    RES(i).Method = sampling{i};
    index         = count:count+rep-1;

    RES(i).LOO     = LOO(index,:);
    RES(i).VS      = VS(index,:);
    RES(i).C0      = C0(index,:);
    RES(i).X_C0    = X_C0(index,:);
    RES(i).L1      = L1(index,:);
    RES(i).L1_norm = L1_norm(index,:);
    %RES(i).L2      = L2(index,:);
    %RES(i).L2_norm = L2_norm(index,:);
    RES(i).Time    = T(index,:);

    count = count + rep;
end

% Grid based
RES(i+1).Method  = 'smolyak';
RES(i+1).LOO     = LOO(end,:);
RES(i+1).VS      = VS(end,:);
RES(i+1).C0      = C0(end,:);
RES(i+1).X_C0    = X_C0(end,:);
%RES(i+1).L2      = L2(end,:);
%RES(i+1).L2_norm = L2_norm(end,:);
RES(i+1).L1      = L1(end,:);
RES(i+1).L1_norm = L1_norm(end,:);
RES(i+1).Time    = T(end,:);
end