function [varargout] = ZS_Grid2Plot(M,software,varargin)

software = lower(software);

switch nargin
    case 3
        d = 1;
    case 4
        d = 2;
    case 5
        d = 3;
    otherwise
        error('Too many input arguments.')
end

% Set up the grid
tol = 0.01;
n   = 100;
switch d
    case 1
        x1Lim = varargin{1};
        offset1 = tol*diff(x1Lim);
        x1 = linspace(x1Lim(1)-offset1,x1Lim(2)+offset1,10*n);
        X  = x1';
    case 2
        x1Lim = varargin{1};
        x2Lim = varargin{2};
        offset1 = tol*diff(x1Lim);
        offset2 = tol*diff(x2Lim);
        x1      = linspace(x1Lim(1)-offset1,x1Lim(2)+offset1,n);
        x2      = linspace(x2Lim(1)-offset2,x2Lim(2)+offset2,n);
        [X1,X2] = meshgrid(x1,x2);
        X       = [X1(:),X2(:)];
    case 3
        x1Lim = varargin{1};
        x2Lim = varargin{2};
        x3Lim = varargin{3};
        offset1 = tol*diff(x1Lim);
        offset2 = tol*diff(x2Lim);
        offset3 = tol*diff(x3Lim);
        x1         = linspace(x1Lim(1)-offset1,x1Lim(2)+offset1,n);
        x2         = linspace(x2Lim(1)-offset2,x2Lim(2)+offset2,n);
        x3         = linspace(x3Lim(1)-offset3,x3Lim(2)+offset3,n);
        [X1,X2,X3] = meshgrid(x1,x2,x3);
        X          = [X1(:),X2(:),X3(:)];
end


idx = randi([1,size(X,1)],1,5);

if isa(M,'uq_model')
    f = M;
elseif isa(M,'function_handle')
    try
        temp = M(X(idx,:));
        is_vectorized = size(temp,1) > 1;
    catch me
        is_vectorized = 0;
    end
    OPTS.mHandle = M;
    OPTS.isVectorized = logical(is_vectorized);
    f = uq_createModel(OPTS,'-private');
    clear OPTS
elseif isa(M,'char')
    OPTS.mString = M;
    f = uq_createModel(OPTS,'-private');
end

switch lower(software)
    case 'matlab'
        Y = uq_evalModel(f,X);
        Y = reshape(Y,size(X1));
    case 'mathematica'
        Y   = uq_evalModel(f,X);
        MAT = [X,Y];
    otherwise
        error('Unknown programming software.')
end


% output
if d == 1 && isequal(software,'matlab')
    varargout{1} = X1;
    varargout{2} = Y;
elseif d == 2 && isequal(software,'matlab')
    varargout{1} = X1;
    varargout{2} = X2;
    varargout{3} = Y;
elseif d == 3 && isequal(software,'matlab')
    varargout{1} = X1;
    varargout{2} = X2;
    varargout{3} = X3;
    varargout{4} = Y;
else
    varargout{1} = MAT;
end


end

