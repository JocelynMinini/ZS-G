classdef ZS_Software    

    properties
    NAME        string % Name of the software
    SEARCH_KEY  string % Name of a file to search in the machine
    N           double % Number of occurences of the software in the machine 
    LOCATIONS   string % Software locations
    end
    
    methods

        function self = ZS_Software(software_name,name_to_search)
        %-------------------------------------------------------------------------------
        % Name:           Instanciate
        % Purpose:        Class constructor
        % Last Update:    20.10.2023
        %-------------------------------------------------------------------------------
        % First set the names
        self.NAME       = software_name;
        self.SEARCH_KEY = name_to_search;
        
        % Then look across the hard disks for it
        fprintf(['\n - Searching for ' ,software_name,'...']);
        locations = self.get_location(name_to_search);
        self = self.set_path(locations);
        pause(0.2)
        if self.N == 0
            fprintf('[Failed]\n');
            fprintf(['   ','No ',software_name,' version found. Please see the instructions here below.\n'])
            pause(0.2)
        else
            fprintf('[OK]\n');
            pause(0.2)
            fprintf(['   ',num2str(self.N),' ',software_name,' version(s) found at :\n'])
            for i = 1:self.N
                pause(0.2)
                fprintf('   - ')
                fprintf(strrep(self.LOCATIONS(i),'\','\\'));
                fprintf('\n')
            end
        end

        pause(1)
        end
        
        function self = set_path(self,path)
        %-------------------------------------------------------------------------------
        % Name:           get_paths
        % Purpose:        Extract the path to uqlab.m
        % Last Update:    20.10.2023
        %-------------------------------------------------------------------------------
        % Sometimes -mat files can appear in temporary folder -> Delete them
        index = ~contains(path,'Temp');
        path = path(index);
        % Sometimes -mat files can appear in Recycle.Bin folder -> Delete them
        index = ~contains(path,'$Recycle');
        path = path(index);
        % Sometimes -mat files can appear in Recycle.Bin folder -> Delete them
        index = contains(path,'\');
        path = path(index);

        % Now we know how much 'software' there are
        self.N = length(path);
        self.LOCATIONS = arrayfun(@(x) erase(x,strcat('\',self.SEARCH_KEY)),path);
        end

    end

    methods(Static = true)
        
        function path = get_location(name_to_search)
        %-------------------------------------------------------------------------------
        % Name:           search
        % Purpose:        Search for a software in all hard disks on the
        %                 machine
        % Last Update:    13.06.2024
        %-------------------------------------------------------------------------------
        drives = ZS_Software.get_drives;
        path = {};
        for i = 1:length(drives)
            cd(drives{i})

            [status,cmd_output] = system(['dir ',name_to_search,' /b/s']);
            cmd_output = strsplit(cmd_output,'\n');
            boole = cellfun(@isempty, cmd_output);
            cmd_output = cmd_output(~boole);
            path = [path;cmd_output'];
        end
        cd([ZS_G_rootPath,'\core'])
        path = string(path);
        end

        function [drives,isLocal] = get_drives
        %-------------------------------------------------------------------------------
        % Name:           get_drives
        % Purpose:        Give the name and the type of the drive in the
        %                 current machine
        % Last Update:    13.06.2024
        %-------------------------------------------------------------------------------
        if ispc
            [drives,isLocal] = ZS_Software.get_drives_Windows;
            drives = drives(isLocal);
        else
            error('ZS+G installation is currently only supported on Windows.');
        end

        end

        function [drives,isLocal] = get_drives_Windows
        drives  = {};
        isLocal = [];
        % Use wmic to get the drive letter and type
        [~, result] = system('wmic logicaldisk get caption,drivetype');
        
        % Then check
        lines    = strsplit(result, '\n');
        index    = cellfun(@(x) ~isempty(x),lines);
        index(1) = false;

        nDrives = sum(index);
        lines = lines(index);

        for i = 1:nDrives
            line = strtrim(lines{i});
            parts = strsplit(line);
            if length(parts) < 2
                continue;
            end

            driveLetter   = parts{1};
            drives{end+1} = [driveLetter,'\'];


            driveType = str2double(parts{2});
            % Which type ?
            switch driveType
                case 3
                    isLocal(end+1) = true;
                otherwise
                    isLocal(end+1) = false;
            end

        end
        isLocal = logical(isLocal);
        end

    end



end

