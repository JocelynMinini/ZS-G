function Y = ZS_fun_shortcolumn(X)
%-------------------------------------------------------------------------------------
% Name         : SHORT COLUMN FUNCTION
% Dimension    : 3
% Family       : Polynomial and rational
% Input domain : x1 = Y : LN(5,0.5) 
%                x2 = M : N(2000,400) 
%                x3 = P : G(500,100) 
%
% Description  : The Short Column function models a short column with uncertain material 
%                properties and subject to uncertain loads (Eldred et al., 2007). 
%                The parameters b (width of the cross-section, in mm) and h (depth of the 
%                cross-section, in mm) have nominal values b = 5 and h = 15.
%-------------------------------------------------------------------------------------
Y = X(:,1);
M = X(:,2);
P = X(:,3);

b = 5;
h = 15;

term1 = -4*M ./ (b.*(h.^2).*Y);
term2 = -(P.^2) ./ ((b.^2).*(h.^2).*(Y.^2));

Y = 1 + term1 + term2;
end