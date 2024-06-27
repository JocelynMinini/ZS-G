function RES = ZS_createAnalysis(this)
%-------------------------------------------------------------------------------
% Name:           ZS_createAnalysis
% Purpose:        ...
% Last Update:    31.05.2024
%-------------------------------------------------------------------------------
sampling = {'mc','lhs','sobol'};
% create multiple OPTS for the parfor
d       = this.Internal.Grid.Dimensions(2);
rep     = this.Options.Surrogate.Replicates;
n       = length(sampling)*rep+1;
support = this.Internal.Grid.Mapping.Support;


% C0-norm options
x_size = [];
for i = 1:d
    x_size(end+1) = support(i,2)-support(i,1);
end
optim_opts.Display    = 'none';
optim_opts.DiscPoints = ceil(100000^(1/d));

OPTS = repmat(struct('Type', '', 'Display', '', 'MetaType', '', 'Input', [],...
                     'Degree', [], 'Method', '',...
                     'ExpDesign', struct('X', [], 'Y', [])), n, 1);
for i = 1:n
    % General options
    OPTS(i).Type     = 'Metamodel';
    OPTS(i).Display  = 'quiet';
    OPTS(i).MetaType           = this.Options.Surrogate.Type;
    OPTS(i).Input              = this.Options.Mapping.RandomVector;
    
    % Surrogate specific options
    if strcmp(OPTS(i).MetaType,'PCE')
    
        OPTS(i).Degree = this.Options.Surrogate.Degree;
        OPTS(i).Method = 'LARS';

    
    elseif strcmp(OPTS(i).MetaType,'PCK') % Not used 

        OPTS(i).Mode = 'optimal';
        OPTS(i).PCE.Degree = this.Options.Surrogate.Degree;
    
    else
        error("Surrogate model must be 'PCE' or 'PCK'")
    end

    % Set the experimental design
    if i == n
        X_ED = this.Grid;
        %OPTS(i).Sampling = 'Sparse Grid'; <- just for verification
    else
        j = ceil(i/rep);
        method = sampling{j};
        %OPTS(i).Sampling = method; <- just for verification
        X_ED = uq_getSample(this.Options.Mapping.RandomVector,this.Internal.Grid.Dimensions(1),method);
    end

    Y_ED = uq_evalModel(this.Options.Surrogate.Model,X_ED);
    
    OPTS(i).ExpDesign.X = X_ED;
    OPTS(i).ExpDesign.Y = Y_ED;

    
end


% Defining the support for L2 integration
for i = 1:d
    IOpts.Marginals(i).Type       = 'Uniform';
    IOpts.Marginals(i).Parameters = support(i,:);
end

L2_Input = uq_createInput(IOpts,'-private');


% Error metrics
LOO  = zeros(n,1);
L2   = zeros(n,1);
C0   = zeros(n,1);
X_C0 = zeros(n,d);
T    = zeros(n,1);
D    = zeros(n,1);

parfor i = 1:n
    tic
    sm = uq_createModel(OPTS(i),'-private');
    
    D(i,:) = sm.PCE.Basis.Degree;

    % LOO error
    LOO(i) = sm.Error.ModifiedLOO;

    % C0 error
    fun   = @(X) -abs(uq_evalModel(this.Options.Surrogate.Model,X) - uq_evalModel(sm,X));
    [temp_xstar,temp_ystar] = uq_gso(fun, [], d , support(:,1)' , support(:,2)' , optim_opts);
    X_C0(i,:) = temp_xstar;
    C0(i,:)   = abs(temp_ystar);

    %{
    sub = 100;
    x = linspace(support(1,1),support(1,2),sub);
    y = linspace(support(2,1),support(2,2),sub);
    [X,Y] = meshgrid(x,y);
    Z = fun([X(:),Y(:)]);
    Z = reshape(Z,[sub,sub]);
    figure
    surf(X,Y,Z)
    hold on
    scatter3(X_C0(i,1),X_C0(i,2),fun(X_C0(i,:)),'red','filled')

    figure
    Z_M  = uq_evalModel(this.Options.Surrogate.Model,[X(:),Y(:)]);
    Z_M  = reshape(Z_M,[sub,sub]);
    Z_sm = uq_evalModel(sm,[X(:),Y(:)]);
    Z_sm = reshape(Z_sm,[sub,sub]);
    surf(X,Y,Z_M)
    hold on
    surf(X,Y,Z_sm)
    %}
    
    
    % L2 error using MCS
    X = uq_getSample(L2_Input,1);
    pdf_val = uq_evalPDF(X,L2_Input);
    X = uq_getSample(L2_Input,10^5);
    fun = @(X) (uq_evalModel(this.Options.Surrogate.Model,X) - uq_evalModel(sm,X)).^2;    
    int = mean(fun(X))/pdf_val;
    L2(i,:) = sqrt(int);

    %{
    % Sanity check using integral2 (same results obtained)
    test = @(x, y) arrayfun(@(xi, yi) fun([xi, yi]), x, y);
    sqrt(integral2(test,support(1,1),support(1,2),support(2,1),support(2,2)))
    %}
    t = toc;
    T(i,:) = t;

end

count = 1;
% Store the results according to the sampling method
for i = 1:length(sampling)
    RES(i).Method = sampling{i};
    index = count:count+rep-1;

    RES(i).LOO    = LOO(index,:);
    RES(i).C0     = C0(index,:);
    RES(i).X_C0   = X_C0(index,:);
    RES(i).L2     = L2(index,:);
    RES(i).T      = T(index,:);
    RES(i).Degree = D(index,:);

    count = count + rep;
end

% Grid based
RES(i+1).Method = 'smolyak';
RES(i+1).LOO    = LOO(end,:);
RES(i+1).C0     = C0(end,:);
RES(i+1).X_C0   = X_C0(end,:);
RES(i+1).L2     = L2(end,:);
RES(i+1).T      = T(end,:);
RES(i+1).Degree = D(end,:);
end