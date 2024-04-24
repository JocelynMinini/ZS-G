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

    function self = set_sparse_grid(self)
    %-------------------------------------------------------------------------------
    % Name:           set_sparse_grid
    % Purpose:        This function will generate the sparse grid
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    mul_i = self.Basis.MultiIndices;
    S     = cell(self.Basis.X_1.M,self.Dimensions(2));

    temp = 'X_';
    for j = 1:self.Dimensions(2)
        S(:,j) = self.Basis.([temp,char(string(j))]).Sj;
    end

    growth = self.Basis.Growth;
    bounds = self.Basis.Bounds;
    
    self.Unit_grid = self.get_sparse_grid(mul_i,S,growth,bounds);
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

    self.Basis.MultiIndices = self.get_multi_indices(d,mu,pNorm);
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

    selection = repmat((1:level+1)',1,d)';

    field = 'X_';
    for i = 1:d
        temp = strcat(field,string(i));
        self.Basis.(temp) = ZS_Points(family{i},selection(i,:),map{i},bounds{i});
    end

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
    d     = self.Dimensions(2);
    pnorm = self.Basis.PNorm;
    mu    = self.Level;
    multi_indices = self.Basis.MultiIndices;
    M = max(multi_indices,[],"all");

    if d == 2

        x_coord = multi_indices(:,1);
        y_coord = multi_indices(:,2);
        figure
        scatter(x_coord,y_coord,'black','filled')
        grid on
        xlim([0 M+1])
        ylim([0 M+1])
        pbaspect([1 1 1])
        hold on
        x = linspace(0,M+1);
        y = linspace(0,M+1);
        [X,Y] = meshgrid(x,y);
        Z = ((X-1).^pnorm + (Y-1).^pnorm).^(1/pnorm);
        Z = real(Z);
        contour(X,Y,Z,[mu+d mu+d],'black','ShowText','on')

    elseif d == 3

        x_coord = multi_indices(:,1);
        y_coord = multi_indices(:,2);
        z_coord = multi_indices(:,3);
        figure
        scatter3(x_coord,y_coord,z_coord,'black','filled')
        grid on
        xlim([0 M+1])
        ylim([0 M+1])
        zlim([0 M+1])
        pbaspect([1 1 1])
        hold on
        x = 0:0.01:M+1;
        y = 0:0.01:M+1;
        [X,Y] = meshgrid(x,y);
        Z = ((d+mu)^pnorm - (X-1).^pnorm - (Y-1).^pnorm).^(1/pnorm);
        index = imag(Z)~=0;
        Z(index) = NaN;
        s = surf(X,Y,Z);
        s.EdgeColor = 'none';

    else
        error("Plotting the set of multi.indices works only for D = 2 or D = 3.")
    end


    end

end


methods (Static)

    function perms = get_jtuples(k, d)
    %-------------------------------------------------------------------------------
    % Copyright :     Copyright (c) 2018-2022, Stefano Marelli and Bruno Sudret (ETH Zurich)
    % Name:           get_jtuples
    % Purpose:        This function generates all the J-tuples of integers
    %                 a(i) that satisfy the following conditions using Knuth's 
    %                 H algorithm (Taken and adapted from uqlab.com). 
    % Last Update:    14.03.2024
    %-------------------------------------------------------------------------------
 
    % trivial cases: J = 0 and J = 1
    if d == 0
        perms = 0 ;
    elseif d == 1
        perms = k ;
    else
        % main loop
        % Preallocate a horizontal vector. The comments in this section reflect
        % those in the decription of the Knuth H algorithm
        perms = zeros(1, d) ;
        
        %  "Initialize"
        Y = ones(1, d+1) ;
        Y(1) = k-d+1 ;
        Y(d+1) = -1 ;
        
        i = 0 ;
        while 1
            % "Visit"
            i = i + 1 ;
            perms(i,:) = Y(1:d) ;
            if Y(2) < Y(1)-1
                % "Tweak" Y(1) and Y(2)
                Y(1) = Y(1) - 1 ;
                Y(2) = Y(2) + 1 ;
            else
                % "Find" j
                j = 3 ;
                s = Y(1) + Y(2) - 1 ;
                while Y(j) >= Y(1) - 1
                    s = s + Y(j) ;
                    j = j + 1 ;
                end
                % "Increase" Y(j)
                if j > d
                    break
                else
                    z = Y(j) + 1 ;
                    Y(j) = z ;
                    j = j-1 ;
                end
                % "Tweak" Z(1) ... Z(j)
                while j > 1
                    Y(j) = z;
                    s = s - z ;
                    j = j - 1 ;
                end
                Y(1) = s ;
            end
        end
        
    end
    
    % Sort the return values
    perms = sortrows(perms);
    perms = sort(perms,2);
    end

    function myperms = get_permutations(myset)
    %-------------------------------------------------------------------------------
    % Copyright :     Copyright (c) 2018-2022, Stefano Marelli and Bruno Sudret (ETH Zurich)
    % Name:           get_permutations
    % Purpose:        This function calculate all the unique permutations of a 
    %                 sparse vector V. Knuth algorithm L,
    %                 (Taken and adapted from uqlab.com). 
    % Last Update:    14.03.2024
    %-------------------------------------------------------------------------------    
    % Using chunk allocation initializations to speed up calculations
    
    % The set is cast as integer 8 (should contain small values) to improve
    % indexin speed
    myset = int8(myset);
    % corresponding to int8
    NTYPE = 1; 
    
    max_size_in_memory = 8192; % max size in MB of the permutations matrix
    
    
    % preallocating variables to specify their type (can significantly improve speed)
    j = zeros(1,1,'int32') ;
    l = zeros(1,1,'int32') ;
    k = zeros(1,1,'int32') ;
    M = zeros(1,1,'int32') ;
    N = zeros(1,1,'int32') ;
    i = zeros(1,1,'int32') ; 
    
    % retrieve important info (e.g. dimensionality)
    M = length(myset) ;
    N = length(myset(myset>0));
    
    % number of rows in case of all different non-zero elements in myset
    nrows = prod(double(M-N+1:M)); 
    
    % Calculate the number of elements to properly pre allocate the output
    % matrix
    un = myset(myset>0);
    totn = 0;
    curn = numel(un);
    mult = zeros(curn, 1);
    unvalue = mult;
    ii = 1;
    while totn < N
        curel = min(un);
        un = un(un>curel);
        tmpcurn = numel(un);
        mult(ii) = curn - tmpcurn;
        unvalue(ii) = curel;
        totn = totn + mult(ii);
        curn = tmpcurn;
        ii = ii + 1;
    end
    
    mult = mult(1:ii-1);
    unvalue = unvalue(1:ii-1);
    % get uniques, multiplicity and reorder
    multcumul = cumsum(mult);
    tmp_set = zeros(1,M);
    idx = M - multcumul(end) + 1;
    multcumul = multcumul + idx - 1;
    
    for jj = 1:ii-1
        tmp_set(idx:multcumul(jj)) = unvalue(jj);
        idx = multcumul(jj) + 1;
    end
    
    % final number of rows, taking multiplicity into consideration
    nrows = nrows / prod(factorial(mult));
    
    % check for total memory
    mfingerprint = nrows*M*NTYPE/2^20; % mem fingerprint in MB
    if  mfingerprint > max_size_in_memory
        error('number of permutations too high: would require %d MB, while the specified max is %d MB\n', mfingerprint, max_size_in_memory);
    end
    
    % allocate the necessary memory
    myperms = zeros(nrows,M, 'int8');
    
    % works with row vectors only
    tmp_set = reshape(tmp_set, 1, M);
    
    
    i = 0;
    while 1
        %   L1. Visit
        i=i+1 ;
        myperms(i,:) = tmp_set ;
        
        
        %   L2. Find j
        j = M - 1 ;
        while j && tmp_set(j) >= tmp_set(j+1)
            j = j - 1 ;
        end
        
        if ~j
            break
        end
        
        %   L3. Increase aj
        l = M ;
        while tmp_set(j) >= tmp_set(l)
            l = l-1 ;
        end
        
        aux = tmp_set(j) ;
        tmp_set(j) = tmp_set(l) ;
        tmp_set(l) = aux ;
        %   L4. Reverse aj+1...aM
        k = j+1 ;
        l = M ;
        while k<l
            if ~(tmp_set(k) || tmp_set(l))% do not exchange zero entries
                k=k+1 ; l=l-1 ;
                continue;
            end
            aux = tmp_set(k) ;
            tmp_set(k) = tmp_set(l) ;
            tmp_set(l) = aux ;
            k=k+1 ; l=l-1 ;
        end
    end
    
    myperms = double(myperms);
    end

    function  multi_indices = get_multi_indices(d,mu,pNorm)
    %-------------------------------------------------------------------------------
    % Name:           get_multi_indices
    % Purpose:        This function will creates a matrix containing the
    %                 set of multi-indices
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    count = 0;
    
    g = ZS_SparseGrid.get_number_of_indices(mu,d);
    multi_indices = zeros(round(g));
    
    i = 0;
    while  i <= mu
    mother_tuple = ZS_SparseGrid.get_jtuples(i+d,d);
    
    alpha_norm = vecnorm(mother_tuple'-1,pNorm)';
    
    truncation = alpha_norm <= mu+d;

    mother_tuple = mother_tuple(truncation,:);

    size_mother = size(mother_tuple,1);
    for j = 1:size_mother
        kid_tuple = ZS_SparseGrid.get_permutations(mother_tuple(j,:));
    
        size_kid = size(kid_tuple,1);
        index = (1 : size_kid) + count;
    
        multi_indices(index,:) = kid_tuple;
    
        count = count + size_kid;
    end
    
    i = i+1;
    
    end

    multi_indices = multi_indices(any(multi_indices ~= 0,2),:);
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
%{
    function N = get_N_minus(mu,d)
    %-------------------------------------------------------------------------------
    % Name:           get_N_minus
    % Purpose:        This function gives the size of the sparse grid
    %                 with growth 2^n-1
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    N = zeros(1,double(mu+1));
    count = 1;

    for k = 0:mu
        n = d-1+k;
        m = d-1;
        binomial = nchoosek(n,m);
        N(count) = double(2^k*binomial);
        count = count+1;
    end

    N = sum(N);
    end

    function N = get_N_plus(mu,d)
    %-------------------------------------------------------------------------------
    % Name:           get_N_plus
    % Purpose:        This function gives the size of the sparse grid
    %                 with growth 2^n+1
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    N = zeros(1,double(d+1));
    count = 1;

    for j = 0:d
        N(count) = nchoosek(d,j)*2^(d-j)*ZS_SparseGrid.get_N_minus(mu,j);
        count = count+1;
    end

    N = sum(N);
    end

    function N = get_N_plus_dupl(multi_indices)
    %-------------------------------------------------------------------------------
    % Name:           get_N_plus_dupl
    % Purpose:        This function gives the size of the sparse grid
    %                 with growth 2^n+1 considering duplicates
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    multi_indices = 2.^multi_indices+1;
    p = prod(multi_indices,2);
    N = sum(p);
    end

    function N = get_N_minus_dupl(multi_indices)
    %-------------------------------------------------------------------------------
    % Name:           get_N_plus_dupl
    % Purpose:        This function gives the size of the sparse grid
    %                 with growth 2^n-1 considering duplicates
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    multi_indices = 2.^multi_indices-1;
    p = prod(multi_indices,2);
    N = sum(p);
    end
%}


    function N = get_allocation(multi_indices,growth,bounds)
    %-------------------------------------------------------------------------------
    % Name:           get_allocation
    % Purpose:        This function allocates to grid with duplicates
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    d = size(growth,2);

    for i = 1:d
        temp = growth{i};
        if ~bounds{i}
            temp = strcat(temp,'-2');
        end
        temp = char(temp);
        multi_indices(:,i) = ZS_Points.convert_pts(multi_indices(:,i),temp);
    end

    if any(multi_indices<1,'all')
        error("One of the given growing function(s) produce negative indices. Please choose a positive monotonic function.")
    end

    p = prod(multi_indices,2);
    N = sum(p);
    end

    function grid = get_sparse_grid(multi_indices,Sj,growth,bounds)
    %-------------------------------------------------------------------------------
    % Name:           get_sparse_grid
    % Purpose:        This function will compute the number of
    %                 multi-indices given n (number of points )
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    g  = size(multi_indices,1);
    d  = size(multi_indices,2);

    tempCell       = cell(1, d);
    cartesian_cell = cell(g,d);
   

    % Make the table for cartesian products
    for i = 1:g
        indices = multi_indices(i,:);
        
        for j = 1:length(indices)
            tempCell{j} = Sj{indices(j),j};
        end
        
        cartesian_cell(i,:) = tempCell;
    end

    % Allocate and
    N = ZS_SparseGrid.get_allocation(multi_indices,growth,bounds);
    % make the grid
    grid = zeros(N,d);
    count = 0;
    for i = 1:g
        temp = cartesian_cell(i,:);
        cartesian = combvec(temp{:})';
        size_cartesian = size(cartesian,1);
        index = (1 : size_cartesian) + count;
        grid(index,:) = cartesian;
        count = count + size_cartesian;
    end
    if count ~= length(grid)
        warning("Something went wrong with the counting of the grid elements !!")
    end
    grid = unique(grid,'rows');
    end

    

end


end

