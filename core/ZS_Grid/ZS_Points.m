classdef ZS_Points
%-------------------------------------------------------------------------------
% Name:           ZS_GridPoints
% Purpose:        This class generates a set of subsets containing unidimensional 
%                 1d-vectors points according to a node familiy
% Last Update:    01.03.2024
%-------------------------------------------------------------------------------
    
properties
    Sj          (1,:) cell % Set in a dimension j
    nestedFlag  logical    % Logical value if the subsets of Sj are nested
    Family      char       % Family name of the basis 1d-vectors
    M           double     % Number of subsets of Sj (capital mu)
    N           double     % Total number of element in Sj
end

methods

    function self = ZS_Points(family,selection,expr,bounds)
    %-------------------------------------------------------------------------------
    % Name:           ZS_GridPoints
    % Purpose:        Constructor
    % Last Update:    01.03.2024
    %-------------------------------------------------------------------------------
    % Check 'family' and return empty class -> empty class constructor
    if ~exist("family",'var')
        return
    end

    [isValid,ErrMsg] = ZS_Validation.check_char(family,"Argument 'family' must be a character array");
    if ~isValid, error(ErrMsg);end

    [isValid,ErrMsg] = ZS_Validation.check_belongs(family,self.get_family);
    if ~isValid, error(ErrMsg);end

    % Check 'selection'
    if ~exist("selection",'var')
        error("Argument 'selection' is mandatory")
    end

    [isValid,ErrMsg] = ZS_Validation.check_array(selection,{{1,':'}},"Argument 'selection' must be an (1 x :) numerical array");
    if ~isValid, error(ErrMsg);end

    % Default value for selection
    if ~all(selection)
        error("Argument 'selection' cannot contain zero(s)")
    end

    % Default value for 'expr'
    if ~exist("expr",'var')
        expr = '2^n+1';
    end

    % Default value for 'bounds'
    if ~exist("bounds",'var')
        bounds = true;
    end
    

    self.Family  = family;
    
    new_selection = self.convert_pts(selection,expr);
    
    to_eval = ['self.get_pts_',family,'(new_selection,bounds)'];
    [S,flag] = eval(to_eval);
    
    if ~iscell(S)
        S = {S};
    end

    self.Sj         = S;
    self.M          = length(S);
    self.N          = self.get_total_pts(S); 
    self.nestedFlag = flag;
    end


    function print_set(self)
    %-------------------------------------------------------------------------------
    % Name:           print_set
    % Purpose:        Print the nodes of the sets in a scatter plot.
    % Last Update:    01.03.2024
    %-------------------------------------------------------------------------------
    figure
    for i = 1:self.M
        x_coord = self.Sj{i};
        y_coord = zeros(1,numel(self.Sj{i}))+i;
        scatter(x_coord,y_coord,'black','filled')
        grid on
        hold on
        pbaspect([1 1 1])
    end
    ylabel('Subset indices - $i$',Interpreter='latex')
    xlabel('[-1 1] - interval coordinates',Interpreter='latex')
    yticks(1:self.M)
    end

end

