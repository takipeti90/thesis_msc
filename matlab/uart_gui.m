function varargout = uart_gui(varargin)
% UART_GUI MATLAB code for uart_gui.fig
%      UART_GUI, by itself, creates a new UART_GUI or raises the existing
%      singleton*.
%
%      H = UART_GUI returns the handle to a new UART_GUI or the handle to
%      the existing singleton*.
%
%      UART_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in UART_GUI.M with the given input arguments.
%
%      UART_GUI('Property','Value',...) creates a new UART_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before uart_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to uart_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help uart_gui

% Last Modified by GUIDE v2.5 08-Jun-2015 15:51:57

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @uart_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @uart_gui_OutputFcn, ...
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

%-------------------------------------------------------------------------------------------------------

% --- Executes just before uart_gui is made visible.
function uart_gui_OpeningFcn(hObject, eventdata, handles, varargin)
serialPorts = instrhwinfo('serial');
% nPorts = length(serialPorts.SerialPorts);
set(handles.port_select, 'String',[{'Select a port'} ; serialPorts.SerialPorts ]);
%set(handles.port_select, 'Value', 2);   
set(handles.recieve_box, 'String', cell(1));
global baud
baud = '115200';
global databits
databits = '8';
global stopbits
stopbits = '1';
% set(handles.send_button, 'Enable', 'Off');
% Choose default command line output for uart_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
% UIWAIT makes uart_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);
% --- Outputs from this function are returned to the command line.
function varargout = uart_gui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

%-------------------------------------------------------------------------------------------------------

% --- Executes on selection change in port_select.
function port_select_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function port_select_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function baud_set_Callback(hObject, eventdata, handles)
global baud
baud = get(handles.baud_set,'String');
if str2num(baud) ~= 115200
    set(handles.error_text,'String','wrong baud rate');
else
    set(handles.error_text,'String','');
end
% --- Executes during object creation, after setting all properties.
function baud_set_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function stopbit_set_Callback(hObject, eventdata, handles)
global stopbits
stopbits = get(handles.stopbit_set,'String');
if str2num(stopbits) ~= 1
    set(handles.error_text,'String','wrong stop bits');
else
    set(handles.error_text,'String','');
end
% --- Executes during object creation, after setting all properties.
function stopbit_set_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function databits_set_Callback(hObject, eventdata, handles)
global databits
databits = get(handles.databits_set,'String');
if str2num(databits) ~= 8
    set(handles.error_text,'String','wrong data bits');
else
    set(handles.error_text,'String','');
end
% --- Executes during object creation, after setting all properties.
function databits_set_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

% --- Executes on button press in connect_button.
function connect_button_Callback(hObject, eventdata, handles)
global baud
global databits
global stopbits
bytesToRead = 1;
if (strcmp(get(handles.connect_button,'String'),'CONNECT'))
    serPortn = get(handles.port_select, 'Value');
    if (str2num(baud)==115200 & str2num(databits)==8 & str2num(stopbits)==1 & serPortn~=1)
        serList = get(handles.port_select,'String');
        serPort = serList{serPortn};
        serial_connection = serial(serPort,'BaudRate',str2num(baud),'DataBits',str2num(databits),'StopBits',str2num(stopbits));
                
        serial_connection.BytesAvailableFcnCount = 50;
        serial_connection.BytesAvailableFcnMode = 'byte';
%         serial_connection.Terminator = 'CR/LF';
%         serial_connection.BytesAvailableFcnMode = 'terminator';
        handles.serial_connection = serial_connection;
        serial_connection.BytesAvailableFcn = {@serialRead,handles};
