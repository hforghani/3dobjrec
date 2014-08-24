clearvars;

case_names = {'all10', 'all20', 'all30', 'all40', 'all50'};
test_paths = {'test_img/auto10/', 'test_img/auto20/', 'test_img/auto30/', ...
    'test_img/auto40/', 'test_img/auto50/'};

methods = {
    {'hao', 'hao', 13} ...
    ,{'gradient', 'hao', 14} ...
    ,{'hao', 'geomGradient', 14} ...
    ,{'gradient', 'geomGradient', 15} ...
    ,{'gradient', 'angle', 15} ...
    ,{'hao', 'angle', 14}
    };

% methods = {{'hao', 'exhaust', 7}, ...
%             {'sm', 'exhaust', 7}, ...
%             {'ipfp', 'exhaust', 7}, ...
%             {'rrwm', 'exhaust', 7}, ...
%             {'gradient', 'exhaust', 7}};

warning('OFF', 'all');

for i = 1 : 1
    m = methods{i};
    options.local = m{1};
    options.global = m{2};
    options.min_inl_count = m{3};
    for j = 1 : 1
        test(case_names{j}, test_paths{j}, true, true, 1, 8, 1, options);
%         test(case_names{j}, test_paths{j}, true, true, 1, 50, 1, options);
    end
end

warning('ON', 'all');
