function [volumes, ratios, densities, outliers] = checkRobustness(t, inputFile, predictors, outcomes, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% This function allows the user to check whether the descriptive          % 
% statistics computed by MUPHASA are robust with respect to data cleaning %
% procedures. This function takes four mandatory inputs:                  %
% - a vector indicating the different cutoff values to detect outliers:   %
%   the numbers provided are multiplied by the IQR computed on the        %
%   Mahalanobis distances computed between each observation and the       %
%   centroid of the group to which the observation belongs                %
% - the path pointing to a dataset (.txt, .dat, .csv)                     %
% - a cell array of strings containing the column name(s) of the          %
%   independent categorical variable(s) (max: 2 predictors, in a 1-by-n   %
%   cell array                                                            %
% - a cell array of strings containing the column names of the            % 
%   quantitative dependent variables (min: 2 variables, in a 1-by-n cell  %
%   array
% Moreover, the function takes the same optional parameters as muphasa.m, %
% see the documentation of that function for further information.         %
%
% The output consists of four cell arrays, each containing information    %
% about a different descriptive statistic: volume, volume ratios,         %
% densities, and proportion of outliers. Each cell array consists of i) a %
% cell array of strings containing the sub-group names, and ii) a matrix  %
% consisting of as many rows as there are sub-groups and as many columns  %
% as there are values in the input vector 't'. The row order of the data  %
% the matrix corresponds to the row order of the sub-group names in the   %
% cell array. The matrix in the 'ratios' cell array has the same number   %
% of columns as the others, but as many as rows as there possible         %
% combinations of sub-groups defined by the categorical predictors.       %
% The function also generates a plot consisting of four panels, one for   %
% each statistic, plotting how the said statistic varies as a function of %
% the cutoff point to detect outliers.                                    %
%                                                                         %
% This function requires the package legendflex:                          %
% https://nl.mathworks.com/matlabcentral/fileexchange/...                 %
%       31092-legendflex-m--a-more-flexible--customizable-legend          %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

defaultSep = '\t';
defaultVideo = 0;
defaultGraphs = 1;
defaultRescale = 1;
defaultWinML = 0;
defaultRandom = {};
default_el = 30;
default_az = 50;
default_alpha = 0.3;
default_frameRate = 50;
default_ext = '-djpeg';

addRequired(p,'t',@isvector);
addRequired(p,'inputFile',@ischar);
addRequired(p,'predictors',@iscell);
addRequired(p,'outcomes',@iscell);
addParameter(p,'sep',defaultSep,@ischar)
addParameter(p,'graphs',defaultGraphs,@isnumeric)
addParameter(p,'rescale',defaultRescale,@isnumeric)
addParameter(p,'video',defaultVideo,@isnumeric)
addParameter(p,'random',defaultRandom,@iscell)
addParameter(p,'winml',defaultWinML,@isnumeric)
addParameter(p,'el',default_el,@isnumeric)
addParameter(p,'az',default_az,@isnumeric)
addParameter(p,'alpha',default_alpha,@isnumeric)
addParameter(p,'frameRate',default_frameRate,@isnumeric)
addParameter(p,'ext',default_ext,@ischar)

parse(p,t,inputFile,predictors,outcomes,varargin{:})

sep = p.Results.sep;
video = p.Results.video;
graphs = p.Results.graphs;
rescale = p.Results.rescale;
random_effects = p.Results.random;
winml = p.Results.winml;
el = p.Results.el;
az = p.Results.az;
alpha = p.Results.alpha;
frameRate = p.Results.frameRate;
ext = p.Results.ext;

ids2names = containers.Map('KeyType', 'int32', 'ValueType', 'char');

% first compute statistics without removing any outlier
[STRUCT, ~] = muphasa(inputFile, predictors, outcomes, ...
        'sep', sep, 'video', video, 'graphs', graphs, 'random', ...
        random_effects, 'rescale', rescale, 'winML', winml, 'el', el, ...
        'az', az,  'alpha', alpha, 'frameRate', frameRate, 'ext', ext);
    
% get the sub-group names
names = fieldnames(STRUCT);
for n = 1:length(names)
    ids2names(n) = names{n};
end

% pre-allocate the output structures
volumes = {cell(length(names), 1), zeros(length(names), length(t) + 1)};
densities = {cell(length(names), 1), zeros(length(names), length(t) + 1)};
outliers = {cell(length(names), 1), zeros(length(names), length(t) + 1)};
ratios = {cell(sum(1:length(names)) - length(names), 1), ...
    zeros(sum(1:length(names)) - length(names), length(t) + 1)};

% store statistics for the case where no otulier detection is carried out
idx = 1;
for j = 1:length(names)
    
    volumes{1}{j} = names{j};
    volumes{2}(j,end) = STRUCT.(ids2names(j)).V;
    
    densities{1}{j} = names{j};
    densities{2}(j,end) = STRUCT.(ids2names(j)).density;
    
    outliers{1}{j} = names{j};
    outliers{2}(j,end) = length(STRUCT.(ids2names(j)).outliers) / ...
            (length(STRUCT.(ids2names(j)).outliers) + ...
            STRUCT.(ids2names(j)).elements);
    for k = 1:length(names)
        if k <= j  
            continue
        end

        ratios{1}{idx} = char(strcat(names{j}, "__", names{k}));
        ratios{2}(idx,end) = STRUCT.(ids2names(j)).V / STRUCT.(ids2names(k)).V;
        idx = idx + 1;
    end
end

for i = 1:length(t)
    [STRUCT, ~] = muphasa(inputFile, predictors, outcomes, 't', t(i), ...
        'sep', sep, 'video', video, 'graphs', graphs, 'random', ...
        random_effects, 'rescale', rescale, 'winML', winml, 'el', el, ...
        'az', az, 'alpha', alpha, 'frameRate', frameRate, 'ext', ext);
    
    idx = 1;
    for j = 1:length(names)
        
        volumes{2}(j,i) = STRUCT.(ids2names(j)).V;    
        densities{2}(j,i) = STRUCT.(ids2names(j)).density;
        outliers{2}(j,i) = length(STRUCT.(ids2names(j)).outliers) / ...
            (length(STRUCT.(ids2names(j)).outliers) + ...
            STRUCT.(ids2names(j)).elements);
        
        for k = 1:length(names)
            if k <= j
                continue
            end
            ratios{2}(idx,i) = STRUCT.(ids2names(j)).V / ...
                STRUCT.(ids2names(k)).V;
            idx = idx + 1;
        end
    end
end
    
t = [t Inf];

titleFont = 20;
axesFont = 16;
legendFont = 18;

figure('name', 'Descriptive statistics', ...
    'Position', [100, 175, 1600, 900])
subplot(2,2,1)
plot(t, volumes{2}, 'LineWidth', 3)
title('Volume', 'fontsize', titleFont)
xlabel('cutoff', 'fontsize', axesFont)
ylabel('volume', 'fontsize', axesFont)
legendflex(volumes{1}, 'nrow', 1, 'anchor', [2 6], ...
    'buffer', [  0 30], 'fontsize', legendFont)

subplot(2,2,2)
plot(t, densities{2}, 'LineWidth', 3)
title('Density', 'fontsize', titleFont)
xlabel('cutoff', 'fontsize', axesFont)
ylabel('density', 'fontsize', axesFont)
legendflex(densities{1}, 'nrow', 1, 'anchor', [2 6], ...
    'buffer', [  0 30], 'fontsize', legendFont)


subplot(2,2,3)
plot(t, outliers{2}, 'LineWidth', 3)
title('Outliers', 'fontsize', titleFont)
xlabel('cutoff', 'fontsize', axesFont)
ylabel('proportion outliers', 'fontsize', axesFont)
legendflex(outliers{1}, 'nrow', 1, 'anchor', [6 2], ...
    'buffer', [  0 -40], 'fontsize', legendFont)

subplot(2,2,4)
plot(t, ratios{2}, 'LineWidth', 3)
title('Volume Ratios', 'fontsize', titleFont)
xlabel('cutoff', 'fontsize', axesFont)
ylabel('volume ratio', 'fontsize', axesFont)
legendflex(ratios{1}, 'nrow', 2, 'anchor', [6 2], ...
    'buffer', [  0 -40], 'fontsize', legendFont)

end

