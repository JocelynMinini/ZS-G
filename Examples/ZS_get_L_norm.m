function [L,L_norm] = ZS_get_L_norm(trueModel,surrogateModel,opts)
%-------------------------------------------------------------------------------
% Name:           ZS_get_L_norm
% Purpose:        This function computes the L-norm using MC simulation
% Last Update:    12.09.2024
%-------------------------------------------------------------------------------
Input = opts.Input;
N     = opts.NSamples;
type  = opts.Type;

distType = {Input.Marginals.Type};
if isequal(distType{:},'Uniform')
    X       = uq_getSample(Input,1);
    pdf_val = uq_evalPDF(X,Input);
    X       = uq_getSample(Input,N,'lhs');
    idx     = ones(N,1);
else
    X       = uq_getSample(Input,N,'lhs');
    pdf_val = uq_evalPDF(X,Input);
    level   = opts.Level;
    idx     = pdf_val >= level;
end


switch type
    case 'L1'
        fun = @(X) abs(uq_evalModel(trueModel,X) - uq_evalModel(surrogateModel,X));
    case 'L2'
        fun = @(X) (uq_evalModel(trueModel,X) - uq_evalModel(surrogateModel,X)).^2;

    otherwise
        error("Type must be 'L1' or 'L2'")
end
    
int     = mean(idx.*(fun(X)./pdf_val));
ybar    = mean(uq_evalModel(trueModel,X));

switch type
    case 'L1'
        % null
    case 'L2'
        int = sqrt(int);

    otherwise
        error("Type must be 'L1' or 'L2'")
end
L      = int;
L_norm = int/ybar;
end

