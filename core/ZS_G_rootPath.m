function root_path = ZS_G_rootPath
root_path = fileparts(which('ZS_G'));
root_path = root_path(1:end-5);
end