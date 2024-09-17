function OUT = ZS_RandomVectorPlot(uq_input,alpha,levels)

if ~isa(uq_input,'uq_input')
    error("First argument must be a 'uq_input'.")
end

d         = size(uq_input.Marginals,2);
n_points = 100;

support = ZS_Grid.get_credible_interval(uq_input,alpha);

for i = 1:length(levels)
    [~,levels(i)] = ZS_Grid.get_credible_interval(uq_input,levels(i));
end

%{
vectors = cell(1, d);
for i = 1:d
    vectors{i} = linspace(support(i, 1), support(i, 2), n_points);
end

% n-Multidimensional grid
[grid_vectors{1:d}] = ndgrid(vectors{:});
X  = cell2mat(cellfun(@(x) x(:), grid_vectors, 'UniformOutput', false));
fX = uq_evalPDF(X,uq_input);
%}

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

        x1      = linspace(support(idx(i,1),1),support(idx(i,1),2),100);
        x2      = linspace(support(idx(i,2),1),support(idx(i,2),2),100);
        [X1,X2] = meshgrid(x1(:), x2(:));
        xi      = [X1(:),X2(:)];


        % Nombre d'échantillons Monte Carlo pour les dimensions restantes
        n_mc_samples = 10000;  % Ajuster pour la précision souhaitée
        
        % Tableau pour stocker la densité marginale
        fX = zeros(size(xi, 1), 1);
        
        % Boucle sur chaque point projeté pour estimer la densité marginale
        for j = 1:size(xi, 1)
            % Générer n_mc_samples échantillons pour les dimensions restantes (3 à d)
            X_rest = uq_getSample(uq_input, n_mc_samples);
            
            % Créer les échantillons complets en fixant x1 et x2 et en générant aléatoirement les autres dimensions
            X_full = [repmat(xi(j, :), n_mc_samples, 1), X_rest(:, 3:end)];
            
            % Évaluer la densité complète en ces points
            f_full = uq_evalPDF(X_full, uq_input);
            
            % Calculer la moyenne des densités pour estimer la densité marginale
            fX(j) = mean(f_full);
        end


        OUT{i} = [xi,fX];

        %{
        notidx             = setdiff(1:d,idx(i,:));
        baseStr            = strtrim(repmat(' muX(%d) ', 1, d));
        strParts           = strsplit(sprintf(baseStr, 1:d), ' ');

        inner              = strParts;
        inner(idx(i,:))    = {'x(1)','x(2)'};
        inner(notidx)      = {'z'};
        inner              = strjoin(inner);

        outer              = strjoin(strParts(notidx));

        %toEval            = ['@(x) uq_evalPDF([', strjoin(strParts(idx(i,:)), ' '), '],uq_input)'];
        toEval             = ['@(x) sum(arrayfun(@(z) uq_evalPDF([',inner,'], uq_input), ',outer,'))'];
        f                  = eval(toEval);

        OUT{i} = ZS_Grid2Plot(f,'mathematica',support(idx(i,1),:),support(idx(i,2),:));
        %}
    end
end

OUT{i+1} = levels';




end