function [struct] = statsHulls(struct)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% This function computes the convex hull for the data in matrix and other %
% relavant statistics to describe the data (number of points per unit of  %
% of volume, coordinates of the centroid, ranges on each dimension, minima%
% and maxima, the variance-covariance matrix and the correlation matrix.  %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

struct.elements = length(struct.fitted(:,1));

[struct.K, struct.V] = convhulln(struct.fitted);

struct.density = struct.elements / struct.V;
struct.centroid = mean(struct.fitted);
struct.ranges = range(struct.fitted);
struct.minima = min(struct.fitted);
struct.maxima = max(struct.fitted);
struct.covariance = cov(struct.cleanData);
struct.corrMatrix = corr(struct.cleanData);

end

