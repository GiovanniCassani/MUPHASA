function [cleanMatrix, cleanEffects, outliers] = removeOutliers(matrix, t, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% This function takes a data matrix (of dimensionality m-by-n, where m    %
% can be any number and m need to be >= 2) and a scalr t, indicating the  %
% factor by which the IQR of the distances between each point and the     %
% centroid is multiplied to detect and remove outliers. Moreover, a third %
% optional argument can be passed in the form of a cell array of strings  %
% containing possible random effects to be taken into account, aligned    %
% with the data matrix.                                                   %
% Outliers are removed by computing the Mahalanobis distance between each %
% observation and the centroid. Every observation whose distance falls    %
% more than t times the IQR computed on the distances is removed. The     %
% function returns the clean data matrix and, if random effects are       %
% passed, the clean array containing the random effects, plus the vector  %
% containing the outliers.                                                % 
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

defaultRandom = {};

addRequired(p,'matrix',@ismatrix);
addRequired(p,'t',@isnumeric);
addParameter(p,'random',defaultRandom,@iscell)

parse(p,matrix,t,varargin{:})

random = p.Results.random;

[~, c] = size(matrix);
if c < 2
    error(['removeOutliers:argChk', ...
        'The input matrix need to consist of at least two columns.'])
end

cleanMatrix = [];
outliers = [];
cleanEffects = {};
[rows,~] = size(matrix);
[~,numEffects] = size(random); 
avgs = mean(matrix);      
S = cov(matrix);
distances = zeros(rows, 1);
        
for i = 1:rows
    distances(i,1) = (matrix(i,:) - avgs) * pinv(S) * (matrix(i,:) - avgs)';
end

t = iqr(distances) * t;
idx = 1;
idxOut = 1;
for j = 1:rows
    if distances(j) < t == 1
        cleanMatrix(idx,:) = matrix(j,:);
        for k = 1:numEffects
            cleanEffects{idx,k} = random{idx,k};
        end
        idx = idx + 1;
        
    else
        outliers(idxOut,1) = distances(j);
        idxOut = idxOut + 1;
    end
end

end

