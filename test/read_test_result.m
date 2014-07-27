function res = read_test_result(res_fname)
% res:  cell array in which each element is result of a test image. Each
%       element is a struct with the properties: objcount, objnames,
%       transforms

load(res_fname, 'results');
res = cell(length(results), 1);

for i = 1 : length(res)
    item.objcount = length(results{i});
    item.objnames = cell(item.objcount, 1);
    item.transforms = cell(item.objcount, 1);
    for j = 1 : item.objcount
        item.objnames{j} = results{i}{j}.obj_name;
        item.transforms{j} = results{i}{j}.transform;
    end    
    res{i} = item;
end
