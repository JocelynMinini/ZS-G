function Y = ZS_fun_steelcolumn(X)
%-------------------------------------------------------------------------------------
% Name         : STEEL COLUMN FUNCTION
% Dimension    : 9
% Family       : Polynomial and rational
% Input domain : x1 = Fs : LN(400,35) 
%                x2 = P1 : N(500000,50000) 
%                x3 = P2 : G(600000,90000) 
%                x4 = P3 : G(600000,90000) 
%                x5 = B  : LN(b,3) 
%                x6 = D  : LN(t,2) 
%                x7 = H  : LN(h,5) 
%                x8 = F0 : N(30,10)
%                x9 = E  : W(210000,4200)
%
% Description  : The Steel Column function models the trade-off between cost and reliability 
%                for a steel column. The cost for the steel column is: Cost = b*t + 5*h, where 
%                b is the mean flange breadth, t (mm) is the mean flange thickness (mm), and h 
%                is the mean profile height (mm). The column length L is 7500 mm. 
%                Eldred et al. (2008) use the values b = 300, d = 20 and h = 300.
%-------------------------------------------------------------------------------------
Fs = X(:,1);
P1 = X(:,2);
P2 = X(:,3);
P3 = X(:,4);
B  = X(:,5);
D  = X(:,6);
H  = X(:,7);
F0 = X(:,8);
E  = X(:,9);

L = 7500;

P   = P1 + P2 + P3;
Eb = (pi^2).*E.*B.*D.*(H.^2) ./ (2*(L.^2));

term1 = 1 ./ (2.*B.*D);
term2 = F0.*Eb ./ (B.*D.*H.*(Eb-P));

Y = Fs - P.*(term1 + term2);
end