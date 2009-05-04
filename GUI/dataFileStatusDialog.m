function [deployments files] = dataFileStatusDialog( deployments, files )
%DATAFILESTATUSDIALOG Displays a list of deployments, and raw files for
% each, allowing the user to verify/change which raw data files map to which
% deployment.
%
% The importManager attempts to find raw data files/directories for each
% deployment. Sometimes a raw file may be missing, or multiple files may be
% present for a single deployment. 
%
% This dialog displays the list of deployments, and the raw files which have 
% been found for each, and allows the user to modify the list (add/remove 
% deployments, and files for a deployment).
%
% Inputs:
%   deployments - Vector of DeploymentData structs.
%
%   files       - Cell array of cell arrays of strings, each containing the
%                 list of file names corresponding to each deployment.
%
% Outputs:
%   deployments - Same as input, potentially with some deployments removed.
%
%   files       - Same as input, potentially with some entries removed or
%                 modified.
%
% Author: Paul McCarthy <paul.mccarthy@csiro.au>
%

%
% Copyright (c) 2009, eMarine Information Infrastructure (eMII) and Integrated 
% Marine Observing System (IMOS).
% All rights reserved.
% 
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are met:
% 
%     * Redistributions of source code must retain the above copyright notice, 
%       this list of conditions and the following disclaimer.
%     * Redistributions in binary form must reproduce the above copyright 
%       notice, this list of conditions and the following disclaimer in the 
%       documentation and/or other materials provided with the distribution.
%     * Neither the name of the eMII/IMOS nor the names of its contributors 
%       may be used to endorse or promote products derived from this software 
%       without specific prior written permission.
% 
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% POSSIBILITY OF SUCH DAMAGE.
%
  error(nargchk(2,2,nargin));

  if ~isstruct(deployments), error('deployments must be a struct'); end
  if ~iscell  (files),       error('files must be a cell array');   end

  % copy the inputs so we can rollback if the user cancels
  origDeployments = deployments;
  origFiles       = files;
  
  %% Create GUI

  % dialog figure
  f = figure(...
    'Name', 'Confirm data files',...
    'Visible', 'off',...
    'MenuBar', 'none',...
    'Resize', 'off',...
    'WindowStyle', 'Modal'...
  );

  % widgets
  depRemoveButton   = uicontrol('Style', 'pushbutton', 'String', ...
    'Remove deployment');
  fileRemoveButton  = uicontrol('Style', 'pushbutton', 'String', 'Remove file');
  fileAddButton     = uicontrol('Style', 'pushbutton', 'String', 'Add file...');
  cancelButton      = uicontrol('Style', 'pushbutton', 'String', 'Cancel');
  confirmButton     = uicontrol('Style', 'pushbutton', 'String', 'Ok');

  depList           = uicontrol('Style', 'listbox', 'Min', 1, 'Max', 1);
  fileList          = uicontrol('Style', 'listbox', 'Min', 1, 'Max', 3);
  % set list items
  set(depList,  'String', genDepDescriptions(deployments, files), 'Value', 1);
  set(fileList, 'String', files{1},                               'Value', 1);

  % use normalised coordinates
  set(f,                                 'Units', 'normalized');
  set([fileRemoveButton, fileAddButton], 'Units', 'normalized');
  set([cancelButton, confirmButton],     'Units', 'normalized');
  set(depRemoveButton,                   'Units', 'normalized');
  set([depList, fileList],               'Units', 'normalized');

  % position widgets
  set(f,                'Position', [0.3, 0.3,  0.4, 0.4 ]);
  set(cancelButton,     'Position', [0.0, 0.0,  0.5, 0.05]);
  set(confirmButton,    'Position', [0.5, 0.0,  0.5, 0.05]);
  set(fileList,         'Position', [0.0, 0.05, 1.0, 0.40]);
  set(fileRemoveButton, 'Position', [0.0, 0.45, 0.5, 0.05]);
  set(fileAddButton,    'Position', [0.5, 0.45, 0.5, 0.05]);
  set(depList,          'Position', [0.0, 0.50, 1.0, 0.45]);
  set(depRemoveButton,  'Position', [0.0, 0.95, 1.0, 0.05]);

  % widget callbacks
  set(f,                'CloseRequestFcn', @cancelCallback);
  set(depList,          'Callback',        @depListCallback);
  set(depRemoveButton,  'Callback',        @depRemoveCallback);
  set(fileRemoveButton, 'Callback',        @fileRemoveCallback);
  set(fileAddButton,    'Callback',        @fileAddCallback);
  set(cancelButton,     'Callback',        @cancelCallback);
  set(confirmButton,    'Callback',        @confirmCallback);

  % user can hit escape to quit dialog
  set(f,                'KeyPressFcn',     @keyPressCallback);
  set(depRemoveButton,  'KeyPressFcn',     @keyPressCallback);
  set(depList,          'KeyPressFcn',     @keyPressListCallback);
  set(fileRemoveButton, 'KeyPressFcn',     @keyPressCallback);
  set(fileAddButton,    'KeyPressFcn',     @keyPressCallback);
  set(fileList,         'KeyPressFcn',     @keyPressListCallback);
  set(cancelButton,     'KeyPressFcn',     @keyPressCallback);
  set(confirmButton,    'KeyPressFcn',     @keyPressCallback);

  % display the dialog and wait for user input
  set(f, 'Visible', 'on');
  uiwait(f);
  
  %% Callback functions
  
  function keyPressCallback(source,ev)
  %KEYPRESSCALLBACK If the user pushes escape while the dialog has focus,
  % the dialog is closed. This is done by delegating to the cancelCallback
  % function.
  %
    if     strcmp(ev.Key, 'escape'), cancelCallback( source,ev);
    elseif strcmp(ev.Key, 'return'), confirmCallback(source,ev); 
    end
  end

  function keyPressListCallback(source,ev)
  %KEYPRESSLISTCALLBACK If the user pushes delete while one of the deployment 
  % or file lists has focus, the selected entries are deleted. Otherwise
  % this function delegates to the keyPressCallback function.
  % 
    if strcmp(ev.Key, 'delete')
      if     source == depList,  depRemoveCallback( source,ev);
      elseif source == fileList, fileRemoveCallback(source,ev);
      end
    else keyPressCallback(source,ev); 
    end
  end

  function cancelCallback(source,ev)
  %CANCELCALLBACK Discards any changes the user may have made, and
  % closes the dialog.
  %
    %deployments = origDeployments;
    %files       = origFiles;
    deployments = [];
    files       = {};
    delete(f);
  end

  function confirmCallback(source,ev)
  %CONFIRMCALLBACK Closes the dialog.
  %
    delete(f);
  end

  function depListCallback(source,ev)
  %DEPLISTCALLBACK Called when the deployment selection changes. Updates
  % the file list with files from the newly selected deployment.
  %
    dep = get(depList, 'Value');
    set(fileList, 'String', files{dep});
    set(fileList, 'Value',  1);
  end

  function depRemoveCallback(source,ev)
  %DEPREMOVECALLBACK Removes the currently selected deployment from the
  % list.
  %
    dep = get(depList, 'Value');
    
    % if there is only one deployment, don't allow it to be removed
    if length(deployments) == 1, return; end
    
    deployments(dep) = [];
    files(      dep) = [];
   
    % if it is the last deployment in the list being removed, make sure
    % that the selected deployment is within the valid range, otherwise
    % matlab will complain
    if dep == length(deployments)+1, dep = length(deployments); end
    
    % update the deployment and file list and deployment selection
    set(depList, 'Value',  dep);
    set(depList, 'String', genDepDescriptions(deployments, files));
    depListCallback(source,ev);
  end

  function fileRemoveCallback(source,ev)
  %FILEREMOVECALLBACK Called when the user pushes the remove file button.
  % Removes the currently selected files from the deployment.
  %
    dep  = get(depList,  'Value');
    file = get(fileList, 'Value');
    
    files{dep}(file) = [];
    
    set(fileList, 'String', files{dep});
    set(fileList, 'Value', 1);
  end

  function fileAddCallback(source,ev)
  %FILEREMOVECALLBACK Called when the user pushes the add file button.
  % Opens a dialog, allowing the user to select a file to add to the
  % deployment.
  %
  
    [newFile path] = uigetfile('*', 'Select Data File',...
                               readToolboxProperty('dataDir'),...
                               'MultiSelect', 'on');
    
    % user cancelled dialog
    if newFile == 0, return; end
    
    % get selected deployment
    dep = get(depList, 'Value');
    
    % add new file to deployment's file list
    files{dep}{end+1} = [path newFile];
    set(fileList, 'String', files{dep});
  end
