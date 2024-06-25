classdef ZS_Points
%-------------------------------------------------------------------------------
% Name:           ZS_GridPoints
% Purpose:        This class generates a set of subsets containing unidimensional 
%                 1d-vectors points according to a node familiy
% Last Update:    01.03.2024
%-------------------------------------------------------------------------------
    
properties
    Sj          (1,:) cell                        % Set in a dimension j
    nestedFlag  logical                           % Logical value if the subsets of Sj are nested
    Family      (1,:) char {mustBeText(Family)}   % Family name of the basis 1d-vectors, must be text
    M           double                            % Number of subsets of Sj (capital mu)
    N           double                            % Total number of element in Sj
    Vec         (1,:) double {mustBeNumeric(Vec)} % Vector of requested number of points, must be numeric
end

methods

    function self = ZS_Points(family,vec,bounds)
    %-------------------------------------------------------------------------------
    % Name:           ZS_GridPoints
    % Purpose:        Constructor
    % Last Update:    01.03.2024
    %-------------------------------------------------------------------------------
    arguments
        family (1,:) char                           = ''
        vec    (1,:) {mustBeNumeric,mustBePositive} = []
        bounds (1,1)                                = true
    end
    
    % Check 'family' and return empty class -> empty class constructor
    if isempty(family)
        return
    end

    [isValid,ErrMsg] = ZS_Validation.check_belongs(family,self.get_family);
    if ~isValid, error(ErrMsg);end

    self.Family = family;
    self.Vec    = vec;


    if ~bounds
        family = [family,'_noBounds'];

        if ~ZS_Validation.check_belongs(family,self.get_family)
            warning("No boundaries for the requested family is not supported -> using the corresponding one with boundaries instead.")
            family = family(1:end-9);
        end

    end
    
    to_eval = ['self.get_pts_',family,'(vec)'];
    [S,~,nestedFlag] = eval(to_eval);
    
    if ~iscell(S)
        S = {S};
    end

    self.Sj         = S;
    self.M          = length(vec);
    self.N          = self.get_total_pts(S); 
    self.nestedFlag = nestedFlag;
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
    xlim([-1 1])
    if self.M > 1
        ylim([1 self.M])
    end
    yticks(1:self.M)
    temp = string(self.Vec);
    yticklabels(cellstr(temp))
    end

end

