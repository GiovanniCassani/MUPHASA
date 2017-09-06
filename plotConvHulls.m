function [CH] = plotConvHulls(matrix, conv_hull, color, name, variables, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% This function simpli fits a convex hull to the input data and plots it. %
% The first argument needs to be a structure with two mandatory           %
% attributes, 'scaledData' and 'color'. The first is a matrix, where each %
% row is an observation and each column a dimensio; the second is an RGB  %
% triple or a string specifying a color. Second and third argument specify%
% the 3d viepoint, the fourth the plot name and the fifth is a cell array %
% specifying the axes names.                                              %
% If called with an output, the function gives the figure handle of the   %
% plot.                                                                   %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

default_el = 30;
default_az = 50;
default_lower = -0.15;
default_upper = 1.15;
default_alpha = 0.3; 

addRequired(p,'matrix',@ismatrix);
addRequired(p,'conv_hull',@ismatrix);
addRequired(p,'color',@ismatrix);
addRequired(p,'name',@ischar);
addRequired(p,'variables',@iscell);
addParameter(p,'el',default_el,@isnumeric)
addParameter(p,'az',default_az,@isnumeric)
addParameter(p,'alpha',default_alpha,@isnumeric)
addParameter(p,'lower',default_lower,@isnumeric)
addParameter(p,'upper',default_upper,@isnumeric)

parse(p,matrix,conv_hull,color,name,variables,varargin{:})

el = p.Results.el;
az = p.Results.az;
alpha = p.Results.alpha;
lower = p.Results.lower;
upper = p.Results.upper;

[~,c] = size(matrix);

if c ~= length(variables)
    error(['plotConvHulls:argChk', ...
        'Dimensionality mismatch!' ...
        'The input matrix must have as many columns as there are variable names.'])
end

hold on
grid on
title(name)
xlabel(variables{1})
ylabel(variables{2})
xlim([lower upper])
ylim([lower upper])

if c == 2
    x = matrix(:,1);
    y = matrix(:,2);
    CH = fill(x(conv_hull), y(conv_hull), color, ...
        'facealpha', alpha, 'EdgeColor', color);
    hold off
elseif c == 3
    zlabel(variables{3})
    zlim([lower upper])
    view(az, el);
    CH = trisurf(conv_hull, matrix(:,1), matrix(:,2), matrix(:,3), ...
        'FaceColor', color, 'facealpha', alpha, 'EdgeColor', color);
    hold off
end
end