classdef ZS_Validation < dynamicprops
%-------------------------------------------------------------------------------
% Name:           ZS_Validation
% Purpose:        This class checks if user argument are OK
% Last Update:    06.03.2024
%-------------------------------------------------------------------------------
    
properties
    Name
    Grid
    Basis
    Mapping
    Summary = []
end

methods

    function self = ZS_Validation(opts)
    %-------------------------------------------------------------------------------
    % Name:           ZS_Validation
    % Purpose:        Constructor
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    families = {'Name','Grid','Basis','Mapping'};

    for i = 1:length(families)
        toEvaluate = ['self.check_',families{i},'(opts)'];
        try
            self = eval(toEvaluate);
        catch ME
            self.(families{i}).check = false;
            self.(families{i}).error = ME.message;
            self.Summary(end+1)      = 0;
        end
    end

    end

    function self = check_Name(self,opts)
    %-------------------------------------------------------------------------------
    % Name:           check_Name
    % Purpose:        Check the field 'name'
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    if ~isfield(opts,'Name')
        self.Name.existFlag = false;
        self.Name.check     = true;
        self.Summary(end+1) = 1;
        return
    else
        self.Name.existFlag = true;
    end

    if ~ischar(opts.Name)
        self.Name.check = false;
        self.Name.error = self.is_char_message('Name');
        self.Summary(end+1) = 0;
        return
    end

    % All tests have been passed
    self.Name.check = true;
    self.Summary(end+1) = 1;
    self.Name.opts = opts.Name;
    end

    function self = check_Grid(self,opts)
    %-------------------------------------------------------------------------------
    % Name:           check_Grid
    % Purpose:        Check the field 'Grid'
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    if ~isfield(opts,'Grid')
        self.Grid.check     = false;
        self.Grid.error     = "Field 'Grid' is mandatory.";
        self.Summary(end+1) = 0;
        return
    end

    if ~isfield(opts.Grid,'Class')
        self.Grid.check     = false;
        self.Grid.error     = "Field 'Grid.Class' is mandatory.";
        self.Summary(end+1) = 0;
        return
    end

    if ~isfield(opts.Grid,'D')
        self.Grid.check     = false;
        self.Grid.error     = "Field 'Grid.D' is mandatory.";
        self.Summary(end+1) = 0;
        return
    end

    if ~isfield(opts.Grid,'Level')
        self.Grid.check     = false;
        self.Grid.error     = "Field 'Grid.Level' is mandatory.";
        self.Summary(end+1) = 0;
        return
    end


    % Check arguments for Grid.Class
    [success,ErrMsg] = self.check_char(opts.Grid.Class, "Field 'Grid.Class' must be a character array.");
    if ~success
        self.Grid.check     = false;
        self.Grid.error     = ErrMsg;
        self.Summary(end+1) = 0;
        return
    end

    set = {'FullTensor','Sparse'};
    [success,ErrMsg] = self.check_belongs(opts.Grid.Class, set);
    if ~success
        self.Grid.check     = false;
        self.Grid.error     = strcat("Field 'Grid.Class' : ",ErrMsg);
        self.Summary(end+1) = 0;
        return
    end

    % Check arguments for Grid.D
    [success,ErrMsg] = self.check_array(opts.Grid.D,{[1 1]},"Field 'Grid.D' must be an numerical array with size [1 1]");
    if ~success
        self.Grid.check     = false;
        self.Grid.error     = ErrMsg;
        self.Summary(end+1) = 0;
        return
    end

    % Check arguments for Grid.Level
    [success,ErrMsg] = self.check_array(opts.Grid.Level,{[1 1]},"Field 'Grid.Level' must be an numerical array with size [1 1]");
    if ~success
        self.Grid.check     = false;
        self.Grid.error     = ErrMsg;
        self.Summary(end+1) = 0;
        return
    end

    % All tests have been passed
    self.Grid.check = true;
    self.Summary(end+1) = 1;
    self.Grid.opts = opts.Grid;
    end

    function self = check_Basis(self,opts)
    %-------------------------------------------------------------------------------
    % Name:           check_Basis
    % Purpose:        Check the field 'basis'
    % Last Update:    06.03.2024
    %-------------------------------------------------------------------------------
    d     = self.Grid.opts.D;
    mu    = self.Grid.opts.Level;
    class = self.Grid.opts.Class;

    % default arg for Basis in general
    if ~isfield(opts,'Basis')
        opts.Basis = {};
    end

    % default arg for family
    if ~isfield(opts.Basis,'Family')
        C    = cell(1, d);
        C(:) = {'chebyshev_2'};
        opts.Basis.Family = C;
    end

    % default arg for growing function
    if ~isfield(opts.Basis,'Growth')
        if strcmp(class,'FullTensor')
            C    = cell(1, d);
            C(:) = {'n'};
        elseif strcmp(class,'Sparse')
            C    = cell(1, d);
            C(:) = {'2^n+1'};
        end
        opts.Basis.Growth = C;
    end

    % default arg for boundaries
    if ~isfield(opts.Basis,'Bounds')
        C    = cell(1, d);
        C(:) = {true};
        opts.Basis.Bounds = C;
    end

    % default arg for the P-Norm
    if ~isfield(opts.Basis,'PNorm')
        opts.Basis.PNorm = 1;
    end

    % default map the arg in every dimension if length = 1 :
    % for Family
    if ischar(opts.Basis.Family)
        expr = opts.Basis.Family;
        C    = cell(1, d);
        C(:) = {expr};
        opts.Basis.Family = C;
    end

    % for growth
    if ischar(opts.Basis.Growth)
        expr = opts.Basis.Growth;
        C    = cell(1, d);
        C(:) = {expr};
        opts.Basis.Growth = C;
    end

    % for bounds
    if islogical(opts.Basis.Bounds) && all(size(opts.Basis.Bounds) == [1 1])
        expr = opts.Basis.Bounds;
        C    = cell(1, d);
        C(:) = {expr};
        opts.Basis.Bounds = C;
    end

    % check data for familiy : type and size
    [success,ErrMsg] = self.check_cell(opts.Basis.Family, {'char'}, {{1,d}}, "Field 'Basis.Family' must be given as a (1 x D) cell array containing characters");
    if ~success
        self.Basis.check     = false;
        self.Basis.error     = ErrMsg;
        self.Summary(end+1) = 0;
        return
    end

    % check data for familiy : familiy names
    set = ZS_Points.get_family;
    for i = 1:d
        [success,ErrMsg] = self.check_belongs(opts.Basis.Family{i},set);
        if ~success
            self.Basis.check     = false;
            self.Basis.error     = ErrMsg;
            self.Summary(end+1) = 0;
            return
        end
    end

    % check data for growth : type and size
    [success,ErrMsg] = self.check_cell(opts.Basis.Growth, {'char'}, {{1,d}}, "Field 'Basis.Growth' must be given as a (1 x D) cell array containing characters");
    if ~success
        self.Basis.check     = false;
        self.Basis.error     = ErrMsg;
        self.Summary(end+1) = 0;
        return
    end

    % check data for bounds : type and size
    [success,ErrMsg] = self.check_cell(opts.Basis.Bounds, {'logical'}, {{1,d}}, "Field 'Basis.Bounds' must be given as a (1 x D) cell array containing logical values");
    if ~success
        self.Basis.check     = false;
        self.Basis.error     = ErrMsg;
        self.Summary(end+1) = 0;
        return
    end

    % check data for PNorm : type and size
    [success,ErrMsg] = self.check_array(opts.Basis.PNorm, {[1 1]}, "Field 'Basis.PNorm' must be an numerical array with size [1 1]");
    if ~success
        self.Basis.check     = false;
        self.Basis.error     = ErrMsg;
        self.Summary(end+1) = 0;
        return
    end

    self.Basis.check = true;
    self.Summary(end+1) = 1;
    self.Basis.opts = opts.Basis;
    end


    function self = check_Mapping(self,opts)
    %-------------------------------------------------------------------------------
    % Name:           check_mapping
    % Purpose:        Check the field 'mapping'
    % Last Update:    170.04.2024
    %-------------------------------------------------------------------------------
    if ~isfield(opts,'Mapping')
        self.Mapping.existFlag = false;
        self.Mapping.check     = true;
        self.Summary(end+1)    = 1;
        return
    else
        self.Mapping.existFlag = true;
    end

    % Check for Mapping.RandomVector
    if ~isfield(opts.Mapping,'RandomVector')
        self.Mapping.check  = false;
        self.Mapping.error  = "Field 'Mapping.RandomVector' is mandatory.";
        self.Summary(end+1) = 0;
        return
    end

    if ~isa(opts.Mapping.RandomVector,'uq_input')
        self.Mapping.check  = false;
        self.Mapping.error  = "Field 'Mapping.RandomVector' must be a 'uq_input' object.";
        self.Summary(end+1) = 0;
        return
    end

    if size(opts.Mapping.RandomVector.Marginals,2) ~= self.Grid.opts.D
        self.Mapping.check  = false;
        self.Mapping.error  = "The dimension of the random vector must match with the dimension of the grid.";
        self.Summary(end+1) = 0;
        return
    end

    % Check for Mapping.Type
    if ~isfield(opts.Mapping,'Type')
        opts.Mapping.Type = 'Rectangular'; % Default value
    end

    if ~ischar(opts.Mapping.Type)
        self.Mapping.check  = false;
        self.Mapping.error  = "Field 'Mapping.Type' must be a character array.";
        self.Summary(end+1) = 0;
        return
    end

    set = {'Rectangular','Isoprobabilistic'};
    [success,ErrMsg] = self.check_belongs(opts.Mapping.Type,set);
    if ~success
        self.Mapping.check  = false;
        self.Mapping.error  = ErrMsg;
        self.Summary(end+1) = 0;
        return
    end

    % for an isoprobabilistic mapping, all basis vectors must be 'linspace'
    test_1 = all(cellfun(@(x) strcmp(x,'linspace'),self.Basis.opts.Family));

    if strcmp(opts.Mapping.Type,'Isoprobabilistic')
        if ~test_1
            self.Mapping.check  = false;
            self.Mapping.error  = "When using isoprobabilistic mapping, all basis vectors must be 'linspace'.";
            self.Summary(end+1) = 0;
            return
        end
    end



    % Check for Mapping.CI
    if ~isfield(opts.Mapping,'CI')
        opts.Mapping.CI = 0.01; % Default value
    end

    [success,ErrMsg] = self.check_array(opts.Mapping.CI, {[1 1]}, "Field 'Mapping.CI' must be an numerical array with size [1 1]");
    if ~success
        self.Mapping.check  = false;
        self.Mapping.error  = ErrMsg;
        self.Summary(end+1) = 0;
        return
    end

    if opts.Mapping.CI >= 1 || opts.Mapping.CI <= 0
        self.Mapping.check  = false;
        self.Mapping.error  = "Field 'Mapping.CI' must belong to the interval ]0,1[";
        self.Summary(end+1) = 0;
        return
    end


    % All tests have been passed
    self.Mapping.check = true;
    self.Summary(end+1) = 1;
    self.Mapping.opts = opts.Mapping;
    end

    

