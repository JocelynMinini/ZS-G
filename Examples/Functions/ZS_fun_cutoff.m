function Y = ZS_fun_cutoff(X)
%-------------------------------------------------------------------------------------
% Name         : CUTOFF
% Dimension    : 2
% Family       : Exponential & Polynomial
% Input domain : [0,2]^2
% Description  : This function has a plateau at Y = 6
%-------------------------------------------------------------------------------------
f1 = exp(X(:,1)).^2 .* X(:,2);
f2 = (X(:,1)+X(:,2)+0.25).^2-0.2;
f3 = 6;
Y = min(f1,min(f2,f3));
end