methods(Static)

    function families = get_family
    %-------------------------------------------------------------------------------
    % Name:           get_family
    % Purpose:        Return the list of the basis vector families
    %                 currently supported in ZS+G
    % Last Update:    21.03.2024
    %-------------------------------------------------------------------------------
    obj = ZS_Points;
    class_method = methods(obj);
    index = contains(class_method,'get_pts') & ~contains(class_method,'generic');
    families = {class_method{index}};

    for i = 1:length(families)
        families{i} = replace(families{i},'get_pts_','');
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

        M = length(S);
        for i = 3:M
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

    function [S,W,nestedFlag] = postprocess(S,W,M)
    %-------------------------------------------------------------------------------
    % Name:           postprocess
    % Purpose:        If M=1 S-cell size is 1 -> return a vector and do not
    %                 evaluate check_nested
    % Last Update:    16.06.2024
    %-------------------------------------------------------------------------------
    if M == 1
        S = S{1};
        W = W{1};
        nestedFlag = false;
    else
        nestedFlag = ZS_Points.check_nested(S);
    end
    end


    function [S,W,nestedFlag] = get_pts_generic(vec,SGMK_name)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_generic
    % Purpose:        Create a set of 1d vector according to the method of
    %                 SGMK
    % Last Update:    15.06.2024
    %-------------------------------------------------------------------------------
    M = numel(vec);
    S = cell(1,M);
    W = S;

    toEval = [SGMK_name,'(vec(i),-1,1)'];

    for i = 1:M
        [S{i},W{i}] = eval(toEval);
    end

    [S,W,nestedFlag] = ZS_Points.postprocess(S,W,M);
    end


    function [S,W,nestedFlag] = get_pts_linspace(vec)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_linspace
    % Purpose:        Create a set of equally spaced 1d vectors WITH
    %                 boudaries.
    % Last Update:    15.06.2024
    %-------------------------------------------------------------------------------
    [S,W,nestedFlag] = ZS_Points.get_pts_generic(vec,'knots_trap');
    end


    function [S,W,nestedFlag] = get_pts_linspace_noBounds(vec)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_linspace_noBounds
    % Purpose:        Create a set of equally spaced 1d vectors WITHOUT
    %                 boudaries.
    % Last Update:    15.06.2024
    %-------------------------------------------------------------------------------
    M = numel(vec);
    S = cell(1,M);
    W = S;

    for i = 1:M
        k = 1:vec(i);
        S{i} = (2 * k) / (vec(i) + 1) - 1;
        W{i} = zeros(1,vec(i));
    end

    [S,W,nestedFlag] = ZS_Points.postprocess(S,W,M);
    end


    function [S,W,nestedFlag] = get_pts_chebyshev_1(vec)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_chebyshev_1
    % Purpose:        Create a set of Chebyshev nodes of the first kind.
    %                 See also get_pts_linspace.
    % Last Update:    15.06.2024
    %-------------------------------------------------------------------------------
    M = numel(vec);
    S = cell(1,M);
    W = S;

    for i = 1:M
        k = 1:vec(i);
        S{i} = -cos( (2*k-1)/(2*vec(i)) * pi);
        W{i} = zeros(1,vec(i));
    end

    [S,W,nestedFlag] = ZS_Points.postprocess(S,W,M);
    end


    function [S,W,nestedFlag] = get_pts_chebyshev_2(vec)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_chebyshev_2
    % Purpose:        Create a set of Chebyshev nodes of the second kind
    %                 WITH boundaries
    % Last Update:    15.06.2024
    %-------------------------------------------------------------------------------
    M = numel(vec);
    S = cell(1,M);
    W = S;

    for i = 1:M
        k = 1:vec(i);
        if isscalar(k)
            S{i} = 0;
        else
            S{i} = cos( (k-1)/(vec(i)-1) * pi); 
        end
        W{i} = zeros(1,vec(i));
    end

    [S,W,nestedFlag] = ZS_Points.postprocess(S,W,M);
    end

    function [S,W,nestedFlag] = get_pts_chebyshev_2_noBounds(vec)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_chebyshev_2_noBounds
    % Purpose:        Create a set of Chebyshev nodes of the second kind
    %                 WITHOUT boundaries
    % Last Update:    15.06.2024
    %-------------------------------------------------------------------------------
    M = numel(vec);
    S = cell(1,M);
    W = S;

    for i = 1:M
        k = 1:vec(i);

        temp = cos( (k-1) / (vec(i)-1) * pi); 
        S{i} = temp(2:end-1);
        W{i} = zeros(1,vec(i)-2);
    end

    [S,W,nestedFlag] = ZS_Points.postprocess(S,W,M);
    end


    function [S,W,nestedFlag] = get_pts_leja(vec)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_leja
    % Purpose:        Create a set of symetric Leja nodes
    % Last Update:    15.06.2024
    %-------------------------------------------------------------------------------
    M = numel(vec);
    S = cell(1,M);
    W = S;

    for i = 1:M
        [S{i},W{i}] = sort(knots_leja(vec(i),-1,1,'sym_line'));
    end

    [S,W,nestedFlag] = ZS_Points.postprocess(S,W,M);
    end


    function [S,W,nestedFlag] = get_pts_midpoints(vec)
    %-------------------------------------------------------------------------------
    % Name:           get_pts_midpoints
    % Purpose:        Create a set of Midpoints nodes
    % Last Update:    15.06.2024
    %-------------------------------------------------------------------------------
    [S,W,nestedFlag] = ZS_Points.get_pts_generic(vec,'knots_midpoint');
    end

end

end

