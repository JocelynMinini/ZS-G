function Y = ZS_fun_branin(X)
%-------------------------------------------------------------------------------------
% Name         : BRANIN OR BRANIN-HOO
% Dimension    : 2
% Family       : Polynomial and trigonometric
% Input domain : x1 { [-5,10] | x2 { [0,15]
% Description  : The Branin, or Branin-Hoo, function has three global minima. The 
%                recommended values of a, b, c, r, s and t are: a = 1, b = 5.1 ⁄ (4π2), 
%                c = 5 ⁄ π, r = 6, s = 10 and t = 1 ⁄ (8π).
%------------------------------------------------------------------------------------

x1 = X(:,1);
x2 = X(:,2);

a = 1;
b = 5.1/(4*pi^2);
c = 5/pi;
r = 6;
s = 10;
t = 1/(8*pi);

term1 = a * (x2 - b*x1.^2 + c*x1 - r).^2;
term2 = s*(1-t)*cos(x1);

Y = term1 + term2 + s;
end