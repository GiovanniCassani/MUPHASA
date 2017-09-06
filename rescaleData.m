function scaledMatrix = rescaleData(matrix, minima, maxima)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% This function takes a matrix as input and rescale it to the range [0:1] %
% using the values provided in minima and maxima (which must have the     %
% same dimensionality as matrix. The final argument, 'method', specifies  %
% whether each dimension should be rescaled separately (with a minimum    %
% and a maximum on each) or if the data should be rescaled globally,      %
% considering only one minimum and one maximum, irrespectively of the     %
% dimension in which they are found.                                      %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[rows,cols] = size(matrix);
[~, minCols] = size(minima);
[~, maxCols] = size(maxima);

if ~isequal(cols, minCols, maxCols)
    error('rescale:argChk', 'The number of columns must be equal across inputs.')
end

scaledMatrix = zeros(rows, cols);

for i = 1:cols
    for j = 1:rows
        if minima(i) < 0
            scaledMatrix(j,i) = (matrix(j,i) + abs(minima(i))) / ...
                (maxima(i) + abs(minima(i)));
        else
            scaledMatrix(j,i) = (matrix(j,i) - minima(i)) / ...
                (maxima(i) - minima(i));
        end
    end
end
end

