function Y = ZS_fun_limetal02pol(X)
%-------------------------------------------------------------------------------------
% Name         : LIM ET AL. (2002) POLYNOMIAL FUNCTION
% Dimension    : 2
% Family       : Polynomial
% Input domain : [0,1]^2
% Description  : This function is a polynomial in two dimensions, with terms up to 
%                degree 5. It is nonlinear, and it is smooth despite being complex, 
%                which is common for computer experiment functions (Lim et al., 2002).
%------------------------------------------------------------------------------------
x1 = X(:,1);
x2 = X(:,2);

term1 = (5/2)*x1 - (35/2)*x2;
term2 = (5/2)*x1.*x2 + 19*x2.^2;
term3 = -(15/2)*x1.^3 - (5/2)*x1.*x2.^2;
term4 = -(11/2)*x2.^4 + (x1.^3).*(x2.^2);

Y = 9 + term1 + term2 + term3 + term4;
end