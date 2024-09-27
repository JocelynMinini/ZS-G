function Y = ZS_fun_stripfoot(X)
d = size(X,2);

% Variables
if d == 5
    phi   = X(:,1)*pi/180;
    c     = X(:,2);
    gamma = X(:,3);
    t     = X(:,4);
    F     = X(:,5);
elseif d == 3
    phi   = X(:,1)*pi/180;
    c     = X(:,2);
    gamma = 21;
    t     = 0.5;
    F     = X(:,3);
end

% Parameters
b = 3.0;

% Body
Nq = exp(pi*tan(phi)) .* (tan(pi/4 + phi/2)).^2;
Nc = (Nq - 1) .* cot(phi);
Ny = (Nq - 1) .* tan(phi)*1.5; %(Hansen)
q = t.*gamma;

qp = c.*Nc + q.*Nq + 0.5*b*gamma.*Ny;

Qp = qp*b;

Y = Qp./F;
end