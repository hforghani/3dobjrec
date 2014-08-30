function varargout = gen_test_man(varargin)
% GEN_TEST_MAN MATLAB code for gen_test_man.fig
%      GEN_TEST_MAN, by itself, creates a new GEN_TEST_MAN or raises the existing
%      singleton*.
%
%      H = GEN_TEST_MAN returns the handle to a new GEN_TEST_MAN or the handle to
%      the existing singleton*.
%
%      GEN_TEST_MAN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GEN_TEST_MAN.M with the given input arguments.
%
%      GEN_TEST_MAN('Property','Value',...) creates a new GEN_TEST_MAN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gen_test_man_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gen_test_man_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gen_test_man

% Last Modified by GUIDE v2.5 08-Jul-2014 16:04:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gen_test_man_OpeningFcn, ...
                   'gui_OutputFcn',  @gen_test_man_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before gen_test_man is made visible.
function gen_test_man_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gen_test_man (see VARARGIN)

% Choose default command line output for gen_test_man
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gen_test_man wait for user response (see UIRESUME)
% uiwait(handles.figure1);

global BKG_PATH IMAGE_HEIGHT IMAGE_WIDTH TEST_PATH BASE_PATH;
BKG_PATH = 'test_img/background/';
IMAGE_HEIGHT = 720;
IMAGE_WIDTH = 1280;
TEST_PATH = 'test_img/auto50_100/';
BASE_PATH = get_dataset_path();

% initializations:
folders = dir(BASE_PATH);
folders = folders(3:end);
obj_names = cell(size(folders));
for i = 1 : length(folders)
    obj_names{i} = folders(i).name;
end
set(handles.popupmenu1, 'String', obj_names);
set(handles.popupmenu2, 'String', obj_names);
set(handles.popupmenu3, 'String', obj_names);


backg_files = dir(BKG_PATH);
backg_files = backg_files(3:end);
str_arr = cell(numel(backg_files), 1);
for i = 1:numel(backg_files)
    str_arr{i} = backg_files(i).name;
end
set(handles.popupmenubkg, 'String', str_arr);

global bck_im obj_im obj_bw;
bck_im = uint8(zeros(IMAGE_HEIGHT, IMAGE_WIDTH, 3));
for i = 1:3
    obj_im{i} = uint8(zeros(IMAGE_HEIGHT, IMAGE_WIDTH, 3));
end
for i = 1:3
    obj_bw{i} = false(IMAGE_HEIGHT, IMAGE_WIDTH);
end

addpath model utils;

set_cameras(1, handles.popupmenu1, handles.editcam1);
set_cameras(2, handles.popupmenu2, handles.editcam2);
set_cameras(3, handles.popupmenu3, handles.editcam3);


% --- Outputs from this function are returned to the command line.
function varargout = gen_test_man_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1
set_cameras(1, hObject, handles.editcam1);



% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editz1_Callback(hObject, eventdata, handles)
% hObject    handle to editz1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editz1 as text
%        str2double(get(hObject,'String')) returns contents of editz1 as a double


% --- Executes during object creation, after setting all properties.
function editz1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editz1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editx1_Callback(hObject, eventdata, handles)
% hObject    handle to editx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editx1 as text
%        str2double(get(hObject,'String')) returns contents of editx1 as a double


% --- Executes during object creation, after setting all properties.
function editx1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editx1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edity1_Callback(hObject, eventdata, handles)
% hObject    handle to edity1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edity1 as text
%        str2double(get(hObject,'String')) returns contents of edity1 as a double


% --- Executes during object creation, after setting all properties.
function edity1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edity1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editd1_Callback(hObject, eventdata, handles)
% hObject    handle to editd1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editd1 as text
%        str2double(get(hObject,'String')) returns contents of editd1 as a double


% --- Executes during object creation, after setting all properties.
function editd1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editd1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2
set_cameras(2, hObject, handles.editcam2);


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editz2_Callback(hObject, eventdata, handles)
% hObject    handle to editz2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editz2 as text
%        str2double(get(hObject,'String')) returns contents of editz2 as a double


