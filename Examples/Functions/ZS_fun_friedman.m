function Y = ZS_fun_friedman(X)
%-------------------------------------------------------------------------------------
% Name         : FRIEDMAN FUNCTION
% Dimension    : 5
% Family       : Polynomial and trigonometric
% Input domain : [0,1]^d
% Description  : The Friedman function is used for modeling computer outputs.
%-------------------------------------------------------------------------------------
x1 = X(:,1);
x2 = X(:,2);
x3 = X(:,3);
x4 = X(:,4);
x5 = X(:,5);

term1 = 10 * sin(pi*x1.*x2);
term2 = 20 * (x3-0.5).^2;
term3 = 10*x4;
term4 = 5*x5;

Y = term1 + term2 + term3 + term4;
end