%         get(serial_connection)
        try
            fopen(serial_connection);
        catch e
            errordlg(e.message);            
        end
        set(handles.connect_button,'String','DISCONNECT');
        set(handles.send_button, 'Enable', 'On');
        set(handles.balra, 'Enable', 'On');
        set(handles.elore, 'Enable', 'On');
        set(handles.jobbra, 'Enable', 'On');
        set(handles.hatra, 'Enable', 'On');
        set(handles.stop, 'Enable', 'On');
        set(handles.kamerabal, 'Enable', 'On');
        set(handles.kamerajobb, 'Enable', 'On');
        set(handles.send_box, 'Enable', 'On');
        set(handles.baud_set, 'Enable', 'Off');
        set(handles.databits_set, 'Enable', 'Off');
        set(handles.stopbit_set, 'Enable', 'Off');
        set(handles.port_select, 'Enable', 'Off');
        set(handles.error_text,'String','');
    else
        set(handles.error_text,'String','wrong serial port settings');
    end
else
    set(handles.connect_button,'String','CONNECT');
    set(handles.send_button, 'Enable', 'Off');
    set(handles.send_box, 'Enable', 'Off');
    set(handles.balra, 'Enable', 'Off');
    set(handles.elore, 'Enable', 'Off');
    set(handles.jobbra, 'Enable', 'Off');
    set(handles.hatra, 'Enable', 'Off');
    set(handles.stop, 'Enable', 'Off');
    set(handles.kamerabal, 'Enable', 'Off');
    set(handles.kamerajobb, 'Enable', 'Off');
    set(handles.baud_set, 'Enable', 'On');
    set(handles.databits_set, 'Enable', 'On');
    set(handles.stopbit_set, 'Enable', 'On');
    set(handles.port_select, 'Enable', 'On');
    fclose(handles.serial_connection);
    handles = rmfield(handles,'serial_connection');
end
guidata(hObject, handles);

%-------------------------------------------------------------------------------------------------------

function serialRead(hObject, eventdata, handles)
bytesAvailable = hObject.BytesAvailable;
if (bytesAvailable)
    %RxText = fscanf(hObject,'%s',bytesAvailable);  % read ASCII data
    rxin = fread(hObject,bytesAvailable);  % read binary data
    RxText = rxin';
    if (RxText(1) == '#')
        if (RxText(21) == '1')
            set(handles.gpsaktiv,'Value',1);
            set(handles.gpsaktiv,'String','GPS AKTÍV');
        end
        set(handles.szelesseg, 'String',native2unicode(RxText(2:10)))
        set(handles.hosszusag, 'String',native2unicode(RxText(11:20)));
        set(handles.muholdak, 'String',native2unicode(RxText(22:23)));
        set(handles.hdop, 'String',native2unicode(RxText(24:28)));
        set(handles.magassag, 'String',native2unicode(RxText(29:34)));

        speed = (round(100000/(2^8*RxText(35) + RxText(36))/12.8125*3.6*10))/10;
        if (speed > 0.6)
            set(handles.sebesseg, 'String',speed);
        else
            set(handles.sebesseg, 'String',0);
        end
            
        akkuVoltage = (round(((2^8*RxText(38) + RxText(37))/4096*3.31*98/15.9)*100)/100);
        if (akkuVoltage <= 9.6) % 3.2V cellánként
            command = ['#','S','S','0','0','0','*']; % SYSTEM STOP
            fwrite(handles.serial_connection, command);
        end
        set(handles.akkufesz, 'String',akkuVoltage);

        cella3 = (round((((2^8*RxText(38) + RxText(37))/4096*3.31*98/15.9)-((2^8*RxText(40) + RxText(39))/4096*3.31*109.2/26.9))*100)/100);
        if (cella3 <= 3.2) % 3.2V cellafeszültség alatt
            command = ['#','S','S','0','0','0','*']; % SYSTEM STOP
            fwrite(handles.serial_connection, command);
        end
        set(handles.cellfesz3, 'String',cella3);

        cella2 = (round((((2^8*RxText(40) + RxText(39))/4096*3.31*109.2/26.9)-((2^8*RxText(42) + RxText(41))/4096*3.31*106.9/50.9))*100)/100);
        if (cella2 <= 3.2) % 3.2V cellafeszültség alatt
            command = ['#','S','S','0','0','0','*']; % SYSTEM STOP
            fwrite(handles.serial_connection, command);
        end
        set(handles.cellfesz2, 'String',cella2);

        cella1 = (round(((2^8*RxText(42) + RxText(41))/4096*3.31*106.9/50.9)*100)/100);
        if (cella1 <= 3.2) % 3.2V cellafeszültség alatt
            command = ['#','S','S','0','0','0','*']; % SYSTEM STOP
            fwrite(handles.serial_connection, command);
        end
        set(handles.cellfesz1, 'String',cella1);

        set(handles.tapfesz1, 'String',(round(((2^8*RxText(44) + RxText(43))/4096*3.31*100.8/61.9)*100)/100));  %3.31(3.2)
        set(handles.tapfesz2, 'String',(round(((2^8*RxText(46) + RxText(45))/4096*3.31*101.1/39)*100)/100));    %5.18(5.05)

        DCmotor_aram = 0.08+(round(((2^8*RxText(48) + RxText(47))/4096*3.31/20/0.0075)*100)/100);
        if (DCmotor_aram > 0.8)
            set(handles.motoraram, 'String', DCmotor_aram);
        else
            set(handles.motoraram, 'String', 0);
        end
    end
