function test_data = read_test_data(data_fname)

fid = fopen(data_fname);
test_data = {};

while 1
    item.fname = fscanf(fid, '%s\n', 1);
    item.objcount = fscanf(fid, '%d');
    if isempty(item.fname)
        break;
    end
    item.objnames = cell(item.objcount, 1);
    for i = 1:item.objcount
        item.objnames{i} = fscanf(fid, ' %s', 1);
    end
    test_data = [test_data; {item}];
end

fclose(fid);
