clearvars;
obj_names = {'alphonse_elric', 'anakin_skywalker', 'ankylosaurus_brown', 'ankylosaurus_green', ...
    'ankylosaurus_olive', 'anteater', 'antelope', 'appaloosa_horse', 'armor_hunter', ...
    'bactrian_camel', 'baryonyx'};

for i = 1:length(obj_names)
    prepare_model(obj_names{i});
end
