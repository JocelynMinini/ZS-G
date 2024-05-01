function Y = ZS_fun_rastrigin(X)
%-------------------------------------------------------------------------------------
% Name         : RASTRIGIN FUNCTION
% Dimension    : d
% Family       : Polynomial and trigonometric
% Input domain : [-5.12,5.12]^d
% Description  : The Rastrigin function has several local minima. It is highly multimodal, 
%                but locations of the minima are regularly distributed. It is shown in the 
%                plot above in its two-dimensional form.
%-------------------------------------------------------------------------------------
d = size(X,2);

temp = X.^2-10*cos(2*pi*X);
sigma = sum(temp,2);

Y = 10*d + sigma;
end