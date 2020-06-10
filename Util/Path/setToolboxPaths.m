function setToolboxPaths(toolbox_path)
% function setToolboxPaths(toolbox_path)
%
% Add all the folders of the toolbox to the search
% path.
%
% Inputs:
%
% toolbox_path - the root path of the IMOS toolbox
%
% Outputs:
%
% Example:
%
% setToolboxPaths('/home/joe/imos-toolbox')
% assert(exist('detectType.m','file'))
%
% author: hugo.oliveira@utas.edu.au
%

% Copyright (C) 2020, Australian Ocean Data Network (AODN) and Integrated
% Marine Observing System (IMOS).
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation version 3 of the License.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.
% If not, see <https://www.gnu.org/licenses/gpl-3.0.en.html>.
%

% This will add all required paths for the toolbox to run
folders = {
'AutomaticQC', ...
'Seawater/TEOS10', ...
'Seawater/TEOS10/library', ...
'Seawater/EOS80', ...
'Util', ...
'Util/CellUtils', ...
'Util/StructUtils', ...
'Util/Path', ...
'Util/Schema', ...
'Util/units', ...
'IMOS', ...
'NetCDF', ...
'Parser', ...
'Parser/GenericParser', ...
'Parser/GenericParser/InstrumentRules', ...
'Parser/GenericParser/InstrumentParsers', ...
'test', ...
'test/Parser', ...
'test/Preprocessing', ...
'test/Util', ...
'test/Util/Schema', ...
'test/Util/CellUtils', ...
'DDB', ...
'Preprocessing'};

addpath(toolbox_path)

for k = 1:length(folders)
    addpath(fullfile(toolbox_path,folders{k}));
end

end