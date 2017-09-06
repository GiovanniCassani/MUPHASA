function [vol, vertices] = hullsIntersection(dirPath, path1, path2)

% This function is implemented to work on MAC OS. If you are working on a
% different Operating System you might have to substitute '/usr/local/bin'
% with the path where Rscript is located on your machine. To find it out,
% open your terminal, type 'which Rscript' and copy paste the resulting
% path in place of '/usr/local/bin', stripping away 'Rscript'.
%
% This function requires R to be installed on your machine, together with
% the packages 'geometry' and 'rcdd'.
%
% To download R, https://cran.r-project.org/mirrors.html
% To install packages, open your R consolle, type
% install.packages('PACKAGE')
%
% The first input argument is the path, relative or absolute, to the folder
% where the R functions 'hullsIntersect.R' and 'CHVintersect.R' are -
% typically the MATLAB folder containing MUPHASA.
% The second and third arguments point to the files - created by MUPHASA -
% containing the coordinates of the vertices defining the convex hulls of
% the two groups being compared. If you are interested in the intersection
% between groupA and group B, these two paths will point to the files
% containing the coordinates of their vertices.
%
% This function automatically runs the R scripts to extract the relavant
% measures, creates two temporary files that are deleted before the end,
% and outputs 1) the volume of the intersection and 2) the coordinates of
% the vertices of the convex hull defining the intersection between the
% convex hulls fitted on the data from the two relevant groups.

setenv('PATH', [getenv('PATH'),':','/usr/local/bin'])

baseDir = cd;
cd(dirPath)

funPath = strcat(dirPath, 'hullsIntersection.R');

cmd = ['Rscript ', funPath, ' "', path1, '" "', path2, '" "', dirPath, '"'];
system(cmd);

vertices = csvread('vertices.csv');
vol = csvread('volume.csv');

delete('vertices.csv');
delete('volume.csv');

cd(baseDir)
