function gnd_truth = read_gnd_truth(data_fname, min_index, max_index)
% test_data:    cell array in which each element is ground truth of a test 
%               image. Each element is a struct with the properties: 
%               objcount, objnames

fid = fopen(data_fname);
gnd_truth = cell(max_index - min_index + 1, 1);
i = 1;

while i <= max_index
    item.fname = fscanf(fid, '%s\n', 1);
    item.objcount = fscanf(fid, '%d');
    if isempty(item.fname)
        break;
    end
    item.objnames = cell(item.objcount, 1);
    for j = 1:item.objcount
        item.objnames{j} = fscanf(fid, ' %s', 1);
    end
    
    if i >= min_index
        gnd_truth{i - min_index + 1} = item;
    end
    
    i = i + 1;
end

fclose(fid);
