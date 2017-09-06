function makeRotatingPlot(graphics_path, name, varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% This function creates short videos of 3d plots, rotating the viewopoint %
% so that the 3d picture is easier to grasp. The path to the folder where %
% the video is to be saved must be supplied as first argument; the second %
% argument is a string specifying the name of the video; the third and    %
% fourth are the azimuthal and elevation parts of the 3d viewpoint. A     %
% fifth optional argument can be passed as a cell array, containing the   %
% plots that will rotate.                                                 %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

p = inputParser;

default_el = 30;
default_az = 50;
default_frameRate = 50;
default_plots = {}; 

addRequired(p,'graphics_path',@ischar);
addRequired(p,'name',@ischar);
addParameter(p,'el',default_el,@isnumeric)
addParameter(p,'az',default_az,@isnumeric)
addParameter(p,'frameRate',default_frameRate,@isnumeric)
addParameter(p,'plots',default_plots,@iscell)

parse(p,matrix,conv_hull,color,name,variables,varargin{:})

el = p.Results.el;
az = p.Results.az;
frameRate = p.results.frameRate;
plots = p.Results.plots;


moviePath2 = strcat(graphics_path, '/rotatingPlots_', name);
movie = VideoWriter(moviePath2);
movie.FrameRate = frameRate;
open(movie)

if isempty(plots)
    for n = 1:3000
        az = az + 0.12;
        axis vis3d
        view([az el])
        frame2 = getframe(gcf);
        writeVideo(movie, frame2)
    end
    
else
    for n = 1:1800
    az = az + 0.1;
        for i = 1:length(plots)
            axis(plots{i}, 'vis3d')
            view(plots{i}, [az el])
            frame2 = getframe(gcf);
            writeVideo(movie, frame2) 
        end
    end
end

close(movie)
close(gcf)

end