% --- Executes during object creation, after setting all properties.
function editz2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editz2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editx2_Callback(hObject, eventdata, handles)
% hObject    handle to editx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editx2 as text
%        str2double(get(hObject,'String')) returns contents of editx2 as a double


% --- Executes during object creation, after setting all properties.
function editx2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editx2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edity2_Callback(hObject, eventdata, handles)
% hObject    handle to edity2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edity2 as text
%        str2double(get(hObject,'String')) returns contents of edity2 as a double


% --- Executes during object creation, after setting all properties.
function edity2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edity2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editd2_Callback(hObject, eventdata, handles)
% hObject    handle to editd2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editd2 as text
%        str2double(get(hObject,'String')) returns contents of editd2 as a double


% --- Executes during object creation, after setting all properties.
function editd2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editd2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu3.
function popupmenu3_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu3 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu3
set_cameras(3, hObject, handles.editcam3);


% --- Executes during object creation, after setting all properties.
function popupmenu3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editz3_Callback(hObject, eventdata, handles)
% hObject    handle to editz3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editz3 as text
%        str2double(get(hObject,'String')) returns contents of editz3 as a double


% --- Executes during object creation, after setting all properties.
function editz3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editz3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editx3_Callback(hObject, eventdata, handles)
% hObject    handle to editx3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editx3 as text
%        str2double(get(hObject,'String')) returns contents of editx3 as a double


% --- Executes during object creation, after setting all properties.
function editx3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editx3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edity3_Callback(hObject, eventdata, handles)
% hObject    handle to edity3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edity3 as text
%        str2double(get(hObject,'String')) returns contents of edity3 as a double


% --- Executes during object creation, after setting all properties.
function edity3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edity3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function editd3_Callback(hObject, eventdata, handles)
% hObject    handle to editd3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editd3 as text
%        str2double(get(hObject,'String')) returns contents of editd3 as a double


% --- Executes during object creation, after setting all properties.
function editd3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editd3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in button1.
function button1_Callback(hObject, eventdata, handles)
% hObject    handle to button1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
add_object(1, handles.popupmenu1, handles.editcam1, handles.editd1, handles.editx1, handles.edity1, handles.editz1, handles.axes);



% --- Executes on button press in button2.
function button2_Callback(hObject, eventdata, handles)
% hObject    handle to button2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
add_object(2, handles.popupmenu2, handles.editcam2, handles.editd2, handles.editx2, handles.edity2, handles.editz2, handles.axes);


% --- Executes on button press in button3.
function button3_Callback(hObject, eventdata, handles)
% hObject    handle to button3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
add_object(3, handles.popupmenu3, handles.editcam3, handles.editd3, handles.editx3, handles.edity3, handles.editz3, handles.axes);


% --- Executes on selection change in popupmenubkg.
function popupmenubkg_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenubkg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenubkg contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenubkg


% --- Executes during object creation, after setting all properties.
function popupmenubkg_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenubkg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonbkg.
function buttonbkg_Callback(hObject, eventdata, handles)
% hObject    handle to buttonbkg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
str = get(handles.popupmenubkg, 'String');
val = get(handles.popupmenubkg, 'Value');
global BKG_PATH IMAGE_HEIGHT IMAGE_WIDTH bck_im;
bck_im = imread([BKG_PATH, str{val}]);
bck_im = imresize(bck_im, [IMAGE_HEIGHT, IMAGE_WIDTH]);
render_im(handles.axes);


function editcam1_Callback(hObject, eventdata, handles)
% hObject    handle to editcam1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editcam1 as text
%        str2double(get(hObject,'String')) returns contents of editcam1 as a double


% --- Executes during object creation, after setting all properties.
function editcam1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editcam1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editcam3_Callback(hObject, eventdata, handles)
% hObject    handle to editcam3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editcam3 as text
%        str2double(get(hObject,'String')) returns contents of editcam3 as a double


% --- Executes during object creation, after setting all properties.
function editcam3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editcam3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
    
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function editcam2_Callback(hObject, eventdata, handles)
% hObject    handle to editcam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editcam2 as text
%        str2double(get(hObject,'String')) returns contents of editcam2 as a double


