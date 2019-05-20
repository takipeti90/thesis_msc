function varargout = power_meres(varargin)
% POWER_MERES MATLAB code for power_meres.fig
%      POWER_MERES, by itself, creates a new POWER_MERES or raises the existing
%      singleton*.
%
%      H = POWER_MERES returns the handle to a new POWER_MERES or the handle to
%      the existing singleton*.
%
%      POWER_MERES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in POWER_MERES.M with the given input arguments.
%
%      POWER_MERES('Property','Value',...) creates a new POWER_MERES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before power_meres_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to power_meres_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help power_meres

% Last Modified by GUIDE v2.5 01-Jul-2015 17:29:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @power_meres_OpeningFcn, ...
                   'gui_OutputFcn',  @power_meres_OutputFcn, ...
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


% --- Executes just before power_meres is made visible.
function power_meres_OpeningFcn(hObject, eventdata, handles, varargin)
clc
global xlRangeNum;
xlRangeNum = 1;
filename = 'powerMeasure.xlsx';
header = {'shunt1 current' 'shunt1 power' 'shunt2 current' 'shunt2 power' 'voltage RFM'};
sheet = 1;
xlRange = ['A' num2str(xlRangeNum)];
xlswrite(filename,header,sheet,xlRange);
serialPorts = instrhwinfo('serial');
set(handles.portselect, 'String',[{'Select a port'} ; serialPorts.SerialPorts ]);
set(handles.receivedtext, 'String', cell(1));
handles.output = hObject;
guidata(hObject, handles);

function varargout = power_meres_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


% --- Executes on selection change in portselect.
function portselect_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function portselect_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in connect.
function connect_Callback(hObject, eventdata, handles)
if (strcmp(get(handles.connect,'String'),'CONNECT'))
    serPortn = get(handles.portselect, 'Value');
    if (serPortn~=1)
        serList = get(handles.portselect,'String');
        serPort = serList{serPortn};
        serial_connection = serial(serPort,'BaudRate',9600,'DataBits',8,'StopBits',1);
                
        serial_connection.BytesAvailableFcnCount = 8;
        serial_connection.BytesAvailableFcnMode = 'byte';
%         serial_connection.Terminator = 'CR/LF';
%         serial_connection.BytesAvailableFcnMode = 'terminator';
        handles.serial_connection = serial_connection;
        serial_connection.BytesAvailableFcn = {@serialRead,handles};
        try
            fopen(serial_connection);
        catch e
            errordlg(e.message);            
        end
        set(handles.connect,'String','DISCONNECT');
        set(handles.sendbutton, 'Enable', 'On');
        set(handles.sendbox, 'Enable', 'On');
        set(handles.receivedtext, 'Enable', 'On');
        set(handles.aram1, 'Enable', 'On');
        set(handles.aram2, 'Enable', 'On');
        set(handles.power1, 'Enable', 'On');
        set(handles.power2, 'Enable', 'On');
        set(handles.feszultseg_rfm, 'Enable', 'On');
        set(handles.adctriggeringtime, 'Enable', 'On');
        set(handles.setadctime, 'Enable', 'On');
        set(handles.averaging, 'Enable', 'On');
        set(handles.setaverage, 'Enable', 'On');
        set(handles.startadc, 'Enable', 'On');
        set(handles.stopadc, 'Enable', 'On');
        set(handles.idlebutton, 'Enable', 'On');
        set(handles.rxbutton, 'Enable', 'On');
        set(handles.txnum, 'Enable', 'On');
        set(handles.chartx, 'Enable', 'On');
        set(handles.txstate, 'Enable', 'On');
        set(handles.portselect, 'Enable', 'Off');
    end
else
    set(handles.connect,'String','CONNECT');
    set(handles.aram1, 'String', '');
    set(handles.power1, 'String', '');
    set(handles.aram2, 'String', '');
    set(handles.power2, 'String', '');
    set(handles.feszultseg_rfm, 'String', '');
    set(handles.sendbutton, 'Enable', 'Off');
    set(handles.sendbox, 'Enable', 'Off');
    set(handles.receivedtext, 'Enable', 'Off');
    set(handles.aram1, 'Enable', 'Off');
    set(handles.aram2, 'Enable', 'Off');
    set(handles.power1, 'Enable', 'Off');
    set(handles.power2, 'Enable', 'Off');
    set(handles.feszultseg_rfm, 'Enable', 'Off');
    set(handles.adctriggeringtime, 'Enable', 'Off');
    set(handles.setadctime, 'Enable', 'Off');
    set(handles.averaging, 'Enable', 'Off');
    set(handles.setaverage, 'Enable', 'Off');
    set(handles.startadc, 'Enable', 'Off');
    set(handles.stopadc, 'Enable', 'Off');
    set(handles.idlebutton, 'Enable', 'Off');
    set(handles.rxbutton, 'Enable', 'Off');
    set(handles.txnum, 'Enable', 'Off');
    set(handles.chartx, 'Enable', 'Off');
    set(handles.txstate, 'Enable', 'Off');
    set(handles.portselect, 'Enable', 'On');
    fclose(handles.serial_connection);
    handles = rmfield(handles,'serial_connection');
end
guidata(hObject, handles);


