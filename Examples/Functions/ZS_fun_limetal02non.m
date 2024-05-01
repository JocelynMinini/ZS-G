function Y = ZS_fun_limetal02non(X)
%-------------------------------------------------------------------------------------
% Name         : LIM ET AL. (2002) POLYNOMIAL FUNCTION
% Dimension    : 2
% Family       : Exponential and trigonometric
% Input domain : [0,1]^2
% Description  : This function is an example of a nonpolynomial model which exhibits 
%                a shape similar to that of a multivariate polynomial. Lim et al. (2002) 
%                compare predictions from this function with predictions from the 
%                Lim et al. (2002) Polynomial Function, due to the similarity in their 
%                shapes and y-ranges.
%------------------------------------------------------------------------------------
x1 = X(:,1);
x2 = X(:,2);

term1 = 30 + 5.*x1.*sin(5*x1);
term2 = 4 + exp(-5*x2);

Y = (term1.*term2 - 100) / 6;
end