end

% clearvars RxText

%-------------------------------------------------------------------------------------------------------

% --- Executes on selection change in recieve_box.
function recieve_box_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function recieve_box_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function send_box_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function send_box_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

% --- Executes on button press in send_button.
function send_button_Callback(hObject, eventdata, handles)
if (~strcmp(get(handles.send_box,'String'),''))
    TxText = get(handles.send_box, 'String');
    fwrite(handles.serial_connection, TxText);         % STRINGET KÜLD \0
    currList = get(handles.recieve_box, 'String');
    set(handles.recieve_box, 'String',[currList ; ['Sent @ ' datestr(now) ': ' TxText]]);
    set(handles.recieve_box, 'Value', length(currList) + 1 );
    set(handles.send_box, 'String', '');
end
%     pause(0.1);

%-------------------------------------------------------------------------------------------------------

function akkufesz_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function akkufesz_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function tapfesz1_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function tapfesz1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function tapfesz2_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function tapfesz2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function cellfesz1_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function cellfesz1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function cellfesz2_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function cellfesz2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function cellfesz3_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function cellfesz3_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function motoraram_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function motoraram_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function sebesseg_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function sebesseg_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

function szelesseg_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function szelesseg_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------------------------------------------------------------

% --- Executes on button press in balra.
function balra_Callback(hObject, eventdata, handles)
command = ['#','S','B','0','1','0','*'];    %35=# 83=S 66=B (szögelfordulás) 42=*
fwrite(handles.serial_connection, command);
%-------------------------------------------------------------------------------------------------------

% --- Executes on button press in elore.
function elore_Callback(hObject, eventdata, handles)
command = ['#','D','E','0','4','7','*'];     %35=# 77=M 69=E (PWM) 42=*
fwrite(handles.serial_connection, command);
%-------------------------------------------------------------------------------------------------------

% --- Executes on button press in jobbra.
function jobbra_Callback(hObject, eventdata, handles)
command = ['#','S','J','0','1','0','*']; %35=# 83=S 74=J (szögelfordulás) 42=*
fwrite(handles.serial_connection, command);
%-------------------------------------------------------------------------------------------------------

% --- Executes on button press in hatra.
function hatra_Callback(hObject, eventdata, handles)
command = ['#','D','H','0','5','3','*'];     %35=# 77=M 72=H (PWM) 42=*
fwrite(handles.serial_connection, command);
%-------------------------------------------------------------------------------------------------------

