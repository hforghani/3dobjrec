obj_names = {'anchiceratops', 'axe_knight'};

descriptors = [];
desc_point_indexes = [];
desc_model_indexes = [];

for i = 1:length(obj_names)
    obj_name = obj_names{i};
    desc_model_fname = ['data/model_desc_' obj_name];
    model_desc = load(desc_model_fname);
    descriptors = [descriptors, model_desc.descriptors];
    desc_point_indexes = [desc_point_indexes, model_desc.desc_point_indexes];
    desc_count = length(model_desc.desc_point_indexes);
    desc_model_indexes = [desc_model_indexes, ones(1,desc_count) * i];
    
    clear model_desc;
end

kdtree = vl_kdtreebuild(double(descriptors));

save('data/model_desc_all', 'descriptors', 'desc_point_indexes', 'desc_model_indexes', 'kdtree');