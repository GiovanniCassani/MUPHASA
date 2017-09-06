function [STRUCT, DIST] = muphasa(inputFile, predictors, outcomes, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% This function takes three mandatory inputs:                             %
% - the path pointing to a dataset (.txt, .dat, .csv): decimal numbers    %
%   NEED to be separated with dots, not commas                            %
% - a cell array of strings containing the column name(s) of the          %
%   independent categorical variable(s) (max: 2 predictors, in a 1-by-n   %
%   cell array)                                                           %
% - a cell array of strings containing the column names of the            %
%   quantitative dependent variables (minimum two variables, in a 1-by-n  %
%   cell array)                                                           %
% Moreover, several optional parameters can be passed:                    %
% - 'sep', a separator, indicating the string separating columns in the   %
%   input file (default: tab)                                             %
% - 't', the threshold to remove outliers, indicating the factor by which %
%   the IQR of distances from the centroid is multiplied to obtain the    %
%   cutoff distance for outlier detection and removal (default: null, no  %
%   outlier detection is performed                                        %
% - 'random', a cell array of strings containing the column name(s) of    %
%   the variables to be included as random effects (default: empty cell)  %
% - 'graphs', a specification of whether to create plots (1) or not (0)   %
%   (default: 1)                                                          %
% - 'rescale', a specification of whether to plot data rescaled to the    %
%    range [0 1] (1) or not (0); default (1)                              %
% - 'video', a specification of whether to make videos (1) or not (0)     %
%   (default: 0)                                                          %
% - 'WinML', a specification of whether WinML compatible output files     %
%   need to be created as output (default: 0, i.e. no WinML compatible    %
%   output is created)                                                    %
% - 'el', specifying the elevation point of 3d plots (default: 30)        %
% - 'az', specifying the azimutal point of 3d plots (default: 50)         %
% - 'alpha', specifying the transparency of surfaces in convex hull plots %
%    (default: 0.3)                                                       %
% - 'frameRate', specifying the number of frames per second for the       %
%   videos (default: 50)                                                  %
%                                                                         %
% The function outputs two structures (information in each structures is  %
% also printed to files in the directory containing the input dataset):   %
%  - STRUCT contains one structure for each subset, which in turn         %
%       consists of:                                                      %
%       - cleaned data (outliers and NaNs removed)                        %
%       - cleaned fixed effects vectors                                   %
%       - data used to fit convex hulls (if the 'rescale' option is set   %
%         to 1, this contains observations rescaled to the range [0 1];   %
%         if the option rescale is set to 0, this is the same as clean    %
%         data)                                                           %
%       - number of observations                                          %
%       - points delimiting the convex hull                               %
%       - volume of the convex hull                                       %
%       - density, or number of points per unit of volume                 %
%       - coordinates of the centroid                                     %
%       - ranges                                                          %
%       - minima and maxima along each dimension                          %
%       - covariance matrix                                               %
%       - correlation matrix                                              %
%  - DIST contains pair-wise Euclidean distances between centroids        %
%                                                                         %
%  Moreover, videos of rotating 3d plots are created and saved in the     %
%  directory of the input dataset, showing the intersection between       %
%  groups.                                                                %
%  Finally, data are printed to files in a WinML compatible format.       %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% EXAMPLE CALL:                                                           %
%  a .txt, comma separated file; one predictor, 'pred1'; three outcomes,  %
%  'varA', 'varB', 'varC'; a cutoff of 2*IQR; no video e no random        %
%  effects                                                                %
%                                                                         %
% >> in_path = '~/myExperiment/datafile.txt';                             %
% >> independent = {'pred1'};                                             %
% >> dependent = {'varA', 'varB', 'varC'};                                %
% >> [STRUCT, DIST] = muphasa(in_path, independent, dependent, ...        %
%                             'sep', ',', 't', 2)                         %
% STRUCT will contain as many sub-structures as the levels of the         %
% categorical predictor; DIST will contain pairwise Euclidean distances   %
% between centroids.                                                      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

defaultSep = '\t';
defaultVideo = 0;
defaultGraphs = 1;
defaultRescale = 1;
defaultWinML = 0;
defaultRandom = {};
defaultT = NaN; 
default_el = 30;
default_az = 50;
default_alpha = 0.3;
default_frameRate = 50;
default_ext = '-djpeg';

addRequired(p,'inputFile',@ischar);
addRequired(p,'predictors',@iscell);
addRequired(p,'outcomes',@iscell);
addParameter(p,'sep',defaultSep,@ischar)
addParameter(p,'graphs',defaultGraphs,@isnumeric)
addParameter(p,'rescale',defaultRescale,@isnumeric)
addParameter(p,'video',defaultVideo,@isnumeric)
addParameter(p,'random',defaultRandom,@iscell)
addParameter(p,'t',defaultT,@isnumeric)
addParameter(p,'winml',defaultWinML,@isnumeric)
addParameter(p,'el',default_el,@isnumeric)
addParameter(p,'az',default_az,@isnumeric)
addParameter(p,'alpha',default_alpha,@isnumeric)
addParameter(p,'frameRate',default_frameRate,@isnumeric)
addParameter(p,'ext',default_ext,@ischar)

parse(p,inputFile,predictors,outcomes,varargin{:})

sep = p.Results.sep;
video = p.Results.video;
graphs = p.Results.graphs;
rescale = p.Results.rescale;
random_effects = p.Results.random;
t = p.Results.t;
winml = p.Results.winml;
el = p.Results.el;
az = p.Results.az;
alpha = p.Results.alpha;
frameRate = p.Results.frameRate;
ext = p.Results.ext;

disp(['Input file: ',p.Results.inputFile])
disp(['Categorical predictors: ', p.Results.predictors])
disp(['Continuous outcomes: ', p.Results.outcomes])

if ~isempty(p.UsingDefaults)
   disp('Using defaults: ')
   disp(p.UsingDefaults)
end

[factorRows, factorCols] = size(p.Results.predictors);
if factorRows > 1 || factorCols > 2
    error(['muphasa:argChk', ...
        'Please provide no more than two predictors in 1-by-2 cell array.'])
end
    % the function only accepts one or two categorical predictors
    
[varRows, varCols] = size(outcomes);
if varRows > 1 || varCols < 2
    error(['muphasa:argChk', ...
        'Please provide at least 2 outcome variables in a 1-by-n cell array'])
end

if ~strcmp(ext(1:2), '-d')
    ext = strcat('-d', ext);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Process input dataset and select relevant fields  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data_all = readtable(inputFile, 'Delimiter', sep);
column_names = data_all.Properties.VariableNames;

[~,numPred] = size(predictors);
[~,numOutc] = size(outcomes);

try
    data_subset = data_all(:, [predictors, random_effects, outcomes]);
catch exception
    for p = 1:length(predictors)
        if ~any(ismember(column_names,predictors{p}))
            sprintf('Predictor %s was not found among the column names', ...
                predictors{p})
        end
    end
    for o = 1:length(outcomes)
        if ~any(ismember(column_names,outcomes{o}))
            sprintf('Outcome %s was not found among the column names', ...
                outcomes{o})
        end
    end
    for r = 1:length(random_effects)
        if ~any(ismember(column_names,random_effects{r}))
            sprintf('Random effect %s was not found among the column names', ...
                random_effects{r})
        end
    end
    
    error('stressPatterns:argChk', ...
        'Some of the provided predictors, outcomes, or random effects could not be found among the column names.')
end
    
[path, ~, ~] = fileparts(inputFile);

% get rid of observations with missing values on the predictors or the
% outcomes; missing values in the random effects are not considered
missingObs = ismissing(data_subset(:, [predictors, outcomes]));
data = data_subset(~any(missingObs,2),:);

clear data_all data_subset missingObs del inputFile varargin
clear factorCols factorRows varCols varRows r o p
    % clean the workspace

if numPred == 1      % one predictor is passed
    if ~isa(class(data.(predictors{1})), 'nominal')
        data.(predictors{1}) = nominal(data.(predictors{1}));
        levelsA = (categories(data.(predictors{1})))';
        levelsB = {''};
    end
        % Make sure that the class of the predictor is nominal, and change 
        % it if necessary. Get its levels.
        
    labels = cell(1,length(levelsA));
    for i=1:length(levelsA)
        labels{i} = levelsA{i};
        groups.(labels{i}) = data(data.(predictors{1}) == levelsA{i}, :);
    end
         % use its levels as labels for the various sub-samples
    
elseif numPred == 2     % two predictors are passed
    if ~isa(class(data.(predictors{1})), 'nominal')
        data.(predictors{1}) = nominal(data.(predictors{1}));
        levelsA = (categories(data.(predictors{1})))';
    end
    if ~isa(class(data.(predictors{2})), 'nominal')
        data.(predictors{2}) = nominal(data.(predictors{2}));
        levelsB = (categories(data.(predictors{2})))';
    end
        % Make sure that the class of both predictors is nominal, and
        % change it if required. Get the levels of each predictor and store
        % them in two different cell arrays
        
    for i = 1:length(outcomes)
        if ~isnumeric(data.(outcomes{i}))
            error(['stressPatterns:argChk', ...
                'The dependent variables must be numerical.'])
        end
    end
    
    labels = cell(length(levelsA), length(levelsB));
    for i=1:length(levelsA)
        for j=1:length(levelsB)
            labels{i,j} = strcat(levelsA{i}, '__', levelsB{j});
            groups.(labels{i,j}) = data(data.(predictors{1}) == ...
                levelsA{i} & data.(predictors{2}) == levelsB{j}, :);
        end
    end
        % create a cell array of labels, obtained by combining each level
        % of the first predictor with every level of the second, and subset
        % data, labeling them with the just-derived labels
end
    
clear data 

axes_names = strrep(outcomes, '_', '__');

           % regular         % light           % dark            % mild
colors = {[0.90 0.00 0.00], [1.00 0.51 0.75], [1.00 0.28 0.23], [0.52 0.00 0.00];  % red
          [0.01 0.26 0.86], [0.58 0.82 0.99], [0.46 0.73 0.99], [0.00 0.01 0.36];  % blue
          [0.08 0.69 0.10], [0.56 1.00 0.62], [0.59 0.98 0.48], [0.01 0.21 0.00];  % green
          [0.98 0.45 0.02], [1.00 0.69 0.43], [0.99 0.67 0.28], [0.78 0.32 0.01]}; % orange
      
      % This color matrix accept two predictors with at max four levels 
      % each. The levels from the first predictor are represented as 
      % different colors (red, blue, green, orange) - the columns of the 
      % matrix. The levels from the second predictor are represented as 
      % different shades of the four colors (dark, regular, light, very 
      % light) - the rows of the matrix.
      % Thus, the subset defined by the first level of the first predictor
      % and the second level of the second predictor will be represented by
      % the color in column 1 and row 2, i.e. regular red.
      % Each subset is assigned a unique color.
      
      
if numPred == 1
    for i = 1:length(labels)
        STRUCT.(labels{1,i}).color = colors{i,1};
    end
elseif numPred == 2
    [rows, cols] = size(labels);
    for i = 1:rows
        for j = 1:cols
            STRUCT.(labels{i,j}).color = colors{i,j};
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    Remove outliers and rescale data to the range [0 1]  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

labels = reshape(labels, [1, length(levelsA)*length(levelsB)]);
minima = zeros(length(labels), length(outcomes));
maxima = zeros(length(labels), length(outcomes));

for i=1:length(labels)
    if ~isnan(t)
        [STRUCT.(labels{i}).cleanData, STRUCT.(labels{i}).cleanEffects, ...
            STRUCT.(labels{i}).outliers] = ...
            removeOutliers(groups.(labels{i}){:, end-numOutc+1:end}, ...
            t, 'random', table2cell(groups.(labels{i})(:, random_effects)));
    else
        STRUCT.(labels{i}).cleanData = groups.(labels{i}){:, end-(numOutc-1):end};
        STRUCT.(labels{i}).cleanEffects = table2cell(groups.(labels{i})(:, random_effects));
        STRUCT.(labels{i}).outliers = 0;
    end
    
    minima(i,:) = min(STRUCT.(labels{i}).cleanData);
    maxima(i,:) = max(STRUCT.(labels{i}).cleanData);
        % if a threshold is passed, remove outliers and then take min and 
        % max values for each dimension in each subset. If no threshold is
        % passed, use all data from the input matrix
end

m = min(minima);
M = max(maxima);
    % get min and max values for each dimension, for all the four subsets 
    % together 
    
clear minima maxima groups

for i=1:length(labels)
    if rescale == 1
        STRUCT.(labels{i}).fitted = rescaleData(STRUCT.(labels{i}).cleanData, ...
            m, M);
            % rescale data to the range [0 1] dimension-wise, so that each
            % dimensions will have its own 0 and 1
    else
        STRUCT.(labels{i}).fitted = STRUCT.(labels{i}).cleanData;
    end
    
        STRUCT.(labels{i}) = statsHulls(STRUCT.(labels{i}));
            % compute the convex hull for each subgroup togethger with
            % descriptive statistics including density, centroid 
            % coordinates in the rescaled space, ranges on each dimension, 
            % minima and maxima, covariance and correlation matrix
    
end

if rescale == 1
    m = 0;
    M = 1;
else
    m = min(m);
    M = max(M);
end

upper = M + (abs(M - m) / 100 * 15); 
lower = m - (abs(M - m) / 100 * 15);

    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Scatter plot the data and fit the convex hulls,  %
%                                            showing group intersections  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% only create graphics in two or three dimensional cases, if graphs are
% required
if numOutc < 4 && graphs ~= 0
    last = path(end);
    if strcmpi(last, '/') == 0
        path = strcat(path, '/');
        % add a / in case the string homeFolder doesn't end with a /
    end
    
    if ~exist(strcat(path, 'graphics/'), 'dir')
        mkdir(strcat(path, 'graphics/'))
    end
    
    graphics_path = strcat(path, 'graphics/');
    
    % create a convex hull and a scatter plot for every sub-group in which 
    % the dataset is divided
    figure('name','Group patterns', 'Position', [100, 175, 900, 800])
    for i = 1:length(labels)
        subplot(length(levelsA),length(levelsB),i)
        grid on
        grid minor
        plotConvHulls(STRUCT.(labels{i}).fitted, ...
            STRUCT.(labels{i}).K, STRUCT.(labels{i}).color, ...
            labels{i}, outcomes);
        scatterplots(STRUCT.(labels{i}).fitted, ...
            STRUCT.(labels{i}).color, labels{i}, axes_names, 'az', az, ...
            'el', el, 'lower', lower, 'upper', upper, 'loc', [m M]);
    end
    image_path = strcat(graphics_path, '/groupPatterns');
    print(image_path, ext)
    close
    
    % create plots showing intersections between subgroups
    % if one categorical predictor is passed, create a single plot and 
    % show all sub-groups on the same plot
    if numPred == 1
        figure('name', 'Groups Intersection', ...
            'Position', [200, 150, 900, 400])
        range_pos = [m M];
        for i = 1:length(levelsA)
            grid on
            grid minor
            plotConvHulls(STRUCT.(labels{i}).fitted, ...
                STRUCT.(labels{i}).K, STRUCT.(labels{i}).color, ...
                labels{i}, outcomes);
            scatterplots(STRUCT.(labels{i}).fitted, ...
                STRUCT.(labels{i}).color, predictors{1}, ...
                axes_names, 'loc', range_pos, 'az', az, ...
                'el', el, 'lower', lower, 'upper', upper);
            range_pos(1) = range_pos(1) - 0.03;
            range_pos(2) = range_pos(2) + 0.03;
        end
        image_path = strcat(graphics_path, '/groupIntersections');
        print(image_path, ext)
        close
        
        % if two categorical predictors are passed, create one plot for 
        % every level of each of the two predictors, and plot all the 
        % sub-groups sharing that level
    elseif numPred == 2
        figure('name', 'Groups Intersections', ...
            'Position', [200, 150, 900, 800])
        idx = 1;
        disp(length(levelsA))
        disp(length(levelsB))
        for i = 1:length(levelsA)
            subplot(length(levelsA), length(levelsB), idx)
            range_pos = [m M];
            grid on
            grid minor
            for j = 1:length(levelsB)
                curr_name = strcat(levelsA{i}, '__', levelsB{j});
                plotConvHulls(STRUCT.(curr_name).fitted, ...
                    STRUCT.(curr_name).K, STRUCT.(curr_name).color, ...
                    levelsA{i}, axes_names);
                scatterplots(STRUCT.(curr_name).fitted, ...
                    STRUCT.(curr_name).color, levelsA{i}, ...
                    axes_names, 'loc', range_pos, 'az', az, ...
                    'el', el, 'lower', lower, 'upper', upper);
                range_pos(1) = range_pos(1) - 0.03;
                range_pos(2) = range_pos(2) + 0.03;
            end
            idx = idx + 1;
        end
        
        for i = 1:length(levelsB)
            subplot(length(levelsA), length(levelsB), idx)
            range_pos = [m M];
            grid on
            grid minor
            for j = 1:length(levelsA)
                curr_name = strcat(levelsA{j}, '__', levelsB{i});
                plotConvHulls(STRUCT.(curr_name).fitted, ...
                    STRUCT.(curr_name).K, STRUCT.(curr_name).color, ...
                    levelsA{i}, axes_names);
                scatterplots(STRUCT.(curr_name).fitted, ...
                    STRUCT.(curr_name).color, levelsB{i}, ...
                    axes_names, 'loc', range_pos, 'az', az, ...
                    'el', el, 'lower', lower, 'upper', upper);
                range_pos(1) = range_pos(1) - 0.03;
                range_pos(2) = range_pos(2) + 0.03;
            end
            idx = idx + 1;
        end
        image_path = strcat(graphics_path, '/groupIntersections');
        print(image_path, ext)
        close
        
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            Compute Euclidean distances between centroids and plot them  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DIST.matrix = zeros(length(labels));
for i = 1:length(labels)
    for j = 1:length(labels)
        if j <= i  
            continue
        end
        name = strcat((labels{i}), '_', (labels{j}));
        DIFF.(name) = abs(STRUCT.(labels{i}).centroid - ...
            STRUCT.(labels{j}).centroid);
        DIST.(name) = sqrt(DIFF.(name) * DIFF.(name)');
        DIST.matrix(i,j) = DIST.(name);
        DIST.matrix(j,i) = DIST.(name);
    end
end

centr = [];
colorsSubset = {};
for i=1:length(labels)
    centr = [centr; STRUCT.(labels{i}).centroid];
    colorsSubset{i} = STRUCT.(labels{i}).color;
    printStats(STRUCT.(labels{i}), labels{i}, axes_names, ...
        'path', path, 'WinML', winml)   
        % concatenate the centroids in a single matrix and write summary
        % statistics to files. Also export scaled data to file, one file
        % for each sub-group.
end

if numOutc < 4 && graphs ~= 0
    fig = centroids(centr, axes_names, colorsSubset, labels, ...
                    'el', el, 'az', az);
    % plot the centroids and the relevant distances
    
    image_path = strcat(graphics_path, '/centroids');
    print(image_path, ext, fig)
    close
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                      Make videos for rotating 3d plots  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if video ~= 0 && numOutc == 3
    for i = 1:length(labels)
        left_margin = 400;
        figure('name', labels{i}, 'Position', [left_margin, 100, 500, 350])
        plotConvHulls(STRUCT.(labels{i}).fitted, ...
                    STRUCT.(labels{i}).K, STRUCT.(labels{i}).color, ...
                    labels{i}, axes_names, 'az', az', 'el', el, ...
                    'lower', lower, 'upper', upper, 'aplha', alpha);
        makeRotatingPlot(graphics_path, labels{i}, ...
                        'az', az, 'el', el, 'frameRate', frameRate)
        
    end
    
    if numPred == 1
        figure('name', predictors{1}, 'Position', [400, 100, 700, 600])
        for i = 1:length(levelsA)
            plotConvHulls(STRUCT.(labels{i}).fitted, ...
                    STRUCT.(labels{i}).K, STRUCT.(labels{i}).color, ...
                    predictors{1}, axes_names, 'az', az', 'el', el, ...
                    'lower', lower, 'upper', upper, 'aplha', alpha);
        end
        makeRotatingPlot(graphics_path, predictors{1}, ...
                        'az', az, 'el', el, 'frameRate', frameRate)
        close
        
    elseif numPred == 2
        figure('name', predictors{1}, 'Position', [400, 100, 1200, 600])
        axis vis3d
        
        idx = 1;
        for i = 1:length(levelsA)
            PlotsA{i} = subplot(1, length(levelsA), idx);
            for j = 1:length(levelsB)
                curr_name = strcat(levelsA{i}, '__', levelsB{j});
                plotConvHulls(STRUCT.(curr_name).fitted, ...
                    STRUCT.(curr_name).K, STRUCT.(curr_name).color, ...
                    levelsA{i}, axes_names, 'az', az', 'el', el, ...
                    'lower', lower, 'upper', upper, 'aplha', alpha);
            end
            idx = idx + 1;
        end
        makeRotatingPlot(graphics_path, predictors{1}, 'plots', PlotsA, ...
                        'az', az, 'el', el, 'frameRate', frameRate)
        close
        
        figure('name', predictors{2}, 'Position', [500, 100, 1200, 600])
        axis vis3d
        idx = 1;
        for i = 1:length(levelsB)
            PlotsB{i} = subplot(1, length(levelsB), idx);
            for j = 1:length(levelsA)
                curr_name = strcat(levelsA{j}, '__', levelsB{i});
                plotConvHulls(STRUCT.(curr_name).fitted, ...
                    STRUCT.(curr_name).K, STRUCT.(curr_name).color, ...
                    levelsB{i}, axes_names, 'az', az', 'el', el, ...
                    'lower', lower, 'upper', upper, 'aplha', alpha);
            end
            idx = idx + 1;
        end
        makeRotatingPlot(graphics_path, predictors{2}, 'plots', PlotsB, ...
                        'az', az, 'el', el, 'frameRate', frameRate)
        close
    end
end

fclose('all');
    
end