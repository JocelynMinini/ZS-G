classdef ZS_Depedencies 
    properties
    UQLAB = ZS_Software('UQLAB','uqlab.m')
    SGMK  = ZS_Software('SGMK','create_sparse_grid.m')
    end

    methods

        function write_software_file(self)
        %-------------------------------------------------------------------------------
        % Name:           write_software_file
        % Purpose:        Write the file with the software dependencies
        % Last Update:    13.06.2024
        %-------------------------------------------------------------------------------
        ROOT = ZS_G_rootPath;
        f = [ROOT,'\DEPENDENCIES'];
        if isfile(f)
            delete(f)
        end
        
        softwares = properties(self);

        fileID = fopen(f,"w");
        for k = 1:length(softwares)
            fprintf(fileID,'%s',[softwares{k},'|']);
            fprintf(fileID,'%u',self.(softwares{k}).N);
            fprintf(fileID,'\n');
            for i = 1:self.(softwares{k}).N
                line = strcat(string(i),"|",self.(softwares{k}).LOCATIONS(i));
                fprintf(fileID,'%s',line);
                fprintf(fileID,'\n');
            end
        end
        fclose('all');
        end

        function install_softwares(self)
        %-------------------------------------------------------------------------------
        % Name:           install_softwares
        % Purpose:        This will ask the user if he want to install the
        %                 third party softwares
        % Last Update:    13.06.2024
        %-------------------------------------------------------------------------------
        names = properties(self);
    
        for i = 1:length(names)

            fprintf(' - Checking ')
            fprintf(names{i})
            fprintf('...')

            locations = self.(names{i}).LOCATIONS;
            isInPath  = ZS_Depedencies.check_in_path(locations);
    
            isMulitple = length(isInPath)>1;
    
            if self.(names{i}).N ~= 0

                if ~isMulitple && isInPath
                    fprintf('[OK]\n')
                    pause(0.2)
                    fprintf(['   - ',names{i},' already belongs to MATLAB path.\n\n'])
                    pause(1)
                elseif isMulitple && any(isInPath)
                    fprintf('[OK]\n')
                    pause(0.2)
                    fprintf(['   - ',names{i},' already belongs to MATLAB path.\n\n'])
                    pause(1)
                elseif isMulitple && all(isInPath)
                    % nothing to do but unstable because 2 locations -> Warning
                else
                    fprintf('[Found]\n')
                    fprintf(['   - ','aksing the user...'])
                    ZS_Depedencies.installation_dialog(locations)
                end

            else

                fprintf('[Failed]\n')
                fprintf(['   - ',names{i},' was not found on your machine.\n\n'])

            end
    
    
        end
    
    
    
        end

        

    end

    methods(Static)

    function self = read_software_file
    %-------------------------------------------------------------------------------
    % Name:           read_software_file
    % Purpose:        Read the file with the software dependencies
    % Last Update:    13.06.2024
    %-------------------------------------------------------------------------------
    ROOT = ZS_G_rootPath;
    f = fopen([ROOT,'\DEPENDENCIES']);

    while ~feof(f)
        line = fgetl(f);
        head = strsplit(line,'|');

        name = head{1};
        N    = str2double(head(2));

        self.(name).N = N;
        self.(name).LOCATIONS = string.empty;
        for i = 1:N
            line = fgetl(f);
            temp = strsplit(line,'|');
            temp = temp{2};
            self.(name).LOCATIONS(end+1,:) = temp;
        end
    end
    fclose(f);
    end

    function path = get_path(software)
    %-------------------------------------------------------------------------------
    % Name:           get_last_version
    % Purpose:        Return the path of 'software'
    % Last Update:    13.06.2024
    %-------------------------------------------------------------------------------
    this = ZS_Depedencies.read_software_file;
    path = this.(software).LOCATIONS;
    end

    function isInPath = check_in_path(software_path)
    %-------------------------------------------------------------------------------
    % Name:           check_in_path
    % Purpose:        Check if 'software' belongs to the current MATLAB
    %                 path
    % Last Update:    13.06.2024
    %-------------------------------------------------------------------------------
    current_path = path;
    current_path = strsplit(current_path,';')';

    isInPath = logical.empty;
    for i = 1:length(software_path)
        isInPath(end+1) = any(cellfun(@(x) contains(x,software_path(i)),current_path));
    end

    end


    function installation_dialog(strArray)
    %-------------------------------------------------------------------------------
    % Name:           installation_dialog
    % Purpose:        This function open a dialog box for installing the
    %   	          software 
    % Last Update:    13.06.2024
    %-------------------------------------------------------------------------------
    % Input argument verification
    if ~isstring(strArray) || ~isvector(strArray)
        error('The argument must be a string array.');
    end

    % Create the dialog box
    d = dialog('Position', [300, 300, 600, 200], 'Name', 'Installing options');
    movegui(d, 'center'); % Center the dialog box

    % Add explanatory text
    uicontrol('Parent', d, ...
              'Style', 'text', ...
              'Position', [20, 130, 560, 40], ...
              'String', 'Please select which location should be added to the MATLAB path:', ...
              'HorizontalAlignment', 'center', ...
              'FontSize', 10);
    
    % Add dropdown list
    popup = uicontrol('Parent', d, ...
                      'Style', 'popupmenu', ...
                      'Position', [225, 90, 150, 25], ...
                      'String', strArray);

    % Add "Install" button
    uicontrol('Parent', d, ...
              'Position', [175, 20, 100, 30], ...
              'String', 'Install', ...
              'Callback', @installCallback, ...
              'FontSize', 10);

    % Add "Abort" button
    uicontrol('Parent', d, ...
              'Position', [325, 20, 100, 30], ...
              'String', 'Abort', ...
              'Callback', @closeCallback, ...
              'FontSize', 10);

    % Variable to store the status
    aborted = false;

    % Wait for the dialog to close
    uiwait(d);

    if aborted
        error('Installation aborted by the user.');
    end

    function installCallback(~, ~)
    % Get the selected item from the dropdown list
    selectedValue = strArray{popup.Value};
    fprintf('[OK]\n')
    folder = selectedValue;
    index  = strfind(folder,'\');
    folder = folder(1:index(end)-1);
    
    % Now install the software by adding the path
    addpath(genpath(folder),'-end')
    fprintf("   - '" + strrep(folder,'\','\\') + "'" + " added to the MATLAB path.\n");
    uiresume(d); % Resume the UI
    delete(d); % Close the dialog
    end

    function closeCallback(~, ~)
    fprintf('[Aborted]\n')
    fprintf("   - Installation aborted by the user.\n");
    aborted = true;
    uiresume(d); % Resume the UI first to close the dialog
    delete(d); % Close the dialog
    end

    end


    end
    

end

