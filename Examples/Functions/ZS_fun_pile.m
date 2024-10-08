function Y = ZS_fun_pile(X)
% Pile strength according to Lang & Huder

% Variables
n = size(X,1);
d = size(X,2);
if d == 7
    D     = X(:,1);
    L     = X(:,2);
    phi   = X(:,3)*pi/180;
    c     = X(:,4);
    gamma = X(:,5);
    h_w   = X(:,6);
    F     = X(:,7);
elseif d == 4
    D     = X(:,1);
    L     = X(:,2);
    phi   = X(:,3)*pi/180;
    c     = repmat(26.7,n,1);
    gamma = repmat(20.8,n,1);
    h_w   = repmat(2,n,1);
    F     = X(:,4);
end

gammaW = 9.81;

% L must be smaller than l_cr
L_cr  = D .* exp(pi*tan(phi)).*tan(pi/4+phi/2);
%L_cr = D .* (2+(phi*180/pi)/8);
idx = L > L_cr;
L_cr(~idx,:) = L(~idx,:);

ratio  = L./D;

% Tip strength
Nq     = exp(pi*tan(phi)).*(tan(pi/4+phi/2)).^2;
Nc     = (Nq-1).*cot(phi);
chi    = (1.2 + tan(phi).^6).*(1 + 0.35./(1./ratio + 0.6./(1 + 7 *tan(phi).^4)));
sig_vp = L_cr.*gamma - max((L_cr-h_w)*gammaW,0);

qpl    = c.*Nc + sig_vp.*Nq;

ap     = (D/2).^2 * pi;

% Attention ! ajouter longueur critique
Rp     = qpl.*ap.*chi;

% Friction strength
Rs = Friction;
    

R = Rs + Rp;

Y = R./F;

% Friction strength
    function Rs = Friction
    
    % Friction strength
    %Ka    = (1-sin(phi))./(1+sin(phi));
    K     = 1-sin(phi);
    delta = phi;
    dh    = 1000;
    L_rep = repmat(L, 1, dh);
    indices = repmat(linspace(0, 1, dh), n, 1);
    hi = L_rep .* indices;


    sigma_v = gamma.*hi;
    
    w = hi;
    
    
    for i = 1:n
        index = w(i,:) < h_w(i,:);
        w(i,index) = NaN;
        w(i,:) = w(i,:)*gammaW;
        w(i,:) = w(i,:) - min(w(i,:));
    end

    w(isnan(w))=0;
    
    sigma_v_eff = sigma_v-w;
    qs          = K .* sigma_v_eff .* tan(delta) + c;
    %{
    Rs = gamma;
    for i = 1:size(gamma,1)
        Rs(i,:) = D(i,:) .* pi .* trapz(hi(i,:),qs(i,:));
    end
    %}
    dh = diff(hi, 1, 2);
    qs_avg = (qs(:, 1:end-1) + qs(:, 2:end)) / 2;
    Rs = pi * D .* sum(dh .* qs_avg, 2);
end




end