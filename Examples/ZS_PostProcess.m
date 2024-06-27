function ZS_PostProcess(res, methods, QoI)

all_QoI     = {'LOO', 'C0', 'X_C0', 'L2'};
all_methods = {'mc', 'lhs', 'sobol', 'halton'};

% Validate and standardize the methods input
if ischar(methods)
    if strcmp(methods, 'all')
        methods = {'mc', 'lhs', 'sobol', 'halton'};
    else
        methods = {methods};
    end
elseif iscell(methods)
    %
else
    error('Methods should be either a character array or a cell array.');
end

if ~all(ismember(methods, all_methods))
    error('Method cell array contains invalid entries.');
end

% Validate and standardize the QoI input
if ischar(QoI)
    if strcmp(QoI, 'all')
        QoI = {'LOO', 'C0', 'X_C0', 'L2'};
    else
        QoI = {QoI};
    end
elseif iscell(methods)
%
else
    error('QoI should be either a character array or a cell array.');
end

if ~all(ismember(QoI, all_QoI))
    error('QoI cell array contains invalid entries.');
end



N = length(QoI);
M = length(methods);

% Indexing the method

for i = 1:N
    f = figure(i);
    current_QoI = QoI{i};
    
    for j = 1:M
        current_method = methods{j};
        index = ismember({res.Method},current_method);

        X = res(index).(current_QoI);
           
        switch current_QoI
    
            case 'X_C0'

                dim = size(X,2);
                
                switch dim

                    case 2
                        scatter(X(:,1),X(:,2))
                        hold on
                        scatter(res(end).(current_QoI)(1),res(end).(current_QoI)(2),100,"filled","black",'HandleVisibility','off')
                        xl = xline(res(end).(current_QoI)(1),'-.','HandleVisibility','off','LineWidth', 2);
                        xl.LabelVerticalAlignment = 'middle';
                        xl.LabelHorizontalAlignment = 'center';
                        yline(res(end).(current_QoI)(2),'-.','HandleVisibility','off','LineWidth', 2)
                        
                    case 3
                        scatter3(X(:,1),X(:,2),X(:,3))
                        hold on
                    otherwise
                        warning("X_C0 error can be plotted only for d = 2 or d = 3.")
                        close(f)
                end

                legend(methods(:))
                title('X_{C0}')
                pbaspect([1 1 1])
                xlabel('X_1') 
                xlabel('X_2') 
                try
                zlabel('X_3') 
                end

    
            otherwise

                histogram(X,'Normalization','pdf')
                legend(methods(:))
                title(current_QoI)
                pbaspect([1 1 1])
                xlabel([current_QoI,' (-)']) 
                ylabel('PDF (-)') 

                % Smolyak solution
                xl = xline(res(end).(current_QoI),'-.','Smolyak','HandleVisibility','off','LineWidth', 2);
                xl.LabelVerticalAlignment = 'middle';
                xl.LabelHorizontalAlignment = 'center';

                hold on
        
        end

   end
end




end
