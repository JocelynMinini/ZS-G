function Y = ZS_fun_franke(X)
%-------------------------------------------------------------------------------------
% Name         : FRANKE'S FUNCTION
% Dimension    : 2
% Family       : Polynomial and exponential
% Input domain : [0,1]^2
% Description  : Franke's function has two Gaussian peaks of different heights, and a 
%                smaller dip. It is used as a test function in interpolation problems.
%-------------------------------------------------------------------------------------
x1 = X(:,1);
x2 = X(:,2);

term1 = 0.75 * exp(-(9*x1-2).^2/4 - (9*x2-2).^2/4);
term2 = 0.75 * exp(-(9*x1+1).^2/49 - (9*x2+1)/10);
term3 = 0.5 * exp(-(9*x1-7).^2/4 - (9*x2-3).^2/4);
term4 = -0.2 * exp(-(9*x1-4).^2 - (9*x2-7).^2);

Y = term1 + term2 + term3 + term4;
end