end


methods (Static)


    function [isValid, ErrMsg] = check_cell(inputVar, allowedTypes, allowedSizes, myErrMsg)
    %-------------------------------------------------------------------------------
    % Name:           check_cell
    % Purpose:        Validates a cell array's size and type against specified criteria. 
    %                 It checks if the cell array matches any allowed sizes, contains only 
    %                 allowed types, and returns true if successful, or false with an error 
    %                 message if not.
    % Last Update:    22.03.2024
    %-------------------------------------------------------------------------------
    % Initialize the output
    isValid = false;
    ErrMsg = '';

    % Check if the input is a cell array
    if ~iscell(inputVar)
        ErrMsg = myErrMsg;
        return;
    end
    
    % Initialize size match flag
    sizeMatch = false;

    % Get current size of the input
    currentSize = size(inputVar);

    % Check each allowed size
    for i = 1:length(allowedSizes)
        allowedSize = allowedSizes{i};
        if length(allowedSize) ~= length(currentSize)
            continue; % Skip if the number of dimensions doesn't match
        end

        match = true;
        for j = 1:length(allowedSize)
            if isnumeric(allowedSize{j}) && allowedSize{j} ~= currentSize(j)
                match = false; % Dimension doesn't match
                break;
            elseif ischar(allowedSize{j}) && ~strcmp(allowedSize{j}, ':')
                match = false; % Invalid specification
                break;
            end
        end

        if match
            sizeMatch = true;
            break; % Size matches, no need to check further
        end
    end

    if ~sizeMatch
        ErrMsg = myErrMsg;
        return;
    end

    % Check that all elements match the allowed types
    for i = 1:length(inputVar)
        if ~any(strcmp(class(inputVar{i}), allowedTypes))
            ErrMsg = myErrMsg;
            return;
        end
    end

    % If all tests are passed
    isValid = true;
    end

    function [isValid, ErrMsg] = check_array(inputVar, allowedSizes, myErrMsg)
    %-------------------------------------------------------------------------------
    % Name:           check_cell
    % Purpose:        checks if an input is a numerical array with specified allowed 
    %                 dimensions, supporting flexible sizes. It returns validity and 
    %                 an error message if criteria are not met.
    % Last Update:    22.03.2024
    %-------------------------------------------------------------------------------
    % Initialize the output
    isValid = false;
    ErrMsg = '';


    % Check if the input is a numerical array
    if ~isnumeric(inputVar)
        ErrMsg = myErrMsg;
        return;
    end
    
    % Initialize size match flag
    sizeMatch = false;

    % Get current size of the input
    currentSize = size(inputVar);

    % Check each allowed size
    for i = 1:length(allowedSizes)
        allowedSize = allowedSizes{i};
        if isequal(allowedSize, ':')
            sizeMatch = true; % Any size matches
            break;
        elseif length(allowedSize) == 2 && any(strcmp(allowedSize, ':'))
            % Handle flexible dimension
            dimIndex = find(strcmp(allowedSize, ':'));
            if dimIndex == 1
                % Flexible row size
                if allowedSize{2} == currentSize(2)
                    sizeMatch = true;
                    break;
                end
            else
                % Flexible column size
                if allowedSize{1} == currentSize(1)
                    sizeMatch = true;
                    break;
                end
            end
        elseif isequal(allowedSize, currentSize)
            sizeMatch = true; % Exact size matches
            break;
        end
    end

    if ~sizeMatch
        ErrMsg = myErrMsg;
        return;
    end

    % If all tests are passed
    isValid = true;
    end


    function [isValid, ErrMsg] = check_char(inputVar, myErrMsg)
    %-------------------------------------------------------------------------------
    % Name:           check_char
    % Purpose:        Check if 'input' is an character array.
    % Last Update:    22.03.2024
    %-------------------------------------------------------------------------------
    if ~ischar(inputVar)
        isValid = false;
        ErrMsg = myErrMsg;
        return
    end

    isValid = true;
    ErrMsg = '';
    end

    function [isValid, ErrMsg] = check_belongs(inputVar, set)
    %-------------------------------------------------------------------------------
    % Name:           check_belongs
    % Purpose:        Check if 'input' belongs to set
    % Last Update:    22.03.2024
    %-------------------------------------------------------------------------------
    if ~ismember(inputVar,set)
        isValid = false;
        ErrMsg = strjoin(horzcat("Argument must take one of the following value :",strjoin(string(set),', ')));
        return
    end

    isValid = true;
    ErrMsg = '';
    end



end


    

    





end

