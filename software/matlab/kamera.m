function varargout = kamera(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @kamera_OpeningFcn, ...
                   'gui_OutputFcn',  @kamera_OutputFcn, ...
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



function kamera_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
% handles.images = imread('img.jpg');
% imshow(handles.images);


set(hObject, 'Units', 'pixels');
handles.banner = imread('img.jpg');
info = imfinfo('img.jpg');
position = get(hObject, 'Position');
set(hObject, 'Position', [position(1:2) info.Width + 100 info.Height + 100]);
axes(handles.axes3);

image(handles.banner);



guidata(hObject, handles);


function varargout = kamera_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
handles.images = imread('img3.jpg');
imshow(handles.images);
