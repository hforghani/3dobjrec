clearvars;

options.local = 'gradient';
options.global = 'angle';
options.min_inl_count = 10;

% for i = 0.4 : 0.2 : 2
%     i = 1.6;
%     fprintf('******* sigma_mult_3d = %f *******\n', i);
%     options.sigma_mult_3d = i;
    test('all30', 'test_img/auto30/', true, false, 1, 50, 1, options);
    test('all30', 'test_img/auto30/', true, true, 1, 50, 1, options);
    test('all30', 'test_img/auto30/', true, true, 1, 50, 1, options);
% end
