function Y = ZS_fun_tunnel(X)
%-------------------------------------------------------------------------------------
% Name         : TUNNEL
% Dimension    : 
% Family       : Polynomial and rational
% Input domain : 
%                
%                
%
% Description  : 
%-------------------------------------------------------------------------------------
d = size(X,2);
n = size(X,1);

% variables
if d == 8
    phi    = X(:,1)*pi/180;
    c      = X(:,2);
    E      = X(:,3)*10^6; % in GPa
    v      = X(:,4);
    gamma  = X(:,5);
    R      = X(:,6);
    H      = X(:,7);
    lambda = X(:,8);
elseif d == 3
    phi    = 29*pi/180;
    c      = 600;
    E      = X(:,1)*10^6; % in GPa
    v      = 0.25;
    gamma  = 27;
    R      = X(:,2);
    H      = 800;
    lambda = X(:,3);
end


% Some constants
sig0    = gamma.*H;
sigC    = getSigC;
Kp      = getKp; 
G       = E./(2.*(1+v));
psi     = max(phi-30*pi/180,0);
K       = 1+sin(psi)./(1-sin(psi));
N       = 2.*sig0./sigC;

% Plastic radius 
lambdaE = 1./(Kp+1) .*( Kp - 1 + 2./N );
Rp      = getRp(lambda);


Y = getU(R,lambda)*1000;

function u = getU(r,lambda)
    u = zeros(n,size(r,2));
    
    idxELAS = lambda<lambdaE;
    idxPLAS = lambda>=lambdaE;

    uELAS = getU_ELAS(r,lambda);
    uPLAS = getU_PLAS(r);

    u(idxELAS,:) = uELAS(idxELAS,:);
    u(idxPLAS,:) = uPLAS(idxPLAS,:);

end

function u = getU_PLAS(r)
    f1 = -(1-2*v) .* ( (Kp+1) ./ (Kp-1));
    f2 = 2* ( ( 1+K.*Kp-v.*(Kp+1).*(K+1) ) ./ ( (Kp-1).*(K+Kp) ) );
    f3 = 2*(1-v) .* ( (Kp+1) ./ (Kp+K) );
    u = (r.*sig0 ./ (2.*G)) .* lambdaE .* ( f1 + f2.*(r./Rp).^(Kp-1) + f3.*(Rp./r).^(K+1));
end

function u = getU_ELAS(r,lambda)
    u = lambda .* (R.^2 ./ r) .* sig0./(2.*G);
end

function [sigR,sigTeta] = getSig(r,lambda)
    sigR      = zeros(n,size(r,2));
    sigR(r<R) = NaN;
    sigTeta   = sigR;

    idxPLAS = r >= R & r <= Rp;
    idxELAS = r > Rp;

    [sigRPLAS,sigTetaPLAS] = getSig_PLAS(r,lambda);
    [sigRELAS,sigTetaELAS] = getSig_ELAS(r,lambda);

    sigR(idxPLAS)    = sigRPLAS(idxPLAS);
    sigR(idxELAS)    = sigRELAS(idxELAS) ;

    sigTeta(idxPLAS)    = sigTetaPLAS(idxPLAS);
    sigTeta(idxELAS)    = sigTetaELAS(idxELAS) ;

end

function [sigR,sigTeta] = getSig_ELAS(r,lambda)
    term     = (Rp./r).^2;
    tempSigR = getSig_PLAS(Rp,lambda);
    sigR     = sig0 .* (1-term) + tempSigR.*term;
    sigTeta  = sig0 .* (1+term) - tempSigR.*term;
end

function [sigR,sigTeta] = getSig_PLAS(r,lambda)
    term    = (Kp-1);
    sigR    = (R./r).^-term .* ((1-lambda).*sig0 + sigC ./ term) - sigC./term;
    sigTeta = (R./r).^-term .* ((1-lambda).*sig0 + sigC ./ term).*Kp - sigC./term;
end

function out = getRp(lambda)
    term1 = 2./(Kp+1);
    term2 = (sigC + sig0.*(Kp-1)) ./ (sigC + (1-lambda).*sig0.*(Kp-1) );
    out = R.* ( term1 .* term2 ).^(1./(Kp-1));
end

function out = getSigC
    out = ( 2*c.*cos(phi) ) ./ ( 1-sin(phi) );
end

function out = getKp
    out = ( 1+sin(phi) ) ./ ( 1-sin(phi) );
end

end

