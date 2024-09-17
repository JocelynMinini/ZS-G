classdef ZS_Grid < dynamicprops
%-------------------------------------------------------------------------------
% Name:           ZS_Grid
% Purpose:        This class generates grids
% Last Update:    06.03.2024
%-------------------------------------------------------------------------------
    
properties
    Grid
    Internal
    Options
end

methods

    function self = ZS_Grid(opts)
    %-------------------------------------------------------------------------------
    % Name:           ZS_Grid
    % Purpose:        Constructor
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    self.Options = opts;   
    % First of all, check user arguments
    self.Internal.Validation = ZS_Validation(opts);
    summary = logical(self.Internal.Validation.Summary);

    if ~all(summary)
        field_names = fieldnames(self.Internal.Validation);
        error_in = field_names(~summary);

        Message = "Error in user input arguments. The following error message(s) was/were returned : \n";
        for i = 1:length(error_in)
                Message = strcat(Message," - ",self.Internal.Validation.(error_in{i}).error,'\n');
        end
        
        error('foo:bar',Message)
    end

    % Then create the unit grid
    self = self.create_grid;

    % Try to put a name
    if self.Internal.Validation.Name.existFlag
        dyn.name = addprop(self,'Name');
        self.Name = self.Internal.Validation.Name.opts;
    end

    % Map the grid if necessary
    if self.Internal.Validation.Mapping.existFlag
        self = self.create_map;
    else
        self.Grid = self.Internal.Grid.Unit_grid; % Return the unit grid if no mapping
    end

    end


    function self = create_grid(self)
    %-------------------------------------------------------------------------------
    % Name:           create_grid
    % Purpose:        This function will call the classes dynamically to
    %                 create the requested grid
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    grid_class = self.Internal.Validation.Grid.opts.Class;
    toEvaluate = ['ZS_',grid_class,'Grid(self.Internal.Validation)'];
    self.Internal.Grid = eval(toEvaluate);
    end

    function self = create_map(self)
    %-------------------------------------------------------------------------------
    % Name:           create_map
    % Purpose:        This function will map the grid according to the
    %                 random vector
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    d               = self.Internal.Grid.Dimensions(2);
    Input           = self.Internal.Validation.Mapping.opts.RandomVector;
    alpha           = self.Internal.Validation.Mapping.opts.CI;
    mapping         = self.Internal.Validation.Mapping.opts.Type;
    [support,level,newInput] = self.get_credible_interval(Input,alpha);

    if strcmp(mapping,'Rectangular') || isnan(level)
        
        grid = self.map_stretch(self.Internal.Grid.Unit_grid,support);
        grid = self.map_translate(grid,support);

    elseif strcmp(mapping,'Isoprobabilistic')

        grid = self.map_equidistributed(self.Internal.Grid.Unit_grid); % Map the grid on tan(pi/4*x)

        grid = self.map_circular(grid); % Map the grid on a unit circle
        self.Internal.Grid.Mapping.Circular.Unit = grid;

        OPTS.Marginals = uq_Marginals(d, 'Gaussian', [0,1]); % Define the standardized Gaussian space (zero-mean, unit variance)
        U_Input = uq_createInput(OPTS,'-private');

        [U_support,U_level] = self.get_credible_interval(U_Input,alpha); % Compute the level bounding the Sl domain
        self.Internal.Grid.Mapping.Circular.Support = U_support;
        self.Internal.Grid.Mapping.Circular.Level   = U_level;

        grid = self.map_stretch(grid,U_support);
        grid = self.map_translate(grid,U_support);
        self.Internal.Grid.Mapping.Circular.Alpha = grid; % Map the grid according to some confidence interval
        
        grid = uq_GeneralIsopTransform(grid,U_Input.Marginals,U_Input.Copula,Input.Marginals,Input.Copula); % Map the grid with the Nataf transform

    else
        error("Unknown mapping method.")
    end

    self.Internal.Grid.Mapping.Type           = mapping;
    self.Internal.Grid.Mapping.Support        = support;
    self.Internal.Grid.Mapping.Level          = level;
    self.Internal.Grid.Mapping.CI             = alpha;
    self.Internal.Grid.Mapping.RandomVector   = Input;
    self.Internal.Grid.Mapping.U_RandomVector = newInput;
    self.Grid                                 = grid;
    end

    function print_grid(self,contour_pdf)
    %-------------------------------------------------------------------------------
    % Name:           print_grid
    % Purpose:        Print the grid
    % Last Update:    07.03.2024
    %-------------------------------------------------------------------------------

    if exist('contour_pdf','var') && contour_pdf && self.Internal.Validation.Mapping.existFlag
        support = self.Internal.Grid.Mapping.Support;
        Input   = self.Internal.Grid.Mapping.RandomVector;
        level   = self.Internal.Grid.Mapping.Level;

        if isnan(level)
            level = 0;
        end

        pdf = @(x) uq_evalPDF(x, Input);
        if self.Internal.Grid.Dimensions(2) == 2

            [X1,X2,Z] = ZS_Grid2Plot(pdf,'matlab',support(1,:),support(2,:));
            figure
            v = linspace(level,max(Z,[],'all'),20);
            contour(X1,X2,Z,v)
            hold on

        elseif self.Internal.Grid.Dimensions(2) == 3

            % Mean values
            mu = [Input.Marginals.Moments];
            mu = mu(1:2:end);

            [X1,X2,X3,Z] = ZS_Grid2Plot(pdf,'matlab',support(1,:),support(2,:),support(3,:));
            figure
            lvls = linspace(level,max(Z,[],'all'),20);
            contourslice(X1,X2,X3,Z,mu(1),mu(2),mu(3),lvls)
            colorbar
            view(3)
            hold on
        end
        self.get_print_grid(self.Grid,true);
    else
        self.get_print_grid(self.Grid,false);
    end
    

    end

    function print_unit_grid(self)
    %-------------------------------------------------------------------------------
    % Name:           print_unit_grid
    % Purpose:        Print the unit grid
    % Last Update:    07.03.2024
    %-------------------------------------------------------------------------------
    self.get_print_grid(self.Internal.Grid.Unit_grid,false);
    end

    function print_basis(self,varargin)
    %-------------------------------------------------------------------------------
    % Name:           print_grid
    % Purpose:        Print the basis vectors
    % Last Update:    07.03.2024
    %-------------------------------------------------------------------------------
    field_names = fieldnames(self.Internal.Grid.Basis);
    index = cellfun(@(x) contains(x,'X_'),field_names);
    field_names = field_names(index,:);

    if length(varargin) == 0
        for i = 1:length(field_names)
            self.Internal.Grid.Basis.(field_names{i}).print_set;
            title(strcat("Basis vectors in dimension ",field_names{i}))
        end
    else
        for i = 1:length(varargin)
            try
                self.Internal.Grid.Basis.(varargin{i}).print_set;
                title(strcat("Basis vectors in dimension ",field_names{i}))
            catch
                ErrMsg = strcat("The basis variable ",string(varargin{i})," does not exist");
                error(ErrMsg)
            end
        end
    end
    end

    function print_multi_indices(self)
    %-------------------------------------------------------------------------------
    % Name:           print_multi_indices
    % Purpose:        Print the basis vectors
    % Last Update:    07.03.2024
    %-------------------------------------------------------------------------------
    class = self.Internal.Grid.Class;

    if strcmp(class,'FullTensor')
        error("FullTensor grids do not need set of multi-indices")
        return
    end

    self.Internal.Grid.print_multi_indices;
    end

