function res = read_test_result(result_path, method, test_data)

res = cell(length(test_data), 1);

for i = 1 : length(test_data)
    switch method
        case 'gm'
            suffix = '_gr';
        case 'filter'
            suffix = '';
    end
    fname = [result_path 'res_' test_data{i}.fname(1:end-4) suffix '.txt'];
    if ~exist(fname, 'file')
        continue;
    end
    fid = fopen(fname);
    fgetl(fid);
    item.objcount = fscanf(fid, '%d');
    item.objnames = cell(item.objcount, 1);
    for j = 1 : item.objcount
        item.objnames{j} = fscanf(fid, '%s', 1);
    end
    res{i} = item;
    fclose(fid);
end