% --- Executes on button press in stop.
function stop_Callback(hObject, eventdata, handles)
command = ['#','S','S','0','0','0','*'];     %35=# 83=S 83=S - 42=*
fwrite(handles.serial_connection, command);
%-------------------------------------------------------------------------------------------------------

% --- Executes on button press in kamerajobb.
function kamerajobb_Callback(hObject, eventdata, handles)
command = ['#','L','J','1','8','0','*'];     %35=# 76=L 74=J (szögelfordulás) 42=*
fwrite(handles.serial_connection, command);
%-------------------------------------------------------------------------------------------------------

% --- Executes on button press in kamerabal.
function kamerabal_Callback(hObject, eventdata, handles)
command = ['#','L','B','1','8','0','*']; %35=# 76=L 66=B (szögelfordulás) 42=*
fwrite(handles.serial_connection, command);
%-------------------------------------------------------------------------------------------------------




% --- Executes on button press in sleepmode.
function sleepmode_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
	fwrite(handles.serial_connection, ['#','C','L','0','0','8','*']);
else
	fwrite(handles.serial_connection, ['#','C','L','0','0','9','*']);
end


% --- Executes on button press in resetstate.
function resetstate_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
	fwrite(handles.serial_connection, ['#','C','L','0','1','0','*']);
else
	fwrite(handles.serial_connection, ['#','C','L','0','1','1','*']);
end


% --- Executes on button press in enable.
function enable_Callback(hObject, eventdata, handles)
if (get(hObject,'Value') == get(hObject,'Max'))
	fwrite(handles.serial_connection, ['#','C','L','0','1','2','*']);
else
	fwrite(handles.serial_connection, ['#','C','L','0','1','3','*']);
end

% --- Executes when selected object is changed in lepteto_mode.
function lepteto_mode_SelectionChangeFcn(hObject, eventdata, handles)
handles = guidata(hObject);
newbutton = get(eventdata.NewValue,'Tag');
switch newbutton % Get Tag of selected object.
    case 'fullstep'
        fwrite(handles.serial_connection, ['#','C','L','0','0','0','*']);
    case 'halfstep'
        fwrite(handles.serial_connection, ['#','C','L','0','0','1','*']);
    case 'negyedlepes'
        fwrite(handles.serial_connection, ['#','C','L','0','0','2','*']);
    case 'nyolcadlepes'
        fwrite(handles.serial_connection, ['#','C','L','0','0','3','*']);
    case 'tizenhatodlepes'
        fwrite(handles.serial_connection, ['#','C','L','0','0','4','*']);
    case 'harminckettedlepes'
        fwrite(handles.serial_connection, ['#','C','L','0','0','5','*']);
end
guidata(hObject, handles);



function hosszusag_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function hosszusag_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in gpsaktiv.
function gpsaktiv_Callback(hObject, eventdata, handles)



function muholdak_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function muholdak_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function magassag_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function magassag_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function hdop_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function hdop_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
eventdata.Key
switch eventdata.Key
    %case 'uparrow'
    case 'w'
        command = ['#','D','E','0','4','7','*'];     %35=# 77=M 69=E (PWM) 42=*
        fwrite(handles.serial_connection, command);
    case 's'
        command = ['#','D','H','0','5','3','*'];     %35=# 77=M 72=H (PWM) 42=*
        fwrite(handles.serial_connection, command); 
    case 'd'
        command = ['#','S','J','0','1','0','*'];     %35=# 83=S 74=J (szögelfordulás) 42=*
        fwrite(handles.serial_connection, command);
    case 'a'
        command = ['#','S','B','0','1','0','*'];     %35=# 83=S 66=B (szögelfordulás) 42=*
        fwrite(handles.serial_connection, command);
    case 'space'
        command = ['#','S','S','0','0','0','*'];     %35=# 83=S 83=S - 42=*
        fwrite(handles.serial_connection, command);
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
if isfield(handles, 'serial_connection')
     fclose(handles.serial_connection);
     handles = rmfield(handles,'serial_connection');
end
delete(hObject);
