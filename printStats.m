function printStats(struct, groupName, variables, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% This function prints the different pieces of information contained in   %
% the input structure to different .txt files. The second argument gives  %
% name that should be added to each file to indetify the data it contains.%
% The third mandatory argument gives the variables' identifiers, that are %
% used to specify the ranges.                                             %
% Two optional arguments ('path' and 'WinML') specifies the path where    %
% files are created (default: current working directory) and whether      %
% WinML compatible files should be created (default: no).                 %
% The input structure must contain the following attributes:              %
% - 'elements': specifies the sample size                                 %
% - 'V': specifies the volume of the convex hull                          %
% - 'density': specifies the number of points per unit                    %
% - 'ranges': a 1-by-n matrix containing the ranges of the data on each   %
%     dimension.                                                          %
% - 'covariance': contains the variance-covariance matrix                 %
% - 'corrMatrix': contains the correlation matrix                         %
% - 'cleanedData': contains a matrix where each row is an observation and %
%     each column a dimension. This matrix should not contain outliers    %
% - 'scaledData': a matrix with the same dimensionality as cleanedData,   %
%     but where the data lies within the range [0 1]                      %
%  - 'cleanEffects': a cell array containing as many rows as the data     %
%     matrices, which contains the random effects for each observation    %
%                                                                         %
% The function creates the following files:                               %
% - 'name'_summaryStatistics.txt: contains the sample size, the volume of %
%     the convex hull fitted to the data, the density (points per unit),  %
%     the ranges on each dimension, the variance-covariance matrix and the%
%     correlation matrix.                                                 %
% - 'name'_cleanData.txt: contains the matrix struct.cleanedData          %
% - 'name'_scaledData.txt: contains the matrix struct.scaledData          %
% Moreover, if the WinML argument is passed, the function also creates    %
% the following files:                                                    %
% - 'name'_winML_(cleaned|scaled).txt: they contain the same data as      %
%     the previous files, but arranged in a WinML compatible format, with %
%     each value precede by the predictor(s), the random effects (if      %
%     provided), and the outcome variable specification. The predictor(s) %
%     is derived from the name (second argument): if two predictors are   %
%     present, make sure that they are divided by two underscores ('__')  %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

defaultPath = pwd;
defaultWinml = 0;

addRequired(p,'struct',@isstruct);
addRequired(p,'groupName',@ischar);
addRequired(p,'variables',@iscell);
addParameter(p,'path',defaultPath,@ischar)
addParameter(p,'WinML',defaultWinml,@isnumeric)

parse(p,struct,groupName,variables,varargin{:})

path = p.Results.path;
winml = p.Results.WinML;

last = path(end);
if strcmpi(last, '/') == 0
    path = strcat(path, '/');
    %add a / in case the string path ends with a different character
end

if ~exist(strcat(path, 'processed/'), 'dir')
    mkdir(strcat(path, 'processed/'))
end

data_path = strcat(path, 'processed/');

statsFile = strcat(data_path, groupName, '_summaryStatistics.txt');
fitted_file = strcat(data_path, groupName, '_fitted.txt');
cleanObs_file = strcat(data_path, groupName, '_cleanData.txt');

fID_stats = fopen(statsFile, 'w');

formatSpec = 'Number of elements: %g \n';
fprintf(fID_stats, formatSpec, struct.elements);
formatSpec = 'Volume size: %g \n';
fprintf(fID_stats, formatSpec, struct.V);
formatSpec = 'Density (or number of points per unit volume): %g \n\n';
fprintf(fID_stats, formatSpec, struct.density);

formatSpec = 'The range on the %s dimensions is: %g (minimum = %g; maximum = %g) \n';
for i=1:length(variables)
    fprintf(fID_stats, formatSpec, variables{i}, struct.ranges(i), ...
        struct. minima(1), struct.maxima(1));
end

fprintf(fID_stats, '\nThe covariance matrix is: \n\n');
fprintf(fID_stats, '\t %6.5f \t %6.5f \t %6.5f \n', struct.covariance);

fprintf(fID_stats, '\n\nThe correlation matrix is: \n\n');
fprintf(fID_stats, '\t %6.5f \t %6.5f \t %6.5f \n', struct.corrMatrix);

dlmwrite(fitted_file, struct.fitted, ...
    'delimiter', '\t', 'precision', 4)
dlmwrite(cleanObs_file, struct.cleanData, ...
    'delimiter', '\t', 'precision', 4)

if winml ~= 0
    
    winMLfile_cleaned = strcat(data_path, groupName, '_winML_cleaned.txt');
    winMLfile_fitted = strcat(data_path, groupName, '_winML_scaled.txt');

    [rowsEff,colsEff] = size(struct.cleanEffects);
    [~,colsObs] = size(struct.fitted);
    names = strsplit(groupName, '__');
    fID_winML_clean = fopen(winMLfile_cleaned, 'w');
    fID_winML_fitted = fopen(winMLfile_fitted, 'w');
    
    for i = 1:rowsEff
        for m = 1:colsObs
            for j = 1:colsEff
                formatSpec = '%s\t';
                if isnumeric(struct.cleanEffects{i,j})
                    effect = num2str(struct.cleanEffects{i,j});
                else
                    effect = struct.cleanEffects{i,j};
                end
                fprintf(fID_winML_clean, formatSpec, effect);
                fprintf(fID_winML_fitted, formatSpec, effect);
                
            end
            for k = 1:length(names)
                formatSpec = '%s\t';
                fprintf(fID_winML_clean, formatSpec, names{k});
                fprintf(fID_winML_fitted, formatSpec, names{k});
            end
            formatSpec = '%s\t%6.5f\n';
            fprintf(fID_winML_clean, formatSpec, variables{m}, struct.cleanData(i,m));
            fprintf(fID_winML_fitted, formatSpec, variables{m}, struct.scaledData(i,m));
        end
    end
end


end

