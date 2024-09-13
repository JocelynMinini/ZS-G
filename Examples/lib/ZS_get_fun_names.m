function list = ZS_get_fun_names
path = ZS_G_rootPath;
path = [path,'\Examples\Functions'];

files = dir(path);
files = {files.name};
list = {};
for i = 1:length(files)
    if contains(files{i},'fun')
        temp = files{i};
        temp = temp(8:end-2);
        list{end+1} = temp;
    end
end
end