end

function descs = genDepDescriptions(deployments, files)
%GENDEPDESCRIPTIONS Creates a cell array of descriptions of the given
% deployments, suitable for use in the deployments list.
%

  % set values for lists
  descs = strcat(...
    {deployments.DeploymentId},...
    ':', {deployments.InstrumentID},...
    '(', {deployments.FileName}, ')'...
  );

  % highlight deployments which have no associated 
  % files or which have more than one associated file
  nofile   = readToolboxProperty('filestatusdialog.nofileformat');
  multiple = readToolboxProperty('filestatusdialog.multiplefileformat');
  
  [nofileStart   nofileEnd]   = genTags(nofile);
  [multipleStart multipleEnd] = genTags(multiple);
  
  for k = 1:length(files)
    
    if     isempty(files{k})
      descs{k} = [nofileStart   descs{k} nofileEnd];
      
    elseif length(files{k}) > 1
      descs{k} = [multipleStart descs{k} multipleEnd];
      
    end
  end
  
  function [startTag endTag] = genTags(formatSpec)
  %GENTAGS Generates HTML tags for the given format specification.
  %
  
  startTag = '';
  endTag   = '';
  
    switch (formatSpec)
      
      case 'normal', 
      case 'bold', 
        startTag = '<html><b>';
        endTag   = '</b></html>';
      case 'italic'
        startTag = '<html><i>';
        endTag   = '</i></html>';
        
      % otherwise assume it's a html colour
      otherwise
        startTag = ['<html><font color=''' formatSpec '''>'];
        endTag   = '</font></html>';
    end
    
  end
end