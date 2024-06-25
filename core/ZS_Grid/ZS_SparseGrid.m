classdef ZS_SparseGrid
%-------------------------------------------------------------------------------
% Name:           ZS_SparseGrid
% Purpose:        This class generates sparse grids
% Last Update:    06.03.2024
%-------------------------------------------------------------------------------
    
properties
    Unit_grid
    Class
    Level
    Dimensions
    nestedFlag
    Basis
    Mapping
    SGMK
end

methods

    function self = ZS_SparseGrid(Validation)
    %-------------------------------------------------------------------------------
    % Name:           ZS_SparseGrid
    % Purpose:        Constructor
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    if nargin == 0 % Default constructor with no args
        return    
    end

    self.Class        = Validation.Grid.opts.Class;
    self.Dimensions   = [0,Validation.Grid.opts.D];
    self.Level        = Validation.Grid.opts.Level;
    self.Basis.PNorm  = Validation.Basis.opts.PNorm;
    self.Basis.Family = Validation.Basis.opts.Family;
    self.Basis.Growth = Validation.Basis.opts.Growth;
    self.Basis.Bounds = Validation.Basis.opts.Bounds;


    % 1. create the set of multi-indices to select the cartesian products
    self = self.set_set_multi_indices;
    
    % 2. create the unidimensional vectors in each dimensions
    self = self.set_basis;
  
    % 3. create the grid
    self = self.set_sparse_grid;

    % 4. Extract the dimension of the grid
    self.Dimensions = size(self.Unit_grid);

    % 5. Check if the grid is nested
    self = self.check_nested;
    end


    function self = set_set_multi_indices(self)
    %-------------------------------------------------------------------------------
    % Name:           create_set_multi_indices
    % Purpose:        This function will generate a set of multi-indices
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    d     = self.Dimensions(2);
    mu    = self.Level;
    pNorm = self.Basis.PNorm;
    fun  = self.get_hyperbolic_truncation(pNorm);

    self.Basis.MultiIndices = multiidx_gen(d,fun,mu,1);
    end


    function self = set_basis(self)
    %-------------------------------------------------------------------------------
    % Name:           set_basis
    % Purpose:        This function will generate the basis structure
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    d      = self.Dimensions(2);
    family = self.Basis.Family;
    bounds = self.Basis.Bounds;
    growth = self.Basis.Growth;

    vec   = 1:5;

    field = 'X_';
    for i = 1:d
        name  = strcat(field,string(i));
        vec_j = growth{i}(vec); 
        self.Basis.(name) = ZS_Points(family{i},vec_j,bounds{i});
    end

    end


    function self = set_sparse_grid(self)
    %-------------------------------------------------------------------------------
    % Name:           set_sparse_grid
    % Purpose:        This function will generate the sparse grid
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    I      = self.Basis.MultiIndices;
    growth = self.Basis.Growth;

    % Convert family to handle functions
    family     = self.Basis.Family;
    family_fun = family;


    for i = 1:self.Dimensions(2)
        if self.Basis.Bounds{i}
            toEval = ['@(n) ZS_Points.get_pts_',family{i},'(n)'];
        else
            toEval = ['@(n) ZS_Points.get_pts_',family{i},'_noBounds','(n)'];
        end
        family_fun{i} = eval(toEval); 
    end

    self.SGMK      = create_sparse_grid_multiidx_set(I,family_fun,growth);
    temp           = reduce_sparse_grid(self.SGMK);
    self.Unit_grid = [temp.knots]';
    end
    

    function self = check_nested(self)
    %-------------------------------------------------------------------------------
    % Name:           check_nested
    % Purpose:        This function will check if the grid is nested or not
    % Last Update:    27.03.2024
    %-------------------------------------------------------------------------------
    d = self.Dimensions(2);
    check = logical.empty();
    for i = 1:d
        check(end+1) = self.Basis.(strcat("X_",string(i))).nestedFlag;
    end

    self.nestedFlag = all(check);
    end

    function self = print_multi_indices(self)
    %-------------------------------------------------------------------------------
    % Name:           print_multi_indices
    % Purpose:        This function will print the multi-indices set
    % Last Update:    28.03.2024
    %-------------------------------------------------------------------------------
    d             = self.Dimensions(2);
    pNorm         = self.Basis.PNorm;
    pNorm_fun     = self.get_hyperbolic_truncation(pNorm);
    mu            = self.Level;
    multi_indices = self.Basis.MultiIndices;
    M             = max(multi_indices,[],"all");

    if d == 2

        x_coord = multi_indices(:,1);
        y_coord = multi_indices(:,2);
        figure
        scatter(x_coord,y_coord,'black','filled')
        grid on
        xlim([0 M+2])
        ylim([0 M+2])
        pbaspect([1 1 1])
        hold on
        x = linspace(1,M+2);
        y = linspace(1,M+2);
        [X,Y] = meshgrid(x,y);
        Z = [X(:) Y(:)];
        temp = X(:);
        for i = 1:length(Z)
            temp(i) = pNorm_fun(Z(i,:));
        end
        Z = reshape(temp,size(X));
        contour(X,Y,Z,[mu mu],'black','ShowText','on')

    elseif d == 3

        x_coord = multi_indices(:,1);
        y_coord = multi_indices(:,2);
        z_coord = multi_indices(:,3);
        figure
        scatter3(x_coord,y_coord,z_coord,'black','filled')
        grid on
        xlim([0 M+2])
        ylim([0 M+2])
        zlim([0 M+2])
        pbaspect([1 1 1])
        hold on
        x = linspace(1,M+2,20);
        y = linspace(1,M+2,20);
        [X,Y] = meshgrid(x,y);
        Z = [X(:) Y(:)];
        temp = X(:);
        for i = 1:length(Z)
            temp(i) = pNorm_fun(Z(i,:));
        end
        Z = (mu+1)-reshape(temp,size(X));
        
        mesh(X,Y,Z,'EdgeColor','black')

    else
        error("Plotting the set of multi.indices works only for D = 2 or D = 3.")
    end


    end

end


methods (Static)

    function fun = get_hyperbolic_truncation(p_norm)
    %-------------------------------------------------------------------------------
    % Name:           get_hyperbolic_truncation
    % Purpose:        Return a function for the hyperbolic truncation
    %                 scheme
    % Last Update:    17.06.2024
    %-------------------------------------------------------------------------------
    fun = @(x) norm(x-1,p_norm);
    end


    function g = get_number_of_indices(mu,d)
    %-------------------------------------------------------------------------------
    % Name:           get_number_of_indices
    % Purpose:        This function will compute the number of
    %                 multi-indices given n (number of points )
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    g = (1+mu)/d * nchoosek(d+mu,d-1);
    g = [g,d];
    end

end


end

