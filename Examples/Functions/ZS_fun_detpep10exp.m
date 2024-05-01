function Y = ZS_fun_detpep10exp(X)
%-------------------------------------------------------------------------------------
% Name         : DETTE & PEPELYSHEV (2010) EXPONENTIAL FUNCTION
% Dimension    : 3
% Family       : Exponential
% Input domain : [0,1]^3
% Description  : This function has asymptotes. It is used for the comparison of computer 
%                experiment designs.
%-------------------------------------------------------------------------------------
x1 = X(:,1);
x2 = X(:,2);
x3 = X(:,3);

term1 = exp(-2./(x1.^1.75));
term2 = exp(-2./(x2.^1.5));
term3 = exp(-2./(x3.^1.25));

Y = 100 * (term1 + term2 + term3);
end