function [precision, recall] = compute_p_r(gnd_truth, test_result, obj_names, interactive)

if nargin == 2
    interactive = 0;
end

T = 0; % true
TP = 0; % true positive
FP = 0; % false positive

for i = 1 : length(gnd_truth)
    if ~isempty(test_result{i})
        true_count = sum(ismember(gnd_truth{i}.objnames, obj_names));
        T = T + true_count;
        
        for j = 1 : test_result{i}.objcount
            name = test_result{i}.objnames{j};
            if ismember(name, gnd_truth{i}.objnames)
                TP = TP + 1;
            else
                FP = FP + 1;
                if interactive
                    fprintf('false positive: %s in %s\n', name, gnd_truth{i}.fname);
                end
            end
        end
        
        if interactive
            for j = 1 : gnd_truth{i}.objcount
                name = gnd_truth{i}.objnames{j};
                if ~ismember(name, obj_names) && ...
                        isempty(find(ismember(test_result{i}.objnames, name), 1))
                    fprintf('false negative: %s in %s\n', gnd_truth{i}.objnames{j}, gnd_truth{i}.fname);
                end
            end
        end
    end
end

recall = TP / T;
precision = TP / (TP + FP);
