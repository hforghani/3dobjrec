function varargout = test_cameras(varargin)
% TEST_CAMERAS MATLAB code for test_cameras.fig
%      TEST_CAMERAS, by itself, creates a new TEST_CAMERAS or raises the existing
%      singleton*.
%
%      H = TEST_CAMERAS returns the handle to a new TEST_CAMERAS or the handle to
%      the existing singleton*.
%
%      TEST_CAMERAS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEST_CAMERAS.M with the given input arguments.
%
%      TEST_CAMERAS('Property','Value',...) creates a new TEST_CAMERAS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before test_cameras_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to test_cameras_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help test_cameras

    % Last Modified by GUIDE v2.5 06-Jun-2014 21:58:19

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @test_cameras_OpeningFcn, ...
                       'gui_OutputFcn',  @test_cameras_OutputFcn, ...
                       'gui_LayoutFcn',  [] , ...
                       'gui_Callback',   []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end

    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
    
    addpath('..\');
    addpath('..\model');
    % End initialization code - DO NOT EDIT


% --- Executes just before test_cameras is made visible.
function test_cameras_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to test_cameras (see VARARGIN)

    % Choose default command line output for test_cameras
    handles.output = hObject;

    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes test_cameras wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
    addpath model;
    global cam_index model_path model;
    cam_index = 1;

    model_path = [get_dataset_path() '0-24(1)\0-24\anchiceratops\'];
    model_fname = '..\data\model\anchiceratops';
    container = load(model_fname);
    model = container.model;

    show_camera(cam_index, handles.axes1);
    set(handles.index_edit, 'String', num2str(cam_index));
    set(handles.total_count_text, 'String', ['/ ' num2str(length(model.cameras))]);


% --- Outputs from this function are returned to the command line.
function varargout = test_cameras_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
    varargout{1} = handles.output;


% --- Executes on button press in prev_button.
function prev_button_Callback(hObject, eventdata, handles)
% hObject    handle to next_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global cam_index;
    if cam_index <= 1
        return;
    end
    cam_index = cam_index - 1;
    set(handles.index_edit, 'String', num2str(cam_index))
    show_camera(cam_index, handles.axes1);
    

% --- Executes on button press in next_button.
function next_button_Callback(hObject, eventdata, handles)
% hObject    handle to prev_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global cam_index model;
    if cam_index >= length(model.cameras)
        return;
    end
    cam_index = cam_index + 1;
    set(handles.index_edit, 'String', num2str(cam_index))
    show_camera(cam_index, handles.axes1);


function show_camera(cam_i, axes)
    global model_path model;
    
    cam = model.cameras{cam_i};
    [features, measurements] = cam.get_points_poses(model.points, model.calibration);
    im = cam.get_image(model_path);
    f_num = size(features, 2);
    cal = model.calibration;
    center = [cal.cx; cal.cy];
    
    imshow(im, 'Parent', axes)
    hold on;
    scatter(center(1), center(2), 100 , 'r+');
    scatter(features(1,:), features(2,:), ones(1,f_num)*20 , 'y');

    for i = 1:f_num
        text(features(1,i), features(2,i), num2str(measurements{i}.point_index), 'Color', 'r');
    end



function index_edit_Callback(hObject, eventdata, handles)
% hObject    handle to index_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of index_edit as text
%        str2double(get(hObject,'String')) returns contents of index_edit as a double


% --- Executes during object creation, after setting all properties.
function index_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to index_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

% --- Executes on button press in show_button.
function show_button_Callback(hObject, eventdata, handles)
% hObject    handle to show_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    cam_i = str2double(get(handles.index_edit, 'String'));
    show_camera(cam_i, handles.axes1);
    global cam_index;
    cam_index = cam_i;
