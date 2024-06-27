function Inputs = ZS_createInput_fun
%-------------------------------------------------------------------------------
% Name:           ZS_createInput_Fun
% Purpose:        This functions creates all uq_input based on the
%                 functions contained in Examples/Functions
% Last Update:    25.04.2024
%-------------------------------------------------------------------------------
names = ZS_get_fun_names;

count = 1;

% Branin function
OPTS.Marginals(1).Type       = 'Uniform';
OPTS.Marginals(1).Parameters = [-5 10];

OPTS.Marginals(2).Type       = 'Uniform';
OPTS.Marginals(2).Parameters = [0 15];

Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;


% Detpep10exp function
d = 3;
OPTS.Marginals = uq_Marginals(d, 'Uniform', [0,1]);
Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;

% franke
d = 2;
OPTS.Marginals = uq_Marginals(d, 'Uniform', [0,1]);
Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;

% friedman
d = 5;
OPTS.Marginals = uq_Marginals(d, 'Uniform', [0,1]);
Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;

% gfunc
d = 4;
OPTS.Marginals = uq_Marginals(d, 'Uniform', [0,1]);
Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;

% ishigami
d = 3;
OPTS.Marginals = uq_Marginals(d, 'Uniform', [-pi,pi]);
Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;

% limetal02non
d = 2;
OPTS.Marginals = uq_Marginals(d, 'Uniform', [0,1]);
Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;

% limetal02pol
d = 2;
OPTS.Marginals = uq_Marginals(d, 'Uniform', [0,1]);
Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;

% rastrigin
d = 2;
OPTS.Marginals = uq_Marginals(d, 'Uniform', [-5.12,5.12]);
Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;

% shortcolumn
OPTS.Marginals(1).Type    = 'Lognormal';
OPTS.Marginals(1).Moments = [5 0.5];

OPTS.Marginals(2).Type    = 'Gaussian';
OPTS.Marginals(2).Moments = [2000 400];

OPTS.Marginals(3).Type    = 'Gumbel';
OPTS.Marginals(3).Moments = [500 100];

Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;

% steelcolumn
b = 300;
t = 20;
h = 300;
OPTS.Marginals(1).Type    = 'Lognormal';
OPTS.Marginals(1).Moments = [400 35];

OPTS.Marginals(2).Type    = 'Gaussian';
OPTS.Marginals(2).Moments = [500 50]*1000;

OPTS.Marginals(3).Type    = 'Gumbel';
OPTS.Marginals(3).Moments = [600 90]*1000;

OPTS.Marginals(4).Type    = 'Gumbel';
OPTS.Marginals(4).Moments = [600 90]*1000;

OPTS.Marginals(5).Type    = 'Lognormal';
OPTS.Marginals(5).Moments = [b 3];

OPTS.Marginals(6).Type    = 'Lognormal';
OPTS.Marginals(6).Moments = [t 2];

OPTS.Marginals(7).Type    = 'Lognormal';
OPTS.Marginals(7).Moments = [h 5];

OPTS.Marginals(8).Type    = 'Gaussian';
OPTS.Marginals(8).Moments = [30 10];

OPTS.Marginals(9).Type    = 'Weibull';
OPTS.Marginals(9).Moments = [210 4.2]*1000;

Inputs.(names{count}) = uq_createInput(OPTS,'-private');
clear OPTS
count = count + 1;


end