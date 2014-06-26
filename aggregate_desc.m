clearvars;

base_path = [get_dataset_path() '0-24(1)\0-24\'];
folders = dir(base_path);
folders = folders(3:end);

result_name = 'all25';
start_i = 1;
end_i = length(folders);
% end_i = 10;

obj_names = cell(end_i - start_i + 1, 1);
for i = start_i:end_i
    obj_name = folders(i).name;
    obj_names{i} = obj_name;
end

descriptors = [];
desc_point_indexes = [];
desc_model_indexes = [];

for i = 1:length(obj_names)
    fprintf('adding object %d ... ', i);
    obj_name = obj_names{i};
    desc_model_fname = ['data/model_desc/' obj_name];
    model_desc = load(desc_model_fname);
    descriptors = [descriptors, model_desc.descriptors];
    desc_point_indexes = [desc_point_indexes, model_desc.desc_point_indexes];
    desc_count = length(model_desc.desc_point_indexes);
    desc_model_indexes = [desc_model_indexes, ones(1,desc_count) * i];
    
    clear model_desc;
    fprintf('done\n');
end

fprintf('building kd-tree ... ');
kdtree = vl_kdtreebuild(double(descriptors));
fprintf('done\n');

fprintf('saving ... ');
save(['data/model_desc/' result_name], ...
    'descriptors', 'desc_point_indexes', 'desc_model_indexes', 'kdtree', 'obj_names');
fprintf('done\n');
