AUTHOR: Giovanni Cassani

	This repository contains the code for MUPHASA (MUltivariate PHonetics AnaliSys, Accessibly). The code provided here also contains a function originally developed by Sebastien Villeger, that used to be available on his website but no longer is.
	This code is essentially self-dependent, although one function in it depends on the legendflex package by Kelly Kearney. It can be downloaded at this link:
https://nl.mathworks.com/matlabcentral/fileexchange/31092-legendflex-m--a-more-flexible--customizable-legend
	Just copy the folder into your Matlab path and add the following line to your startup.m file:
>> addpath(genpath('kakearney-legendflex-pkg-a21c386'))
(alternatively, you can run that line every time you run MUPHASA.

	MUPHASA allows to perform exploratory data analysis on multivariate data using convex hulls, directly inputing a dataset and the relevant (categorical) predictors and (continuous) outcomes. Its main feature is in the visualisations, that accomodate both 2- and 3-dimensional data. However, a number of descriptive statistics are computed for n-dimensional data as well. MUPHASA works with at most two categorical predictors, each consisting of maximum four levels (the code can be easily modified to accomodate cases with more predictors and levels, but for our experience the visualisations become cluttered and hard to grasp with many predictors and levels). As far as outcome variables are concerned, MUPHASA works with 2 or more continuous variables. Visualisations are produced in the 2- and 3-dimensional cases, but descriptive statistics are computed for n-dimensions.
	MUPHASA aims to provide an accessible way to explore multivariate data, check if a multivariate approach is required, formulate hypothesis, compare groups, and arrange data in such a way that it is easy to input them to inferential statistical functions in a variety of programming languages, including Matlab, R, WinML, Python, and others.
	The main script, muphasa.m, runs the full analysis, but single functions can be used to run single pieces of it. muphasa.m outputs two Matlab structures, one containing summary statistics for all sub-groups determined by the choice of dependent variables, and the other containing the Euclidean distances between the centroids of the sub-groups determined by the categorical independent variables.
	I'll describe how muphasa.m works, breaking it into several steps. Then, I'll describe the output structures in detail.

DATA IMPORT
	muphasa.m can be called by providing the path to a dataset (.txt, .dat, .csv), a cell array of strings indicating the names of the categorical independent variable(s) - no more than two, consisting of no more than 4 levels each -, and a cell array of strings indicating the names of the continuous dependent variables - no fewer than 2. The names are supposed to be column names in the provided dataset.
	Missing observations are removed: an observation is considered missing if any of its values on the independent and dependent variables are not there. This stringent criterion is chosen to improve the robustness of the approach.
	Then, observations in the input dataset are divided into sub-groups depending on the levels in the categorical predictor(s). As an example, with two predictors consisting of two levels each, the dataset would be split into 4 sub-groups, resulting by the crossing of the 2 levels in each of the two predictors.

OUTLIER DETECTION
	It is possible to ask MUPHASA to get rid of outliers. This is carried out for each sub-group by computing the Mahalnobis distance from each observation in a sub-group to the centroid of the sub-group itself. Outliers are removed using the Inter-Quartile Range (IQR), a non-parametric approach, which is more robust and better handles the skewed distribution of Mahalnobis distances. An optional input to muphasa.m, 't', allows to specify the factor by which the IQR needs to be multiplied to determine which observations are outliers.
	Outliers are detected and removed at the sub-group level to take the covariance structure of the sub-group into account, and avoid getting rid of data that are not strange in the subgroup but might be when collapsing two or more, and viceversa.

RESCALING
	After removing missing observations and outliers according to the desired cutoff, observations are rescaled to the range [0 1]. This step is carried out separately on each outcome variable and on the whole set of observations, getting rid of the division into sub-groups. This is to make sure that all sub-groups exist in the same reference space and that relations between observations in different sub-groups are preserved. However, this step is optional.
	The rescaling serves the purpose of having the data in an easily interpretable reference space (a square of side 1 in 2D, a cube of side 1 in 3D, and a hypercube of side 1 in nD). This step is entirely agnostic to units of measure and projects every dependent variable onto the same standard reference space: if this makes sense depends on the problem you want to tackle and the data you have. 
	Finally, rescaling makes the graphs easier to interpret in case on outcome variable lies on a scale that markedly differs from the others in terms of absolute values. This would stretch the visualisation and make differences on the others go un-noticed. Importantly, rescaling only changes the absolute magnitude of the observations, not the relative ones, preserving the structure of the data.

DESCRIPTIVE STATISTICS
	MUPHASA computes and returns several simple descriptive statistics for each sub-group that can be helpful in making sense of your data. These include: the coordinates of the centroids; the ranges, minima, and maxima on all dependent variables; the variance-covariance matrix; and the correlation matrix. These two are particularly useful to assess whether a multivariate approach is required or whether a simpler, combination of univariate analysis will do just fine. If the off-diagonal cells in the two matrices are non-zero it means that there is a relation between at least two of the outcome variables, that is better captured using a multivariate analysis. Practically, if the off-diagonal cells in the correlation matrix are higher than 0.2, a multivariate analysis is warranted (as every arbitrary cut-off, this value should be taken with a grain of salt). However, if the same cells contain values that are larger than 0.8, it might be a sign that one of the dependent variables is not needed because it correlates with another one and collinearity might bias results.

CONVEX HULLS
	The bulk of the exploratory analysis is the fitting and plotting of convex hulls to each sub-group. A convex hull is the smallest convex polytope that can be fitted to a set of observations. It provides an indication of where in the space the observations are, and how much of it they take up. MUPHASA uses built-in Matlab functions to compute the convex hull, both in 2- and 3-dimensions, returning the set of vertices that define it and its volume.
	MUPHASA plots i) the single convex hulls for each sub-group and ii) the relevant intersections across sub-groups. Going back to the example of two predictors, let's call them A and B, consisting of two levels each, 1 and 2, we have four subgroups, [A1, A2, B1, B2], which gives rise to 6 possible intersections. However, A1-B2 and A2-B1 are not relevant because no level is shared. MUPHASA automatically identifies the relevant interactions looking at those situations in which one level is shared, and plot the two corresponding convex hulls onto the same plot, allowing the user to directly compare the two.

