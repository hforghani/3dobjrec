function model = prepare_model(model, model_path)

N = size(model.points, 1);

for i = 1:N
    tic;
    point = model.points{i}.calc_descriptors([model_path 'db_img\'], model);
    model.points{i} = point;
    fprintf('Point %d with %d measurements prepared.\n', i, model.points{i}.measure_num);
    toc;
    if mod(i, 100) == 0
        save model;
    end
end
