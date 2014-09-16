function timing = analyse_time( times, indexes )

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

end