INTERSECTIONS
	The CHVintersection script developed by Sebastien Villeger in R is used and wrapped to be run inside MUPHASA. Given two sets of observations, this script computes the volume of the intersection between the two. This provides a measure of how much of the space occupied by a set of observations is also occupied by another set of observations. Largely overlapping sets are more similar than sets that are further apart. This quantifies the relation shown by the plots.

CENTROIDS
	MUPHASA also plots the centroids of all the sub-groups, showing where the centre of mass of each set of observations is.

*CAVEAT: all visualizations only work in 2- or 3-dimensions. In the 3-dimensional case, 3d plots are generated, and there is the possibility of also generating short videos of rotating convex hulls fitted to the various sub-groups, to get a better grip of how the data look like.

OUTPUT STRUCTURES
	The first output structure consists of several inner sub-structures, as many as there are sub-groups defined by the chosen predictors. Each inner structure consists of the following elements:
- an RGB vector indicating the color used in the plots for the corresponding subgroup
- a matrix containing the raw data after removing missing observations and outliers
- a cell array of strings that contains the random effects associated to each observation:  this feature can be directly asked via the 'random' parameter in the main function call
- a matrix containing the observations deemed as outliers
- a matrix containing the rescaled data
- the number of elements that survived the cleaning
- a matrix of indices over the rescaled data indicating the vertices of the convex hull
- the volume of the convex hull
- the density of the hull, computed as #observations/volume, to provide a sample size invariant measure
- the coordinates of the centroid
- the ranges
- the maxima
- the minima
- the variance-covariance matrix
- the correlation matrix

	The second structure contains a matrix consisting of all the pairwise Euclidean distances between the centroids, as well as a scalar for each distance, defined by the levels of the predictors that were considered to compute that distance.
	Importantly, all names in the output structures are assigned dynamically, meaning that the levels of the input predictors are used to name the corresponding structures. The same holds for the plots: titles and axes names are derived from the chosen predictor and outcome variables.

DIAGNOSTICS
	Given that no inferential statistics is provided, the diagnostics are fairly shallow. One thing is however potentially very impactful, and that is the cutoff choice to detect and remove outliers. The function checkRobustness takes a vector with several cutoff points and outputs matrices and plots showing how volumes, volume ratios, densities, and proportion of outliers change by changing the cutoff. If major differences arise when using different cutoffs, extra care should be taken in deciding whether to remove outliers at all, and which cutoff to use.

	For any question, comment, rant, or general feedback please write me at
giovanni.cassani AT uantwerpen DOT com

