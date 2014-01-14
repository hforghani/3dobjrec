function model = prepare_model(model, model_path)

points = model.points;
N = size(points, 1);

for i = 1:N
    tic;
    points{i}.calc_descriptors([model_path 'db_img\'], model);
    fprintf('Point %d with %d measurements prepared.\n', i, points{i}.measure_num);
    toc;
end
