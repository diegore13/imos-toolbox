function scatterMooring1DVarAgainstDepth(sample_data, varName, isQC, saveToFile, exportDir)
%SCATTERMOORING1DVARAGAINSTDEPTH Opens a new window where the selected
% variable collected by all the intruments on the mooring are plotted.
%
varTitle = imosParameters(varName, 'long_name');
varUnit = imosParameters(varName, 'uom');

if any(strcmpi(varName, {'DEPTH', 'PRES', 'PRES_REL'})), return; end

stringQC = 'non QC';
if isQC, stringQC = 'QC'; end

%plot depth information
monitorRec = get(0,'MonitorPosition');
xResolution = monitorRec(:, 3)-monitorRec(:, 1);
iBigMonitor = xResolution == max(xResolution);
if sum(iBigMonitor)==2, iBigMonitor(2) = false; end % in case exactly same monitors
title = [sample_data{1}.deployment_code ' mooring''s instruments ' stringQC '''d good ' varTitle];

%sort instruments by depth
lenSampleData = length(sample_data);
metaDepth = nan(lenSampleData, 1);
xMin = nan(lenSampleData, 1);
xMax = nan(lenSampleData, 1);
for i=1:lenSampleData
    if ~isempty(sample_data{i}.meta.depth)
        metaDepth(i) = sample_data{i}.meta.depth;
    elseif ~isempty(sample_data{i}.instrument_nominal_depth)
        metaDepth(i) = sample_data{i}.instrument_nominal_depth;
    else
        metaDepth(i) = NaN;
    end
    iTime = getVar(sample_data{i}.dimensions, 'TIME');
    xMin = min(sample_data{i}.dimensions{iTime}.data);
    xMax = max(sample_data{i}.dimensions{iTime}.data);
end
[metaDepth, iSort] = sort(metaDepth);
xMin = min(xMin);
xMax = max(xMax);

markerStyle = {'+', 'o', '*', '.', 'x', 's', 'd', '^', 'v', '>', '<', 'p', 'h'};
lenMarkerStyle = length(markerStyle);

instrumentDesc = cell(lenSampleData + 1, 1);
hScatterVar = nan(lenSampleData + 1, 1);

instrumentDesc{1} = 'Make Model (nominal depth - instrument SN)';
hScatterVar(1) = 0;

initiateFigure = true;

for i=1:lenSampleData
    % instrument description
    if ~isempty(strtrim(sample_data{iSort(i)}.instrument))
        instrumentDesc{i + 1} = sample_data{iSort(i)}.instrument;
    elseif ~isempty(sample_data{iSort(i)}.toolbox_input_file)
        [~, instrumentDesc{i + 1}] = fileparts(sample_data{iSort(i)}.toolbox_input_file);
    end
    
    instrumentSN = '';
    if ~isempty(strtrim(sample_data{iSort(i)}.instrument_serial_number))
        instrumentSN = [' - ' sample_data{iSort(i)}.instrument_serial_number];
    end
    
    instrumentDesc{i + 1} = [strrep(instrumentDesc{i + 1}, '_', ' ') ' (' num2str(metaDepth(i)) 'm' instrumentSN ')'];
        
    %look for time and relevant variable
    iTime = getVar(sample_data{iSort(i)}.dimensions, 'TIME');
    iDepth = getVar(sample_data{iSort(i)}.variables, 'DEPTH');
    iVar = getVar(sample_data{iSort(i)}.variables, varName);
    
    if iVar > 0 && iDepth > 0 && size(sample_data{iSort(i)}.variables{iVar}.data, 2) == 1 % we're only plotting 1D variables with depth variable
        if initiateFigure
            fileName = genIMOSFileName(sample_data{iSort(i)}, 'png');
            visible = 'on';
            if saveToFile, visible = 'off'; end
            hFigMooringVar = figure(...
                'Name', title, ...
                'NumberTitle','off', ...
                'Visible', visible, ...
                'OuterPosition', [0, 0, monitorRec(iBigMonitor, 3), monitorRec(iBigMonitor, 4)]);
            
            hAxMooringVar = axes('Parent',   hFigMooringVar);
            set(hAxMooringVar, 'YDir', 'reverse');
            set(get(hAxMooringVar, 'XLabel'), 'String', 'Time');
            set(get(hAxMooringVar, 'YLabel'), 'String', 'DEPTH (m)', 'Interpreter', 'none');
            set(get(hAxMooringVar, 'Title'), 'String', title, 'Interpreter', 'none');
            set(hAxMooringVar, 'XTick', (xMin:(xMax-xMin)/4:xMax));
            set(hAxMooringVar, 'XLim', [xMin, xMax]);
            hold(hAxMooringVar, 'on');
            
            hCBar = colorbar('peer', hAxMooringVar);
            set(get(hCBar, 'Title'), 'String', [varName ' (' varUnit ')'], 'Interpreter', 'none');
            
            initiateFigure = false;
        end
        

        hScatterVar(1) = line([xMin, xMax], [metaDepth(i), metaDepth(i)], ...
            'Color', 'black');
            
        iGood = true(size(sample_data{iSort(i)}.variables{iVar}.data));
        
        if isQC
            %get time, depth and var QC information
            timeFlags = sample_data{iSort(i)}.dimensions{iTime}.flags;
            depthFlags = sample_data{iSort(i)}.variables{iDepth}.flags;
            varFlags = sample_data{iSort(i)}.variables{iVar}.flags;
            
            iGood = (timeFlags == 1 | timeFlags == 2) & (varFlags == 1 | varFlags == 2) & (depthFlags == 1 | depthFlags == 2);
        end
        
        if all(~iGood)
            fprintf('%s\n', ['Warning : in ' sample_data{iSort(i)}.toolbox_input_file ...
                ', there is not any data with good flags.']);
        else
            hScatterVar(i + 1) = scatter(sample_data{iSort(i)}.dimensions{iTime}.data(iGood), ...
                sample_data{iSort(i)}.variables{iDepth}.data(iGood), ...
                5, ...
                sample_data{iSort(i)}.variables{iVar}.data(iGood), ...
                markerStyle{mod(i, lenMarkerStyle)+1});
           
            % set background to be grey
            set(hAxMooringVar, 'Color', [0.75 0.75 0.75])
        end
        
        
    else
%         fprintf('%s\n', ['Warning : in ' sample_data{iSort(i)}.toolbox_input_file ...
%             ', there is no ' varName ' variable.']);
    end
end

if ~initiateFigure
    iNan = isnan(hScatterVar);
    if any(iNan)
        hScatterVar(iNan) = [];
        instrumentDesc(iNan) = [];
    end
    
    datetick(hAxMooringVar, 'x', 'dd-mm-yy HH:MM:SS', 'keepticks');
    
    % we try to split the legend in two location horizontally
    nLine = length(hScatterVar);
    if nLine > 2
        nLine1 = ceil(nLine/2);
        
        hLegend(1) = multipleLegend(hAxMooringVar, hScatterVar(1:nLine1),         instrumentDesc(1:nLine1),       'Location', 'SouthOutside');
        hLegend(2) = multipleLegend(hAxMooringVar, hScatterVar(nLine1+1:nLine),   instrumentDesc(nLine1+1:nLine), 'Location', 'SouthOutside');
        
        posAx = get(hAxMooringVar, 'Position');
        
        pos1 = get(hLegend(1), 'Position');
        pos2 = get(hLegend(2), 'Position');
        maxWidth = max(pos1(3), pos2(3));
%         set(hLegend(1), 'Position', [pos1(1)-maxWidth/2, pos1(2), pos1(3), pos1(4)]);
%         set(hLegend(2), 'Position', [pos1(1)+maxWidth/2, pos1(2), pos1(3), pos1(4)]);
        set(hLegend(1), 'Position', [0   + 2*maxWidth, pos1(2), pos1(3), pos1(4)]);
        set(hLegend(2), 'Position', [0.5 + 2*maxWidth, pos1(2), pos1(3), pos1(4)]);
        
        % set position on legends above modifies position of axis so we
        % re-initialise it
        set(hAxMooringVar, 'Position', posAx);
    else
        hLegend = legend(hAxMooringVar, hScatterVar, instrumentDesc, 'Location', 'SouthOutside');
    end
    
    set(hLegend, 'Box', 'off', 'Color', 'none');
    
    if saveToFile
        % the default renderer under windows is opengl; for some reason,
        % printing pcolor plots fails when using opengl as the renderer
        set(hFigMooringVar, 'Renderer', 'zbuffer');
        
        % ensure the printed version is the same whatever the screen used.
        set(hFigMooringVar, 'PaperPositionMode', 'manual');
        set(hFigMooringVar, 'PaperType', 'A4', 'PaperOrientation', 'landscape', 'PaperUnits', 'normalized', 'PaperPosition', [0, 0, 1, 1]);
        
        % preserve the color scheme
        set(hFigMooringVar, 'InvertHardcopy', 'off');
                
        fileName = strrep(fileName, '_PARAM_', ['_', varName, '_']); % IMOS_[sub-facility_code]_[site_code]_FV01_[deployment_code]_[PLOT-TYPE]_[PARAM]_C-[creation_date].png
        fileName = strrep(fileName, '_PLOT-TYPE_', '_SCATTER_');
        
        print(hFigMooringVar, fullfile(exportDir, fileName), '-dpng');
        
        % trick to save the image in landscape rather than portrait file
        image = imread(fullfile(exportDir, fileName), 'png');
        r = image(:,:,1);
        g = image(:,:,2);
        b = image(:,:,3);
        r = rot90(r, 3);
        g = rot90(g, 3);
        b = rot90(b, 3);
        image = cat(3, r, g, b);
        imwrite(image, fullfile(exportDir, fileName), 'png');
    end
end

end