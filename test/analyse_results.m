function analyse_results( results, times, min_index, max_index, test_path )
%CALC_RESULTS Summary of this function goes here
%   Detailed explanation goes here

    % Compute mean time.
    matching_time = zeros(max_index-min_index+1,1);
    filtering_time= zeros(max_index-min_index+1,1);
    ransac_time = zeros(max_index-min_index+1,1);
    for i = min_index:max_index
        matching_time(i) = times{i}.matching;
        filtering_time(i) = times{i}.filtering;
        ransac_time(i) = times{i}.ransac;
    end
    total = matching_time + filtering_time + ransac_time;
    fprintf('======= MEAN TIME : %f + %f + %f = %f =======\n', ...
        mean(matching_time), mean(filtering_time), mean(ransac_time), mean(total));

    % Compute precision and recall.
    gnd_truth = read_gnd_truth([test_path 'data.txt'], min_index, max_index);
    test_result = read_test_result(results);
    [precision, recall] = compute_p_r(gnd_truth, test_result, false);
    fprintf('======= RECALL = %f, PRECISION = %f =======\n', recall, precision);

end

