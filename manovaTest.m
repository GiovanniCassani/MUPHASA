function [sig, pval, mahalDist] = manovaTest(group1, group2, labels)
% Given two samples and a cell containing two strings, the function
% performS a one-way MANOVA. For explanations about the outputs check the
% doc of the manova1 function.

[rows1, ~] = size(group1);
[rows2, ~] = size(group2);

label1 = cell(rows1,1);
label2 = cell(rows2,1);

for i = 1:length(label1)
    label1{i,1} = labels{1};
end

for j = 1:length(label2)
    label2{j,1} = labels{2};
end

sample = vertcat(group1, group2);
labelsVec = vertcat(label1, label2);

[sig, pval, stats] = manova1(sample, labelsVec);

mahalDist = stats.gmdist;

end

