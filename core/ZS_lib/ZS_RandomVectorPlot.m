function OUT = ZS_RandomVectorPlot(uq_input, alpha)
if ~isa(uq_input, 'uq_input')
    error("First argument must be a 'uq_input'.")
end

alpha = sort(alpha,'descend');

% Dimension of the problem
d = length(uq_input.Marginals);

% Compute the highest density region for having an interval 'support' in each dimension
HDR = ZS_Grid.get_credible_interval(uq_input, min(alpha));
support = HDR.Support;

% Create a matrix of indices for plotting combinations
idx = [];
for i = 1:d
    temp = [i * ones(d, 1), (1:d)'];
    idx = [idx; temp];
end

% Remove duplicate pairs and keep combinations where the first index <= second index
idx = unique(sort(idx, 2), 'rows');

% Initialize output cell array
OUT = cell(size(idx, 1), 2);

for idx_pair = 1:size(idx, 1)
    i = idx(idx_pair, 1);
    j = idx(idx_pair, 2);

    if i == j  % Diagonal elements: Marginal densities
        % Generate points over the support
        x_values = linspace(support(i, 1), support(i, 2), 1000)';

        % Evaluate the marginal density using the marginal's PDF
        MarginalDist = uq_input.Marginals(i);
        y_values = uq_all_pdf(x_values, MarginalDist);

        % Store the results
        OUT{idx_pair,1} = [x_values, y_values];

    else  % Off-diagonal elements: Joint marginal densities using Monte Carlo

        % Defined the projected input
        OPTS.Marginals         = rmfield(uq_input.Marginals([i j]),'Moments');
        OPTS.Copula.Type       = uq_input.Copula.Type;
        OPTS.Copula.Parameters = uq_input.Copula.Parameters([i j],[i j]);

        tempInput = uq_createInput(OPTS,'-private');
        
        
        uniformIdx = ZS_Grid.get_all_uniform(tempInput);
        allUniform = all( uniformIdx );
        % Compute the levels corresponding to the user-defined probabilities
        for o = 1:length(alpha)
            if allUniform
                modifiedLevels(o) = eps;
            else
                % Return the support first
                alphaTemp = alpha(o);
                HDR = ZS_Grid.get_credible_interval(uq_input, alphaTemp);
                support = HDR.Support;
                % Then compute
                tempIdx = [i j];
                tempIdx = tempIdx(~uniformIdx');
                maxVal = min(support(tempIdx,:),[],'all');
                idxMax = support([i j],:) == maxVal;
                fun     = @(x) (helper(tempInput,x,idxMax)-maxVal)^2;
                x       = fminbnd(fun,0,1);
                tempHDR = ZS_Grid.get_credible_interval(tempInput, x);
                modifiedLevels(o) = tempHDR.Level;
                
            end
        end
        
        OUT{idx_pair,2} = flip(modifiedLevels);

        % Then create the pdf-vector
        pdfFun = @(x) uq_evalPDF(x,tempInput);
        OUT{idx_pair,1} = ZS_Grid2Plot(pdfFun,'mathematica',support(i, :),support(j, :));      
        
    end
end

    function out = helper(uq_input,alpha,idxMax)
        tempHDR = ZS_Grid.get_credible_interval(uq_input, alpha);
        out = tempHDR.Support;
        out = out(idxMax);
    end

end
