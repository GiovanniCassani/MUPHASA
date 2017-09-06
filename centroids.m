function [fig] = centroids(centroids, variables, colors, labels, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% This function plots the points specified in the first argument (each row%
% is a point, each column a dimension) in a 3d space. Besides, it projects%
% each point onto the three 2d planes defined by the axes.                %
% The second argument specifies the axis names, the second the colors to  %
% be used for each point, and the final argument specifies the names to be%
% included in the legend.                                                 %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

default_el = 30;
default_az = 50;

addRequired(p,'centroids',@ismatrix);
addRequired(p,'variables',@iscell);
addRequired(p,'colors',@iscell);
addRequired(p,'labels',@iscell);
addParameter(p,'el',default_el,@isnumeric)
addParameter(p,'az',default_az,@isnumeric)

parse(p,centroids,variables,colors,labels,varargin{:})

el = p.Results.el;
az = p.Results.az;

[r,c] = size(centroids);

disp(centroids)

if c ~= length(variables)
    error(['plotConvHulls:argChk', ...
        'Dimensionality mismatch!' ...
        'The input matrix must have as many columns as there are variable names.'])
end

m = floor(min(min(centroids)) * 10) / 10;
M = ceil(max(max(centroids)) * 10) / 10;
upper = M + (abs(M - m) / 100 * 15); 
lower = m - (abs(M - m) / 100 * 15);
% derive minimum and maximum coordinates to be used as axes limits, so
% that both plots will appear in a figure with equal axis

fig = figure('name', 'Euclidean Distance between Centroids', ...
    'Position', [300, 125, 800, 600]);

hold on
grid on
grid minor

title('Euclidean distance between centroids', 'FontSize', 16)

xlabel(variables{1}, 'FontSize', 14)
xlim([lower upper])

ylabel(variables{2}, 'FontSize', 14)
ylim([lower upper])


if c == 2
    for i = 1:r
        scatter(centroids(i,1), centroids(i,2), 'square', ...
            'MarkerEdgeColor', colors{i}, 'MarkerFaceColor', colors{i}, ...
            'LineWidth', 8)
    end
    
    legend(labels, 'Location', 'eastoutside', 'FontSize', 14)
    
elseif c == 3
    
    projections = {};
    for i = 1:r
        projections{i} = [centroids(i,1), centroids(i,2), lower;
            centroids(i,1), upper,           centroids(i,3);
            lower,           centroids(i,2), centroids(i,3)];
    end
    % create matrices defining the projection of each centroid onto each of
    % the three planes defined by two dimensions, with the third being
    % constant to the minimum or maximum of the graph: this allows to
    % better visualize the 3d relations between centroids.
    
    zlabel(variables{3}, 'FontSize', 14)
    zlim([lower upper])
    view(az, el)
    
    for i = 1:r
        scatter3(centroids(i,1), centroids(i,2), centroids(i,3), 'square', ...
            'MarkerEdgeColor', colors{i}, 'MarkerFaceColor', colors{i}, ...
            'LineWidth', 8)
    end
    % plot the centroids and their projections onto each 2d plane
    
    legend(labels, 'Location', 'eastoutside', 'FontSize', 14)
    
    for i = 1:r
        scatter3(projections{i}(:,1), projections{i}(:,2), projections{i}(:,3), ...
            10, 'MarkerEdgeColor', colors{i}, 'MarkerFaceColor', ...
            colors{i})
    end
end
end

