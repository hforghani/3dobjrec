model_fnames = {'data/model_desc_anchi', 'data/model_desc_axe_knight'};

descriptors = [];
desc_point_indexes = [];
for i = 1:length(model_fnames)
	model_desc = load(model_fnames{i});
	descriptors = [descriptors, model_desc.descriptors];
	desc_point_indexes = [desc_point_indexes, model_desc.desc_point_indexes];
	clear model_desc;
end
kdtree = vl_kdtreebuild(double(descriptors));

save('data/model_desc_aggr', 'descriptors', 'desc_point_indexes', 'kdtree');