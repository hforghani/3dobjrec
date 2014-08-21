clearvars;

folders = dir(get_dataset_path());
folders = folders(3:end);

result_name = 'all10_2';
count = 10;
% indexes = 1 : count;
indexes = zeros(1, count);
all_indexes = 1 : 50;
for i = 1 : count
    ri = randi(50 - i + 1);
    indexes(i) = all_indexes(ri);
    all_indexes(ri) = [];
end

obj_names = cell(length(indexes), 1);
for i = 1 : length(indexes)
    obj_name = folders(indexes(i)).name;
    obj_names{i} = obj_name;
end

descriptors = [];
desc_point_indexes = [];
desc_model_indexes = [];

for i = 1 : length(obj_names)
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
