function create_ply(transforms, rec_indexes, obj_names, fname)

    poses = [];
    for i = 1:length(rec_indexes)
        model_f_name = ['data/model/' obj_names{rec_indexes(i)}];
        model = load(model_f_name);
        model = model.model;
        
        t = transforms{i};
        rotation_mat = t(:,1:3);
        translation_mat = t(:,4);

        points3d = model.transform_points(rotation_mat, translation_mat);
        poses = [poses, points3d];
        
        clear model;
    end
    
    poses_num = size(poses, 2);
    
    fid = fopen(fname, 'w');
    fprintf(fid, 'ply\n');
    fprintf(fid, 'format ascii 1.0\n');
    fprintf(fid, 'element vertex %d\n', poses_num);
    fprintf(fid, 'property float x\n');
    fprintf(fid, 'property float y\n');
    fprintf(fid, 'property float z\n');
    fprintf(fid, 'end_header\n');
    for i = 1:poses_num
        p = poses(:, i);
        fprintf(fid, '%f %f %f\n', p(1), p(2), p(3));
    end
    fclose(fid);
    
end
