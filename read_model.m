function model = read_model(model_fname)
% Read data from model file and read the model.

fid = fopen(model_fname);

%% Read cameras data.

fscanf(fid, '%s', 2);
fx = fscanf(fid, '%f', 1);
cx = fscanf(fid, '%f', 1);
fy = fscanf(fid, '%f', 1);
cy = fscanf(fid, '%f', 1);
calibration = Calibration(fx, cx, fy, cy);

camera_num = fscanf(fid, '%d', 1);
cameras = cell(camera_num, 1);
for i = 1:camera_num
    file_name = fscanf(fid, '%s', 1);
    focal_length = fscanf(fid, '%f', 1);
    q_rotation = fscanf(fid, '%f', 4);
    center = fscanf(fid, '%f', 3);
    r_distortion = fscanf(fid, '%f', 2);
    fgetl(fid);

    cameras{i} = Camera(file_name, focal_length, q_rotation, center, r_distortion);
end

%% Read points data.
points_num = fscanf(fid, '%d', 1);
points = cell(points_num,1);
for i = 1:points_num
    pos = fscanf(fid, '%f', 3);
    color = fscanf(fid, '%f', 3);
    measure_num = fscanf(fid, '%d', 1);
    measurements = cell(measure_num, 1);
    for j = 1:measure_num
        image_index = fscanf(fid, '%d', 1) + 1;
        feature_index = fscanf(fid, '%d', 1);
        pos_in_image = fscanf(fid, '%f', 2);
        measurements{j} = Measurement(image_index, feature_index, pos_in_image);
    end
    points{i} = Point(pos, color, measure_num, measurements);
end

fclose(fid);

model = Model(calibration, cameras, points);
