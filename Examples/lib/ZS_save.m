function ZS_save(filename,var)
    path = fullfile(ZS_G_rootPath,'Examples','Results');
    save(fullfile(path,filename),"var")
end