methods(Static)

    function families = get_family
    %-------------------------------------------------------------------------------
    % Name:           get_family
    % Purpose:        Remove the boundaries, i.e. the points [-1 1] of a 
    %                 unidimensional vector 'vec_1d'
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    obj = ZS_Points;
    class_method = methods(obj);
    index = contains(class_method,'get_pts');
    families = {class_method{index}};
    for i = 1:length(families)
        families{i} = replace(families{i},'get_pts_','');
    end
    end


    function new_selection = convert_pts(selection,expr)
    %-------------------------------------------------------------------------------
    % Name:           convert_pts
    % Purpose:        Map the expression 'expr' to every element of 'selection'
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    dim_sel = size(selection);

    % Default value for expr
    if ~exist("expr",'var')
        expr = {'i'};
    end

    % Pass 'expr' to a cell if 'expr' is given as a char
    if ~iscell(expr)
        expr = {expr};
    end

    dim_expr = size(expr);

    % Test if selection is a numerical array
    [isValid,errMes] = ZS_Validation.check_array(selection,{':'},"'selection' must be a numercial array");
    if ~isValid, error(errMes);end

    % Determine if 'selection' is a vector or a matrix
    if any(dim_sel == 1)
        isVec    = true;
        isMatrix = false;
    else
        isMatrix = true;
        isVec    = false;
    end

    % The size of 'expr' must then match
    if isVec

        [isValid,errMes] = ZS_Validation.check_cell(expr,{'char'},{{1,1}},"'expr' must be a cell array with size (1 x 1) and must contain only character arrays");
        if ~isValid, error(errMes);end

    else

        [isValid,errMes] = ZS_Validation.check_cell(expr,{'char'},{{1,':'}},"'expr' must be a cell array with size (1 x :) and must contain only character arrays");
        if ~isValid, error(errMes);end

        if dim_expr(2) ~= 1
            [isValid,errMes] = ZS_Validation.check_cell(expr,{'char'},{{1 dim_sel(2)}},"When 'selection' is a matrix, the mapping is performed column-wise. Then the number of columns must match with the number of elements in 'expr'");
            if ~isValid, error(errMes);end
        end

    end


    toEval    = cell(dim_expr);
    new_selection = zeros(dim_sel);

    operator  = '(?<!\.)\^|(?<!\.)\*|(?<!\.)\/|(?<!\.)';
    var       = '(?<=\()\s*[a-zA-Z]\s*(?=\))|(?<![a-zA-Z.])[a-zA-Z](?![a-zA-Z.])';
  
    
    for i = 1:length(expr)
        if length(expr) == 1
            toEval{i} = regexprep(expr{i}, var, 'selection');
        else
            toEval{i} = regexprep(expr{i}, var, 'selection(:,i)');
        end
        toEval{i} = regexprep(toEval{i}, operator, '.$0');  % replace all operator for element-wise operations
    end
    

    if length(toEval) == 1
        new_selection = eval(toEval{1});
    else
        for i = 1:length(toEval)
            new_selection(:,i) = eval(toEval{i});
        end
    end

    new_selection = ceil(new_selection); % this function returns only integers
    end

    function new_vec_1d = remove_bounds(vec_1d)
    %-------------------------------------------------------------------------------
    % Name:           remove_bounds
    % Purpose:        Remove the boundaries, i.e. the points [-1 1] of a 
    %                 unidimensional vector 'vec_1d'
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    [isValid,errMes] = ZS_Validation.check_array(vec_1d,{':'},"'vec_1d' must be a numercial array");
    if ~isValid, error(errMes);end

    new_vec_1d = vec_1d;

    if numel(new_vec_1d) > 1
        index = any(new_vec_1d == [-1;1]);
        new_vec_1d(index) = [];
    end
    end

    function nestedFlag = check_nested(S)
    %-------------------------------------------------------------------------------
    % Name:           check_nested
    % Purpose:        According to a certain set, check if the
    %                 number of requested generates a nested sequence
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    if ~iscell(S)

        nestedFlag = false;
        return

    else

        [isValid,errMes] = ZS_Validation.check_cell(S,{'double','char','string'},{{1,':'}},"'S' must be a cell array with size (1 x :)");
        if ~isValid, error(errMes);end

        M = length(S);
        for i = 2:M
            if ~all(ismember(S{i-1},S{i}))
                nestedFlag = false;
                return
            end
        end
    
        nestedFlag = true;

    end
    end

    function nTot = get_total_pts(S)
    %-------------------------------------------------------------------------------
    % Name:           get_total_pts
    % Purpose:        Count the total number of points within the set S
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    nTot = numel(horzcat(S{:}));
    end

    function [nodes,nestedFlag] = get_pts_linspace(selection,bounds)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_linspace
    % Purpose:        Create a set of equally spaced 1d vectors. 'selection'
    %                 drives the position and the number of points within
    %                 each 1d-vector.
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    if ~exist("bounds","var")
        bounds = true;
    end

    M = numel(selection);
    nodes      = cell(1,M);

    for i = 1:M

        n = selection(i);

        if n == 1
            vec_1d        = 0;
        else
            vec_1d        = linspace(-1,1,n);
        end

        if ~bounds
            vec_1d = ZS_Points.remove_bounds(vec_1d);
        end

        nodes{i} = vec_1d;

    end

    if M == 1
        nodes = nodes{1};
        nestedFlag = false;
    else
        nestedFlag = ZS_Points.check_nested(nodes);
    end

    end

    function [nodes,nestedFlag] = get_pts_chebyshev_1(selection,~)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_chebyshev_1
    % Purpose:        Create a set of Chebyshev nodes of the first kind.
    %                 See also get_pts_linspace.
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    M = numel(selection);
    nodes      = cell(1,M);

    for i = 1:M

        n = selection(i);

        vec_1d = zeros(1,n);
    
        for j = 1:n
           vec_1d(j) = -cos( (2*j-1)/(2*n) * pi); 
        end
        
        nodes{i} = round(vec_1d,12);
    end

    if M == 1
        nodes = nodes{1};
        nestedFlag = false;
    else
        nestedFlag = ZS_Points.check_nested(nodes);
    end

    end


    function [nodes,nestedFlag] = get_pts_chebyshev_2(selection,bounds)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_chebyshev_2
    % Purpose:        Create a set of Chebyshev nodes of the second kind.
    %                 See also get_pts_linspace.
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    if ~exist("bounds","var")
        bounds = true;
    end

    M = numel(selection);
    nodes      = cell(1,M);

    for i = 1:M

        n = selection(i);
    
        vec_1d = zeros(1,n);
    
        if n == 1
    
            vec_1d = 0;
    
        else
            
            for j = 1:n
                vec_1d(j) = -cos( (j-1)/(n-1) * pi); 
            end

            vec_1d = round(vec_1d,12);
            vec_1d = unique(vec_1d);
    
        end

        if ~bounds
            vec_1d = ZS_Points.remove_bounds(vec_1d);
        end
        
        nodes{i} = vec_1d;

    end

    if M == 1
        nodes = nodes{1};
        nestedFlag = false;
    else
        nestedFlag = ZS_Points.check_nested(nodes);
    end

    end


    function [nodes,nestedFlag] = get_pts_legendre(selection,~)
    %-------------------------------------------------------------------------------
    % name:           get_pts_legendre
    % Purpose:        Create a set of Gauss-Legendre nodes.
    %                 See also get_pts_linspace.
    %                 This script is an adaptation of 'lgwt.m' from
    %                 Greg von Winckel
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    M = numel(selection);
    nodes      = cell(1,M);

    for i = 1:M

        n = selection(i);
    
        if n == 1

            vec_1d = 0;
            nodes{i} = vec_1d;

        else

            n = n-1;
            N1 = n+1; 
            N2 = n+2;
            xu = linspace(-1,1,N1)';
            % Initial guess
            temp = ZS_Points.get_pts_chebyshev_1(n+1);
            vec_1d = temp';
            % Legendre-Gauss Vandermonde Matrix
            L = zeros(N1,N2);
            % Derivative of LGVM
            Lp = zeros(N1,N2);
            % Compute the zeros of the N+1 Legendre Polynomial
            % using the recursion relation and the Newton-Raphson method
            y0 = 2;
            % Iterate until new points are uniformly within epsilon of old points
            while max(abs(vec_1d - y0))>eps
                
                
                L(:,1)  = 1;
                Lp(:,1) = 0;
                
                L(:,2)  = vec_1d;
                Lp(:,2) = 1;
                
                for k = 2:N1
                    L(:,k+1) = ( (2*k-1)*vec_1d.*L(:,k)-(k-1)*L(:,k-1) )/k;
                end
             
                Lp     = (N2)*( L(:,N1)-vec_1d.*L(:,N2) )./(1-vec_1d.^2);   
                
                y0     = vec_1d;
                vec_1d = y0-L(:,N2)./Lp;
            end
            vec_1d = vec_1d';
            

            nodes{i} = vec_1d;

        end
        nestedFlag(i) = false;

    end

    if M == 1
        nodes = nodes{1};
        nestedFlag = false;
    else
        nestedFlag = ZS_Points.check_nested(nodes);
    end

    end

    function [nodes,nestedFlag] = get_pts_lobatto(selection,bounds)
    %-------------------------------------------------------------------------------
    % name:           get_pts_lobatto
    % Purpose:        Create a set of Gauss-Legendrel-Lobatto nodes.
    %                 See also get_pts_linspace.
    %                 This script is an adaptation of 'lglnodes.m' from
    %                 Greg von Winckel
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    if ~exist("bounds","var")
        bounds = true;
    end

    M = numel(selection);
    nodes      = cell(1,M);

    for i = 1:M

        n = selection(i);
    
        if n == 1

            vec_1d = 0;
            nodes{i} = vec_1d;

        else

            n  = n-1;
            N1 = n+1;
            
            % Use the Chebyshev-Gauss-Lobatto nodes as the first guess
            temp = ZS_Points.get_pts_chebyshev_2(n+1);
            vec_1d = temp';
            
            % The Legendre Vandermonde Matrix
            P=zeros(N1,N1);
            
            x_old=2;
            while max(abs(vec_1d-x_old))>eps
                x_old=vec_1d;
                    
                P(:,1)=1;    P(:,2)=vec_1d;
                
                for k=2:n
                    P(:,k+1)=( (2*k-1)*vec_1d.*P(:,k)-(k-1)*P(:,k-1) )/k;
                end
                 
                vec_1d=x_old-( vec_1d.*P(:,N1)-P(:,n) )./( N1*P(:,N1) );
                         
            end

            vec_1d = vec_1d';

            if ~bounds
                vec_1d = ZS_Points.remove_bounds(vec_1d);
            end

            nodes{i} = vec_1d;
        end

    end


    if M == 1
        nodes = nodes{1};
        nestedFlag = false;
    else
        nestedFlag = ZS_Points.check_nested(nodes);
    end

    end

    

end






end