function serialRead(hObject, eventdata, handles)
global xlRangeNum;
bytesAvailable = hObject.BytesAvailable;
if (bytesAvailable)
    rxin = fread(hObject,bytesAvailable);  % read binary data
    RxText = rxin';
    if (RxText(1) == '#' && RxText(8) == '*')
        
        shuntIN = (2^8*RxText(4) + RxText(5));
        shuntOUT = (2^8*RxText(6) + RxText(7));
        shuntVoltage = shuntIN - shuntOUT;
        current1 = (round((shuntVoltage*3.36/4096*57/47/3.3*1000)*1000))/1000;
        power1 = (round(((current1^2)*3.3)*1000))/1000;
        %tic
        set(handles.aram1, 'String',current1);
        set(handles.power1, 'String',power1);
        %toc
        
        ina196 = (2^8*RxText(2) + RxText(3));
        current2 = (round((ina196*3.36/4096/20/1.8*1000)*1000))/1000-0.091;
        voltageRFM = (round(((shuntOUT*3.36/4096*57/47)-(ina196*3.36/4096/20))*1000))/1000;
        power2 = (round(((current2^2)*1.8)*1000))/1000;
        %tic
        set(handles.feszultseg_rfm, 'String',voltageRFM);
        set(handles.aram2, 'String',current2);
        set(handles.power2, 'String',power2);
        %toc
        
        %tic
        write2file = [current1 power1 current2 power2 voltageRFM];
        xlRangeNum = xlRangeNum + 1;
        xlRange = ['A' num2str(xlRangeNum)];
        xlswrite('powerMeasure.xlsx',write2file,1,xlRange);
        %tic
    end
end


function sendbox_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function sendbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in sendbutton.
function sendbutton_Callback(hObject, eventdata, handles)
if (~strcmp(get(handles.sendbox,'String'),''))
    TX2RFM = get(handles.sendbox, 'String');
    TxText = ['#','0',TX2RFM,13,10];
    fwrite(handles.serial_connection, TxText);
    currList = get(handles.receivedtext, 'String');
    set(handles.receivedtext, 'String',[currList ; ['Sent: ' TX2RFM]]);
    set(handles.receivedtext, 'Value', length(currList) + 1 );
    set(handles.sendbox, 'String', '');
end


function receivedtext_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function receivedtext_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function aram1_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function aram1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function aram2_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function aram2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function feszultseg_rfm_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function feszultseg_rfm_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function power1_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function power1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function power2_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function power2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function adctriggeringtime_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function adctriggeringtime_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function averaging_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function averaging_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in setadctime.
function setadctime_Callback(hObject, eventdata, handles)
adctime = get(handles.adctriggeringtime, 'String');
if (length(adctime) == 1)
    time = ['0' '0' '0' '0' adctime];
elseif (length(adctime) == 2)
    time = ['0' '0' '0' adctime];
elseif (length(adctime) == 3)
    time = ['0' '0' adctime];
elseif (length(adctime) == 4)
    time = ['0' adctime];
elseif (length(adctime) == 5)
    if (adctime > 65535)
        time = ['0' '0' '1' '0' '0'];
    else
        time = adctime;
    end
else
    time = ['0' '0' '1' '0' '0'];
    set(handles.adctriggeringtime, 'String', 100);
end
command = ['#','3',time,13,10];
fwrite(handles.serial_connection, command);


% --- Executes on button press in setaverage.
function setaverage_Callback(hObject, eventdata, handles)
average = get(handles.averaging, 'String');
if (length(average) == 1)
    time = ['0' '0' '0' '0' average];
elseif (length(average) == 2)
    time = ['0' '0' '0' average];
elseif (length(average) == 3)
    time = ['0' '0' average];
elseif (length(average) == 4)
    time = ['0' average];
elseif (length(average) == 5)
    if (average > 65535)
        time = ['0' '1' '0' '0' '0'];
    else
        time = average;
    end
else
    time = ['0' '1' '0' '0' '0'];
    set(handles.averaging, 'String', 1000);
end
command = ['#','4',time,13,10];
fwrite(handles.serial_connection, command);


% --- Executes on button press in startadc.
function startadc_Callback(hObject, eventdata, handles)
command = ['#','1',13,10];
fwrite(handles.serial_connection, command);


% --- Executes on button press in stopadc.
function stopadc_Callback(hObject, eventdata, handles)
command = ['#','2',13,10];
fwrite(handles.serial_connection, command);


% --- Executes on button press in resetbutton.
function resetbutton_Callback(hObject, eventdata, handles)
set(handles.aram1, 'String', '');
set(handles.power1, 'String', '');
set(handles.aram2, 'String', '');
set(handles.power2, 'String', '');


% --- Executes on button press in idlebutton.
function idlebutton_Callback(hObject, eventdata, handles)
command = ['#','0','#','I','D','L','E','*',13,10];
fwrite(handles.serial_connection, command);


% --- Executes on button press in rxbutton.
function rxbutton_Callback(hObject, eventdata, handles)
command = ['#','0','#','R','X','*',13,10];
fwrite(handles.serial_connection, command);


function txnum_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function txnum_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function chartx_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function chartx_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in txstate.
function txstate_Callback(hObject, eventdata, handles)
number = get(handles.txnum, 'String');
if (length(number) == 1)
    txnumber = ['0' '0' '0' '0' number];
elseif (length(number) == 2)
    txnumber = ['0' '0' '0' number];
elseif (length(number) == 3)
    txnumber = ['0' '0' number];
elseif (length(number) == 4)
    txnumber = ['0' number];
elseif (length(number) == 5)
    if (number > 65535)
        txnumber = ['0' '0' '0' '0' '0'];
    else
        txnumber = number;
    end
else
    txnumber = ['0' '0' '0' '0' '0'];
    set(handles.txnum, 'String', 0);
end
char = get(handles.chartx, 'String');
command = ['#','0','#','T','X',char,txnumber,'*',13,10];
fwrite(handles.serial_connection, command);



% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
if isfield(handles, 'serial_connection')
     fclose(handles.serial_connection);
     handles = rmfield(handles,'serial_connection');
end
delete(hObject);
