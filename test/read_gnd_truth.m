function gnd_truth = read_gnd_truth(data_fname, indexes)
% test_data:    cell array in which each element is ground truth of a test 
%               image. Each element is a struct with the properties: 
%               objcount, objnames

fid = fopen(data_fname);
all_gnd_truth = cell(length(indexes), 1);
i = 1;

while i <= max(indexes)
    item.fname = fscanf(fid, '%s\n', 1);
    item.objcount = fscanf(fid, '%d');
    if isempty(item.fname)
        break;
    end
    item.objnames = cell(item.objcount, 1);
    for j = 1:item.objcount
        item.objnames{j} = fscanf(fid, ' %s', 1);
    end
    
    all_gnd_truth{i} = item;
    i = i + 1;
end

fclose(fid);

gnd_truth = all_gnd_truth(indexes);
