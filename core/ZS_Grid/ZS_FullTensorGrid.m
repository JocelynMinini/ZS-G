classdef ZS_FullTensorGrid < ZS_SparseGrid
%-------------------------------------------------------------------------------
% Name:           ZS_FullTensorGrid
% Purpose:        This class generates full tensor grids
% Last Update:    06.03.2024
%-------------------------------------------------------------------------------

methods

    function self = ZS_FullTensorGrid(internal)
    %-------------------------------------------------------------------------------
    % Name:           ZS_FullTensorGrid
    % Purpose:        Constructor
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    self.Class        = internal.Validation.Grid.opts.Class;
    self.Dimensions   = [0,internal.Validation.Grid.opts.D];
    self.Level        = internal.Validation.Grid.opts.Level;
    self.Basis.Family = internal.Validation.Basis.opts.Family;
    self.Basis.Growth = internal.Validation.Basis.opts.Growth;
    self.Basis.Bounds = internal.Validation.Basis.opts.Bounds;

    % 1. Create the basis
    self = self.set_basis;
    
    % 2. Perform cartesian product of the basis
    self = self.set_grid;

    % 3 set the size of the grid
    self.Dimensions = size(self.Unit_grid);

    % 5. Check if the grid is nested
    self = self.check_nested;
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
    map    = self.Basis.Growth;
    level  = self.Level;

    selection = repmat(level,1,d);

    field = 'X_';
    for i = 1:d
        temp = strcat(field,string(i));
        self.Basis.(temp) = ZS_Points(family{i},selection(i),map{i},bounds{i});
    end

    end

    function self = set_grid(self)
    %-------------------------------------------------------------------------------
    % Name:           set_grid
    % Purpose:        This function will generate the full tensor grid
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    S = cell(self.Basis.X_1.M,self.Dimensions(2));

    temp = 'X_';
    for j = 1:self.Dimensions(2)
        S(:,j) = self.Basis.([temp,char(string(j))]).Sj;
    end
    
    self.Unit_grid = self.get_full_grid(S);
    end


end


methods(Static)

    function grid = get_full_grid(Sj)
    %-------------------------------------------------------------------------------
    % Name:           get_full_grid
    % Purpose:        This function creates the full grid and return it
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    grid = combvec(Sj{:})';
    grid = unique(grid,'rows');
    end

end

end

