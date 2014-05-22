clearvars;
obj_names = {'airborne_soldier', 'alex_row', 'alphonse_elric', 'anakin_skywalker', ...
    'anchiceratops', 'ankylosaurus_brown', 'ankylosaurus_green', 'ankylosaurus_olive', ...
    'anteater', 'antelope', 'appaloosa_horse', 'armor_hunter', 'axe_knight', ...
    'bactrian_camel', 'baryonyx'};

for i = 1:length(obj_names)
    fprintf('preparing model "%s"\n', obj_names{i});
    prepare_model(obj_names{i});
end