% --- Executes during object creation, after setting all properties.
function editcam2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editcam2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in buttonsave.
function buttonsave_Callback(hObject, eventdata, handles)
% hObject    handle to buttonsave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global TEST_PATH obj_bw;
data_fname = [TEST_PATH 'data.txt'];
cur_test_count = numel(dir(TEST_PATH)) - 2;
if exist(data_fname, 'file') > 0
    cur_test_count = cur_test_count - 1;
end
name_number = num2str(cur_test_count + 1);
fname = [repmat('0', 1,3-length(name_number)) , name_number, '.jpg'];

obj_count = 0;
test_obj_names = '';
pupops = {handles.popupmenu1, handles.popupmenu2, handles.popupmenu3};
for i = 1:3
    if any(any(obj_bw{i}))
        obj_count = obj_count + 1;
        str = get(pupops{i}, 'String');
        val = get(pupops{i}, 'Value');
        test_obj_names = [test_obj_names ' ' str{val}];
    end
end

im = render_im(handles.axes);
imwrite(im, [TEST_PATH fname]);
fid = fopen(data_fname, 'a');
fprintf(fid, '%s\n%d%s\n', fname, obj_count, test_obj_names);
fclose(fid);



function im = render_im(axes)
global bck_im obj_im obj_bw;
im = bck_im;
for i = 1:3
    obj_imi = obj_im{i};
    obj_bwi = obj_bw{i};
    for c = 1:3
        ch_obj = obj_imi(:,:,c); ch_im = im(:,:,c);
        ch_im(obj_bwi) = ch_obj(obj_bwi); im(:,:,c) = ch_im;
    end
end
imshow(im, 'Parent', axes);



function add_object(index, popupmenu, editcam, editd, editx, edity, editz, axes)

fprintf('rendering object %d ... ', index);

global BASE_PATH;

str = get(popupmenu, 'String');
val = get(popupmenu, 'Value');
model_path = [BASE_PATH str{val} '\'];
load (['data/model/' str{val}]);

cam_f_index = round(get(editcam, 'Value'));
global camera_fnames obj_im obj_bw;
fname = camera_fnames{index}{cam_f_index};
for i = 1:length(model.cameras)
    if strcmp(model.cameras{i}.file_name, fname)
        cam_index = i;

        depth_mult = get(editd, 'Value');
        phi_x = get(editx, 'Value');
        phi_y = get(edity, 'Value');
        phi_z = get(editz, 'Value');

        [obj_im1, bw1, R, T] = apply_homo(model, model_path, cam_index, depth_mult, phi_x, phi_y, phi_z);
        obj_im{index} = obj_im1;
        obj_bw{index} = bw1;

        render_im(axes);
    end
end

fprintf('done\n');




function set_cameras(index, popupmenu, editcam)

str = get(popupmenu, 'String');
val = get(popupmenu, 'Value');

global BASE_PATH;
cam_files = dir([BASE_PATH str{val} '\db_img\']);
cam_files = cam_files(3:end);
str_arr = cell(numel(cam_files), 1);
for i = 1:numel(cam_files)
    str_arr{i} = cam_files(i).name;
end
global camera_fnames;
camera_fnames{index} = str_arr;

set(editcam, 'Max', length(cam_files));


% --- Executes on button press in buttonclear1.
function buttonclear1_Callback(hObject, eventdata, handles)
% hObject    handle to buttonclear1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global obj_bw IMAGE_HEIGHT IMAGE_WIDTH;
obj_bw{1} = false(IMAGE_HEIGHT, IMAGE_WIDTH);
render_im(handles.axes);

% --- Executes on button press in buttonclear2.
function buttonclear2_Callback(hObject, eventdata, handles)
% hObject    handle to buttonclear2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global obj_bw IMAGE_HEIGHT IMAGE_WIDTH;
obj_bw{2} = false(IMAGE_HEIGHT, IMAGE_WIDTH);
render_im(handles.axes);


% --- Executes on button press in buttonclear3.
function buttonclear3_Callback(hObject, eventdata, handles)
% hObject    handle to buttonclear3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global obj_bw IMAGE_HEIGHT IMAGE_WIDTH;
obj_bw{3} = false(IMAGE_HEIGHT, IMAGE_WIDTH);
render_im(handles.axes);