end


methods (Static)

    function [support,level,new_uq_input,solver_ouput] = get_credible_interval(uq_input,alpha)
    %-------------------------------------------------------------------------------
    % Name:           get_credible_interval
    % Purpose:        Stretch the unit_grid over the intervals given by
    %                 'support'
    % Last Update:    07.03.2024
    %-------------------------------------------------------------------------------
    if ~exist("uq_input","var") || ~exist("alpha","var")
        error("Not enough input arguments. Two arguments are required")
    end

    if ~strcmp(class(uq_input) , 'uq_input')
        error("First argument must be a 'uq_input' object")
    end

    if alpha >= 1 || alpha <= 0
        error("Confidence level 'alpha' must belong to ]0,1[")
    end

    cv = 0.01; % 1% error is acceptable
    n_req = (1-alpha) / (alpha*cv^2);
    
    if n_req > 5*10^7
        warning("Number of samples has been truncated to 10^7 for stability reasons. Integral approximation may be inaccurate (> 1% error).")
        n = 5*10^7;
    else
        n = round(n_req);
    end

    d = size(uq_input.Marginals,2);

    % The solver does not work if all distributions are uniform, skip in
    % this case
    index = ZS_Grid.get_all_uniform(uq_input);
    param = {uq_input.Marginals.Parameters}';
    param = cell2mat(param);

    if all(index)

        support = param;
        level   = NaN;

    else

        % First draw some sample from the random vector
        X = uq_getSample(uq_input,n);
        % Then evaluate the PDF
        f = uq_evalPDF(X, uq_input);
        % Numercial integration over Sl is driven the Monte-Carlo method
        fun = @(x) fun_indicator(x,alpha,f);
        % Now find the correpoding level by solving 
        %opts = optimset('Display','iter'); % show iterations
        [level,~,~,solver_ouput] = fzero(fun,[0 max(f,[],'all')]);
        % sanity check in 2d : l = alpha/(2*pi*sig1*sig2);
        % Select the points inside of the region
        index_level = f>level;
        % Make the hypercube of the boundary points
        [minA,MaxA] = bounds(X(index_level,:),1);
        support = [minA;MaxA]';
    
        % Overwrite the support if the input is 'uniform' (for accuracy)
        support(index,:) = param(index,:);
    end

    for i = 1:d
        OPTS.Marginals(i).Type = 'Uniform';
        OPTS.Marginals(i).Parameters = support(i,:);
    end
    new_uq_input = uq_createInput(OPTS,'-private');


    function out = fun_indicator(level,ci,f)
        N = size(f,1);
        % Numercial integration over Sl is driven the Monte-Carlo method
        Sl_bar = f < level;
        N_fail = sum(Sl_bar);
        out = N_fail/N - ci;
    end

    end

    function index = get_all_uniform(uq_input)
    %-------------------------------------------------------------------------------
    % Name:           get_all_uniform
    % Purpose:        Check if all marginals are uniform and return their
    %                 positions
    % Last Update:    01.05.2024
    %-------------------------------------------------------------------------------
    dist  = {uq_input.Marginals.Type};
    index = (cellfun(@(x) strcmp(x,'Uniform'),dist))';
    end

    function mapped_grid = map_stretch(grid,support)
    %-------------------------------------------------------------------------------
    % Name:           map_stretch
    % Purpose:        Stretch the unit_grid over the intervals given by
    %                 'support'
    % Last Update:    07.03.2024
    %-------------------------------------------------------------------------------
    d = size(grid,2);
    if d ~= size(support,1)
        error("The dimension of the support and of the grid must match")
    end

    % Transpose the grid
    grid = grid';
    
    % Built the transformation matrix
    A = eye(d).*(support(:,2)-support(:,1))/2;

    % And map
    mapped_grid = (A*grid)';
    end

    function mapped_grid = map_translate(grid,support)
    %-------------------------------------------------------------------------------
    % Name:           map_translate
    % Purpose:        Translate the unit_grid on the center given by 'support'
    % Last Update:    07.03.2024
    %-------------------------------------------------------------------------------
    d = size(grid,2);
    if d ~= size(support,1)
        error("The dimension of the support and of the grid must match")
    end

    % Transpose the grid
    grid = grid';
    
    % Built the transformation matrix
    A = (support(:,1)+support(:,2))/2;

    % And map
    mapped_grid = (grid + A)';
    end

    function mapped_grid = map_equidistributed(grid)
    %-------------------------------------------------------------------------------
    % Name:           map_equidistributed
    % Purpose:        Initial map of the grid, such that the grid is then equidistributed
    %                 on the hypersphere.
    % Last Update:    01.05.2024
    %-------------------------------------------------------------------------------
    mapped_grid = tan(pi/4*grid);
    end

    function mapped_grid = map_circular(grid)
    %-------------------------------------------------------------------------------
    % Name:           get_circular_map
    % Purpose:        Map the unit grid on a circular support defined by 
    %                 yi = xi * (|xi|_inf / |xi|_2)
    % Last Update:    17.04.2024
    %-------------------------------------------------------------------------------
    for i = 1:length(grid)
        vec = grid(i,:);
        lambda = norm(vec,inf)/norm(vec,2);
        grid(i,:) = vec*lambda;
    end

    grid(isnan(grid)) = 0;
    mapped_grid = grid;
    end

    function get_print_grid(the_grid,overlap)
    %-------------------------------------------------------------------------------
    % Name:           print_grid
    % Purpose:        Print any grid
    % Last Update:    07.03.2024
    %-------------------------------------------------------------------------------
    dim = size(the_grid);
    [minA,MaxA] = bounds(the_grid,1);
    limits = [minA;MaxA]';
    limits = ZS_Grid.get_round(limits);
    
    if ~overlap
        figure
    end

    if dim(2) == 2
        x_coord = the_grid(:,1);
        y_coord = the_grid(:,2);
        scatter(x_coord,y_coord,'black','filled')
        grid on
        xlim(limits(1,:))
        ylim(limits(2,:))
        xlabel('X1')
        ylabel('X2')
        pbaspect([1 1 1])
    elseif dim(2) == 3
        x_coord = the_grid(:,1);
        y_coord = the_grid(:,2);
        z_coord = the_grid(:,3);
        scatter3(x_coord,y_coord,z_coord,'black','filled')
        grid on
        xlim(limits(1,:))
        ylim(limits(2,:))
        zlim(limits(3,:))
        xlabel('X1')
        ylabel('X2')
        zlabel('X3')
        pbaspect([1 1 1])
    else
        error("Plotting the grid works only for D = 2 or D = 3.")
    end
    end

    function a = get_round(a)
    %-------------------------------------------------------------------------------
    % Name:           get_round
    % Purpose:        Round to next bigger interger but also for negative
    % Last Update:    17.04.2024
    %-------------------------------------------------------------------------------
    a(:,1) = floor(a(:,1));
    a(:,2) = ceil(a(:,2));
    end

    
    
end







end

