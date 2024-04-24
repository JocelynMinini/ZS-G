function ZS_G_install
clc
CORE = fileparts(which('ZS_G_install'));
ROOT = CORE(1:end-5);

try
    % Add the path of ZSROOT
    addpath(genpath(ROOT), '-begin');
    rmpath(genpath(fullfile(ROOT,'Interfaces')))

    status = savepath;
    if status
        fprintf(['Warning: the ZS+G installer could not be save the MATLAB path.\n' ...
            'Please make sure that the MATLAB startup folder is set to a writable location in the MATLAB preferences:\n'...
            'Preferences->General->Initial Working Folder\n'
            ]);
    end

    fprintf('Installing ZS+G module, please wait...\n');
    pause(1)
    % Search for software dependencies
    Software = ZS_Softwares;
    Software.UQLAB = Software.UQLAB.Instanciate;
    Software.write_software_file

    if Software.UQLAB.N < 0
        warning('No UQLab version found on this machine. Some features will not work without the installation of UQLab.')
    end

    fprintf('\nZS+R installation complete! \n\n');

    ZS_Progress('Launching ZS+G: ','Forward');
    for i=1:100
        ZS_Progress(i,'Forward');
        pause(0.02);
    end
    ZS_Progress('\n\n','Forward');
    pause(1)
    clc
    ZS_G;
    
catch me
    fprintf('The installation was not successful!\nThe installer returned the following message: %s\n\n', me.message);
end
end