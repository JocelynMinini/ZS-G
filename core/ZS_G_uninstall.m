function ZS_G_uninstall
clc
CORE = fileparts(which('ZS_G_install'));
ROOT = CORE(1:end-5);


try
    fprintf('Uninstalling ZS+G module, please wait...\n\n');
    
    pause(1)

    ZS_Progress('Uninstalling ZS+G: ','Backward');
    for i=1:100
        ZS_Progress(i,'Backward');
        pause(0.02);
    end
    ZS_Progress('\n\n','Backward');
    pause(1)

    % Delete dependencies
    delete(fullfile(ROOT,'DEPENDENCIES'))

    % remove the path of ZSROOT

    rmpath(genpath(fullfile(ROOT)))
    savepath

    clc
   
    fprintf('ZS+G was successfully uninstalled.\n');

catch me
    fprintf('The uninstallation was not successful!\nThe installer returned the following message: %s\n\n', me.message);
end
end