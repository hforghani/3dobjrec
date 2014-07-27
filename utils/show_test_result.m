function show_test_result(test_path, models, obj_names, gnd_truth, test_res)

for i = 1 : length(test_res)
    res_item = test_res{i};
    gnd_item = gnd_truth{i};
    if isempty(res_item); continue; end
    
    q_im_name = [test_path gnd_item.fname];
    image = imread(q_im_name);
    figure; imshow(image); hold on;
    
    for j = 1 : res_item.objcount
        objname = res_item.objnames{j};
        [~, index] = ismember(objname, obj_names);
        model = models{index};
        
        % Map points with the found transformation.
        trans = res_item.transforms{j};
        R = trans(:, 1:3);
        T = trans(:, 4);
        points2d = model.project_to_img_plane(R, T);
        
        if ismember(objname, gnd_item.objnames)
            color = 'g';
        else
            color = 'r';
        end
        scatter(points2d(1,:), points2d(2,:), 5, 'filled', 'MarkerFaceColor', color);
    end
    
%     for j = 1 : gnd_item.objcount
%         if ~ismember(gnd_item.objnames{j}, res_item.objnames)
%             model = models{find(obj_names, gnd_item.objnames{j})};
% 
%             % Map points with the found transformation.
%             points2d = model.project_to_img_plane(R, T);
% 
%             scatter(points2d(1,:), points2d(2,:), 5, 'filled', 'MarkerFaceColor', 'r');            
%         end
%             
%     end
end

