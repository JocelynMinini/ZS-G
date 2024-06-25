function ZS_G
ROOT = ZS_G_rootPath;
interface_path = [ROOT,'\Interfaces'];
addpath(genpath(interface_path));

fprintf('This is ZS_G, version 1.0')
fprintf('\n')
fprintf('Copyright 2024, HEIA FR, Fribourg, Switzerland.')
fprintf('\n')
fprintf('Corresponding license available at:')
fprintf('\n')
disp([ROOT,'\LICENSE.'])
fprintf('\n')
disp('For any assistance, bug report or feature request, please fill the contact form online: <a href="https://github.com/JocelynMinini/ZS-G.git">GitHub.ch</a>.')
fprintf('\n')
user_manual_path = [char(39),ROOT,'\Documentation\User manual.pdf',char(39)];
disp(['Check the ZS+G documentation : <a href="matlab:winopen(',user_manual_path,')">ZS+G User manual</a>.'])
fprintf('\n');
end