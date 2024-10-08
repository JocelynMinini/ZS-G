clc
clear
ZS_G
uqlab
ZS_R
clc

Inputs = ZS_createInput_fun;
Models = ZS_createModel_fun;

%% Short column model
modelName   = 'shortcolumn';
trueModel   = Models.(modelName);
trueModelFE = Models.([modelName,'FE']);

X = createVector2d(10, [1000 3000], [200 800]);
X = [repmat(5,length(X),1) X];

RES.(modelName).X        = X;
RES.(modelName).Y_MATLAB = uq_evalModel(trueModel,X);
%RES.(modelName).Y_FE     = ZS_parallel_evalModel(trueModelFE,X);


%% Strip foot model
modelName   = 'stripfoot';
trueModel   = Models.(modelName);
trueModelFE = Models.([modelName,'FE']);

X = createVector2d(10, [24 31], [1200 3000]);
X = [X(:,1) repmat(19.69,length(X),1) X(:,2)];

RES.(modelName).X        = X;
RES.(modelName).Y_MATLAB = uq_evalModel(trueModel,X);
%RES.(modelName).Y_FE     = ZS_parallel_evalModel(trueModelFE,X);


%% Truss structure model
modelName   = 'trussstructure';
trueModel   = Models.(modelName);
trueModelFE = Models.([modelName,'FE']);

X = createVector2d(10, [160 260], [15 25]);

RES.(modelName).X        = X;
RES.(modelName).Y_MATLAB = uq_evalModel(trueModel,X);
%RES.(modelName).Y_FE     = ZS_parallel_evalModel(trueModelFE,X);

%% Pile model
modelName   = 'pile';
trueModel   = Models.(modelName);
trueModelFE = Models.([modelName,'FE']);

X = createVector2d(10, [0.4 1.5], [5 30]);
X = [X(:,1) X(:,2) repmat(30,length(X),1) repmat(5000,length(X),1)];

RES.(modelName).X        = X;
RES.(modelName).Y_MATLAB = uq_evalModel(trueModel,X);
%RES.(modelName).Y_FE     = ZS_parallel_evalModel(trueModelFE,X);








ZS_save('FEvsMATLAB.mat',RES)



function X = createVector2d(n,xRange,yRange)
    x1      = linspace(xRange(1),xRange(2),n);
    x2      = linspace(yRange(1),yRange(2),n);
    [X1,X2] = meshgrid(x1,x2);
    X       = [X1(:),X2(:)];
end