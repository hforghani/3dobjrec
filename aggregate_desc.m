clearvars;

obj_names = {'airborne_soldier', 'alex_row', 'alphonse_elric', 'anakin_skywalker', ...
    'anchiceratops', 'ankylosaurus_brown', 'ankylosaurus_green', 'ankylosaurus_olive', ...
    'anteater', 'antelope', 'appaloosa_horse', 'armor_hunter', 'axe_knight', ...
    'bactrian_camel', 'baryonyx'};
result_name = 'all15';

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
