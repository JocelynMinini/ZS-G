function Y = ZS_fun_ishigami(X)
%-------------------------------------------------------------------------------------
% Name         : ISHIGAMI FUNCTION
% Dimension    : 3
% Family       : Trigonometric
% Input domain : [-Pi,Pi]^3
% Description  : The Ishigami function of Ishigami & Homma (1990) is used as an example 
%                for uncertainty and sensitivity analysis methods, because it exhibits 
%                strong nonlinearity and nonmonotonicity. It also has a peculiar dependence 
%                on x3, as described by Sobol' & Levitan (1999).
%
%                The values of a and b used by Crestaux et al. (2007) and Marrel et al. (2009) 
%                are: a = 7 and b = 0.1. Sobol' & Levitan (1999) use a = 7 and b = 0.05.
%-------------------------------------------------------------------------------------
x1 = X(:,1);
x2 = X(:,2);
x3 = X(:,3);

a = 7;
b = 0.1;

term1 = sin(x1);
term2 = a * (sin(x2)).^2;
term3 = b * x3.^4 .* sin(x1);

Y = term1 + term2 + term3;
end