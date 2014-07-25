function [precision, recall] = compute_p_r(test_data, test_result, interactive)

if nargin == 2
    interactive = 0;
end

test_count = 0;
true_count = 0;
false_count = 0;
for i = 1 : length(test_data)
    if ~isempty(test_result{i})
        test_count = test_count + test_data{i}.objcount;
        for j = 1 : test_result{i}.objcount
            name = test_result{i}.objnames{j};
            istrue = false;
            for k = 1 : test_data{i}.objcount
                if strcmp(name, test_data{i}.objnames{k})
                    istrue = true;
                end
            end
            if istrue
                true_count = true_count + 1;
            else
                false_count = false_count + 1;
                if interactive
                    fprintf('false positive: %s in %s\n', name, test_data{i}.fname);
                end
            end
        end
        if interactive
            for j = 1 : test_data{i}.objcount
                found = false;
                for k = 1 : test_result{i}.objcount
                    if strcmp(test_data{i}.objnames{j}, test_result{i}.objnames{k})
                        found = true;
                        break;
                    end
                end
                if ~found
                    fprintf('false negative: %s in %s\n', test_data{i}.objnames{j}, test_data{i}.fname);
                end
            end
        end
    end
end

recall = true_count / test_count;
precision = true_count / (true_count + false_count);