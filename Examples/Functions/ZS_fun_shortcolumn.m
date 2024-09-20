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
n = size(X,1);
d = size(X,2);
if d ~= 5
    b = 5;
    h = 15;
    add = [b*ones(n,1),h*ones(n,1)];
    X = [add,X];
end
b  = X(:,1);
h  = X(:,2);
fy  = X(:,3);
Md = X(:,4);
Nd = X(:,5);

MRd = fy.* b.*(h.^2)/4;
NRd = b .*h .* fy;
Y = -Md./MRd - (Nd./NRd).^2 + 1;
end