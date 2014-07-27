function [precision, recall] = compute_p_r(gnd_truth, test_result, interactive)

if nargin == 2
    interactive = 0;
end

test_count = 0;
true_count = 0;
false_count = 0;
for i = 1 : length(gnd_truth)
    if ~isempty(test_result{i})
        test_count = test_count + gnd_truth{i}.objcount;
        for j = 1 : test_result{i}.objcount
            name = test_result{i}.objnames{j};
            istrue = false;
            for k = 1 : gnd_truth{i}.objcount
                if strcmp(name, gnd_truth{i}.objnames{k})
                    istrue = true;
                end
            end
            if istrue
                true_count = true_count + 1;
            else
                false_count = false_count + 1;
                if interactive
                    fprintf('false positive: %s in %s\n', name, gnd_truth{i}.fname);
                end
            end
        end
        if interactive
            for j = 1 : gnd_truth{i}.objcount
                found = false;
                for k = 1 : test_result{i}.objcount
                    if strcmp(gnd_truth{i}.objnames{j}, test_result{i}.objnames{k})
                        found = true;
                        break;
                    end
                end
                if ~found
                    fprintf('false negative: %s in %s\n', gnd_truth{i}.objnames{j}, gnd_truth{i}.fname);
                end
            end
        end
    end
end

recall = true_count / test_count;
precision = true_count / (true_count + false_count);
