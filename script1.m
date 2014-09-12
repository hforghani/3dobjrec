clearvars;
% close all;

% case_names = {'all10', 'all20', 'all30', 'all40', 'all50', 'all10a'};
% test_paths = {'test_img/auto10/', 'test_img/auto20/', 'test_img/auto30/', ...
%     'test_img/auto40/', 'test_img/auto50/', 'test_img/auto50/'};

case_names = {'all10a', 'all20', 'all30', 'all40', 'all50'};
test_paths = {'test_img/auto50_112/', ...
            'test_img/auto50_112/', ...
            'test_img/auto50_112/', ...
            'test_img/auto50_112/', ...
            'test_img/auto50_112/'};

methods = {
    {'hao', 'hao', 45} ...
    ,{'gradient', 'hao', 30} ...
    ,{'hao', 'geomGradient', 30} ...
    ,{'gradient', 'geomGradient', 30} ...
    ,{'hao', 'angle', 22} ...
    ,{'gradient', 'angle', 22} ...
    };

% methods = {
%             {'sm', 'exhaust', 30}, ...
%             {'ipfp', 'exhaust', 20}, ...
%             {'rrwm', 'exhaust', 25}, ...
%             {'gradient', 'exhaust', 20}};

% methods = {{'gradient', 'hao', 35}, ...
%             {'gradient', 'geomGradient', 30}, ...
%             {'gradient', 'angle', 22}};        

warning('OFF', 'all');

% indexes = randperm(106, 20);
indexes = 1 : 106;
% indexes = [44    76    18    29     7     6    12    48    41    98    27     1    88   86    79    20    60     4    46   105];
cases = 5;

colors = 'rgbcmykw';

for i = 6
    m = methods{i};
    options.local = m{1};
    options.global = m{2};
    options.min_inl_count = m{3};
    
    recalls = zeros(length(cases),1);
    for j = cases
        res1 = test(case_names{j}, test_paths{j}, true, false, indexes, 2, options);
%         res2 = test(case_names{j}, test_paths{j}, true, true, indexes, 1, options);
%         res3 = test(case_names{j}, test_paths{j}, true, true, indexes, 1, options);

%         recalls(j) = mean([res2.recall, res3.recall]);
    end
    
    figure(1);
    plot(cases, recalls, [colors(i) 'o-']);
    hold on;
    
    fprintf('\n\n');
end

warning('ON', 'all');
