function [precision, recall, timing] = analyse_results( test_res, gnd_truth, times, case_name, test_path, indexes )
%CALC_RESULTS Summary of this function goes here
%   Detailed explanation goes here

    desc_model_f_name = ['data/model_desc/' case_name];
    load(desc_model_f_name, 'obj_names');
    
    % Compute mean time.
    matching_time = zeros(length(indexes),1);
    filtering_time= zeros(length(indexes),1);
    ransac_time = zeros(length(indexes),1);
    for i = 1 : length(indexes)
        matching_time(i) = times{i}.matching;
        filtering_time(i) = times{i}.filtering;
        ransac_time(i) = times{i}.ransac;
    end
	timing.matching = mean(matching_time);
	timing.filtering = mean(filtering_time);
	timing.ransac = mean(ransac_time);
	timing.total = timing.matching + timing.filtering + timing.ransac;

    % Compute precision and recall.
%     test_result = read_test_result(test_res);
    [precision, recall] = compute_p_r(gnd_truth, test_res, obj_names, false);
 
end

