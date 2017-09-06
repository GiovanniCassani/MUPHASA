function scatterplots(matrix, color, name, variables, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% This function plots simple a 3d scatterplot, but also computes and show %
% the ranges on each dimension.                                           %
% This function takes a structure as input, which must contain the        %
% following mandatory attributes:                                         %
%  - scaledData, a matrix where each row is a point and each column a     %
%      dimension                                                          %
%  - color, an RGB triple or string specifying a color                    %
% The second and third input specifies the azimut and the elevation of    %
% the 3d viewpoint; the fourth the coordinates where the ranges should be %
% plotted while the last argument contains the axis names, in a a 1-by-3  %
% cell array of strings.                                                  %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

default_el = 30;
default_az = 50;
default_lower = -0.15;
default_upper = 1.15;
default_loc = [0 1];

addRequired(p,'matrix',@ismatrix);
addRequired(p,'color',@ismatrix);
addRequired(p,'name',@ischar);
addRequired(p,'variables',@iscell);
addParameter(p,'el',default_el,@isnumeric)
addParameter(p,'az',default_az,@isnumeric)
addParameter(p,'lower',default_lower,@isnumeric)
addParameter(p,'upper',default_upper,@isnumeric)
addParameter(p,'loc',default_loc,@ismatrix)

parse(p,matrix,color,name,variables,varargin{:})

el = p.Results.el;
az = p.Results.az;
lower = p.Results.lower;
upper = p.Results.upper;
loc = p.Results.loc;

[~,c] = size(matrix);

if c ~= length(variables)
    error(['plotConvHulls:argChk', ...
        'Dimensionality mismatch!' ...
        'The input matrix must have as many columns as there are variable names.'])
end

minima = min(matrix);
maxima = max(matrix);

title(name)
xlabel(variables{1})
ylabel(variables{2})
xlim([lower upper])
ylim([lower upper])
         
if c == 2
    
    RangeA = [ minima(1) min(loc);
               maxima(1) min(loc)];
    RangeB = [ min(loc) minima(2);
               min(loc) maxima(2)];
           
    hold on
    grid on
    scatter(matrix(:,1), matrix(:,2), 10, 'MarkerFaceColor', color, ...
        'MarkerEdgeColor', color);
    
    plot(RangeA(:,1), RangeA(:,2), ...
            '-', 'Color', color, 'LineWidth', 2)
    plot(RangeB(:,1), RangeB(:,2), ...
            '-', 'Color', color, 'LineWidth', 2)
    
    hold off
    
elseif c == 3
    
    RangeA = [ minima(1) min(loc) lower;
               maxima(1) min(loc) lower];
    RangeB = [ max(loc) minima(2)  lower;
               max(loc) maxima(2)  lower];
    RangeC = [ lower min(loc) minima(3);
               lower min(loc) maxima(3)];
           
    zlabel(variables{3})
    zlim([lower upper])
    view(az, el);
    hold on
    grid on
    
    scatter3(matrix(:,1), matrix(:,2), matrix(:,3), ...
        10, 'MarkerFaceColor', color, 'MarkerEdgeColor', color);
    
    plot3(RangeA(:,1), RangeA(:,2), RangeA(:,3), ...
        '-', 'Color', color, 'LineWidth', 2)
    plot3(RangeB(:,1), RangeB(:,2), RangeB(:,3), ...
        '-', 'Color', color, 'LineWidth', 2)
    plot3(RangeC(:,1), RangeC(:,2), RangeC(:,3), ...
        '-', 'Color', color, 'LineWidth', 2)
    
    hold off
end
