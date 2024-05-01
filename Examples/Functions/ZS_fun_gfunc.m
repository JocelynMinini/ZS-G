function Y = ZS_fun_gfunc(X)
%-------------------------------------------------------------------------------------
% Name         : G-FUNCTION
% Dimension    : d
% Family       : Rational 
% Input domain : [0,1]^d
% Description  : As discussed by Marrel et al. (2009), this test function is used as an 
%                integrand for various numerical estimation methods, including sensitivity 
%                analysis methods, because it is fairly complex, and its sensitivity indices 
%                can be expressed analytically. The exact value of the integral with this 
%                function as an integrand is 1. For each index i, a lower value of ai indicates 
%                a higher importance of the input variable xi. Above are the values of ai 
%                recommended by Crestaux et al. (2007).
%-------------------------------------------------------------------------------------
d = size(X,2);

a = ((1:d)-2)/2;
temp = (abs(4*X-2) + a) ./ (1+a);

Y = prod(temp,2);
end