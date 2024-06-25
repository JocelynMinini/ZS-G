function ZS_G_install
clc
clear all
CORE = fileparts(which('ZS_G_install'));
ROOT = CORE(1:end-5);

try
    fprintf('Installing ZS+G module, please wait...\n');
    pause(1)

    % Add the path of ROOT
    addpath(genpath(ROOT),'-end');
    addpath(CORE,'-end');
    rmpath(genpath(fullfile(ROOT,'Interfaces')))
   
    % Search for the software dependencies
    Depedencies = ZS_Depedencies;
    
    % UQLab is not necessary for building a grid but is mandatory for the mapping,
    url = "https://www.uqlab.com/";
    if Depedencies.UQLAB.N == 0
        fprintf('\n')
        fprintf('Warning : \n\n')
        fprintf('  UQLab is not installed on your system. Please note: Although UQLab is not required to run ZS+G, some features will be unavailable.\n');
        fprintf(1,'%s <a href="matlab: web(''%s'') ">%s</a>','  Please go to :',url,'uqlab.com')
        fprintf(' to get and install UQLab (installation in ''\\Program Files''-folder is recommanded).\n')
    end

    % But SGMK is
    url = "https://sites.google.com/view/sparse-grids-kit";
    if Depedencies.SGMK.N == 0
        fprintf('\n')
        fprintf('Error : \n\n')
        fprintf('  SGMK is not installed on your system. ZS+G cannot run without SGMK.\n');
        fprintf(1,'%s <a href="matlab: web(''%s'') ">%s</a>','  Please go to :',url,'sparse-grids-kit.com')
        fprintf(' to download the zip archive and unzip it in a folder of your choice (installation in ''\\Program Files''-folder is recommanded).\n')
        error("ZS+G installation failed because SGMK is not installed on your machine.")
    end

    % Now write a file with the locations
    Depedencies.write_software_file

    % Now check if the dependencies belong already to the MATLAB path
    fprintf('\n')
    fprintf('Checking MATLAB path, please wait...\n\n');
    pause(1)
    Depedencies.install_softwares
    pause(1)

    % And save the pasth
    status = savepath;

    if status ~= 0
        error(['Warning: the ZS+G installer could not save the MATLAB path.\n' ...
            'Please make sure that the MATLAB startup folder is set to a writable location in the MATLAB preferences:\n'...
            'Preferences->General->Initial Working Folder\n'
            ]);
    end

    fprintf('\nZS+R installation complete! \n\n');

    ZS_Progress('Launching ZS+G: ','Forward');
    for i=1:100
        ZS_Progress(i,'Forward');
        pause(0.02);
    end
    ZS_Progress('\n\n','Forward');
    pause(1)
    
    fprintf('----------------------------------------------------------------------------------\n\n\n');

    ZS_G;
    
catch me
    Message = "The installation was not successful! The following error message(s) was/were returned : \n";
    Message = strcat(Message," - ",me.message,'\n');
    error('foo:bar',Message)
end
end