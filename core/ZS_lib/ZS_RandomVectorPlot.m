function OUT = ZS_RandomVectorPlot(uq_input,alpha,levels)

if ~isa(uq_input,'uq_input')
    error("First argument must be a 'uq_input'.")
end

d = size(uq_input.Marginals,2);


[support] = ZS_Grid.get_credible_interval(uq_input,alpha);

for i = 1:length(levels)
    [~,levels(i)] = ZS_Grid.get_credible_interval(uq_input,levels(i));
end

% Matrix of indices
idx = []; 
for i = 1:d
    temp = [i * ones(i, 1), (1:i)'];
    idx = [idx; temp];
end

idx = idx(:,[2 1]);

moments = [uq_input.Marginals.Moments];
moments = reshape(moments,[2,d]);

muX     = moments(1,:);
count = 1;


OUT = cell(size(idx,1),1);

for i = 1:size(idx,1)
    if idx(i,1) == idx (i,2) % diagonal
        baseStr = strtrim(repmat(' muX(%d) ', 1, d));
        strParts        = strsplit(sprintf(baseStr, 1:d), ' ');
        strParts{count} = 'x';
        toEval          = ['@(x) uq_evalPDF([', strjoin(strParts, ' '), '],uq_input)'];
        f               = eval(toEval);

        OUT{i} = ZS_Grid2Plot(f,'mathematica',support(count,:));

        count = count + 1;
    else
        baseStr                = strtrim(repmat(' muX(%d) ', 1, d));
        strParts               = strsplit(sprintf(baseStr, 1:d), ' ');
        strParts(idx(i,:))     = {'x(1)','x(2)'};
        toEval                 = ['@(x) uq_evalPDF([', strjoin(strParts, ' '), '],uq_input)'];
        f                      = eval(toEval);

        OUT{i} = ZS_Grid2Plot(f,'mathematica',support(idx(i,1),:),support(idx(i,2),:));
    end
end

OUT{end+1} = levels';



end