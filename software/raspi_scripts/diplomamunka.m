function varargout = diplomamunka(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @diplomamunka_OpeningFcn, ...
                   'gui_OutputFcn',  @diplomamunka_OutputFcn, ...
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

%----------------------------- STARTUP ------------------------------------
function diplomamunka_OpeningFcn(hObject, eventdata, handles, varargin)
clc
%----- homerseklet szenzor gorbeje -----
global x1_ho;
global y1_ho;
x_ho = [498 538 581 603 626 672 722 773 826 882 940 1000];
y_ho = [0 10 20 25 30 40 50 60 70 80 90 100];
[poly_ho,~,mu_ho] = polyfit(x_ho,y_ho,10);
x1_ho = 498:0.1:1000;
y1_ho = polyval(poly_ho,x1_ho,[],mu_ho);
%----- ping szenzor gorbeje -----
global x1_sharp;
global y1_sharp;
x_sharp = [2.28 1.62 1.27 1.05 0.92 0.75 0.62 0.53 0.46 0.4];
y_sharp = [10 15 20 25 30 40 50 60 70 80]; 
[poly_sharp,~,mu_sharp] = polyfit(x_sharp,y_sharp,5);
x1_sharp = 0.4:0.01:2.28;
x1_sharp = (round(x1_sharp.*100))/100;
y1_sharp = polyval(poly_sharp,x1_sharp,[],mu_sharp);
%----- alap kamerakep -----
%fid = fopen('camera.jpg', 'rb');
%b0 = fread(fid, Inf, '*uint8');
%fclose(fid);
jImg0 = javax.imageio.ImageIO.read(java.io.ByteArrayInputStream(b0));
h0 = jImg0.getHeight;
w0 = jImg0.getWidth;
p0 = reshape(typecast(jImg0.getData.getDataStorage, 'uint8'), [3,w0,h0]);
camImg0 = cat(3, transpose(reshape(p0(3,:,:), [w0,h0])), transpose(reshape(p0(2,:,:), [w0,h0])), transpose(reshape(p0(1,:,:), [w0,h0])));
image(camImg0, 'Parent', handles.axes2);
set(handles.axes2,'Visible', 'off','Units', 'pixels','Position', [369 209 512 384]);
%----- alap halozati kapcsolati cimek, portok -----
address = java.net.InetAddress.getLocalHost;
IPaddress =  char(address.getHostAddress);
set(handles.localIP, 'String',IPaddress);
set(handles.remoteIP, 'String','192.168.1.8');
set(handles.localPort, 'String',50000);
set(handles.remotePort, 'String',50001);
set(handles.cameraport, 'String',50002);
global idx
idx = 0;
global img
img = 0;
global jImg
jImg = 0;
global h
h = 0;
global w
w = 0;
global p
p = 0;
global camImg
camImg = 0;
global fps
fps = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
global fpsAvg
fpsAvg = 0;
global fpsNum
fpsNum = 1;
global pattern
pattern = [49 57 57 48 48 54 50 56 13 10];
global tcpBuffer
tcpBuffer = [];
global imgLength;
imgLength = 0;
global imgBuff;
imgBuff = 0;
global uartData;
uartData = 0;
global uartDataNum;
uartDataNum = 1;
global uartBuffer;
uartBuffer = zeros(1,50);
serialPorts = instrhwinfo('serial');
set(handles.portselect, 'String',[{'Select a port'} ; serialPorts.SerialPorts ]);
handles.output = hObject;
guidata(hObject, handles);

function varargout = diplomamunka_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%-------------------------- UDP KAPCSOLAT ---------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function udpconnect_Callback(hObject, eventdata, handles)
if (strcmp(get(handles.udpconnect,'String'),'WIFI CONNECT'))    
    portLoc = str2num(get(handles.localPort,'String'));
    ipRem = get(handles.remoteIP,'String');
    portRem = str2num(get(handles.remotePort,'String'));

    udpConn = udp(ipRem,portRem,'LocalPort',portLoc);
    udpConn.Terminator = 'CR/LF';
    udpConn.BytesAvailableFcnMode = 'terminator';
    handles.udpConn = udpConn;
    udpConn.BytesAvailableFcn = {@udpRead,handles};
    try
        fopen(udpConn);
        set(handles.udpconnect,'String','WIFI DISCONNECT');
        set(handles.remoteIP, 'Enable', 'Inactive');
        set(handles.remotePort, 'Enable', 'Inactive');
        set(handles.localPort, 'Enable', 'Inactive');
        set(handles.stopbutton, 'Enable', 'On');
        set(handles.telemetria1, 'Enable', 'On');
        if (strcmp(get(handles.connect,'String'),'RADIO CONNECT'))     % ha a radio nincs connectelve
            set(handles.wifichannel, 'Value', 1);
        end
        channel = get(get(handles.channel,'SelectedObject'), 'Tag');
        if(strcmp(channel,'wifichannel'))
            set(handles.h264button, 'Enable', 'On');
            set(handles.jpegbutton, 'Enable', 'On');
        end
        set(handles.wifichannel, 'Enable', 'On');
        set(handles.kameraforgat, 'Enable', 'Inactive');
        set(handles.elore, 'Enable', 'Inactive');
        set(handles.oldalra, 'Enable', 'Inactive');
    catch e
        errordlg(e.message);            
    end
else
    if (strcmp(get(handles.connect,'String'),'RADIO CONNECT'))     % ha a radio sincs connectelve
        set(handles.elore, 'Value', 50);
        set(handles.oldalra, 'Value', 140);
        set(handles.kameraforgat, 'Value', 0);
        set(handles.telemetria1, 'Enable', 'Off');
        set(handles.kameraforgat, 'Enable', 'Off');
        set(handles.stopbutton, 'Enable', 'Off');
        set(handles.elore, 'Enable', 'Off');
        set(handles.oldalra, 'Enable', 'Off');
        command = ['#','S','S','0','0','0',13,10];     % STOP SYSTEM
        fwrite(handles.udpConn, command);
        set(handles.elore, 'Value', 50);
        set(handles.oldalra, 'Value', 140);
        set(handles.kameraforgat, 'Value', 0);
    end
    if (strcmp(get(handles.connect,'String'),'RADIO DISCONNECT'))   % ha a radio connectelve van valtas radiora
        set(handles.wifichannel, 'Value', 0);
        set(handles.radiochannel, 'Value', 1);
        command = ['#','R','P','0','0','0',13,10];     % change to radio, RPi close the ports
        fwrite(handles.serial_connection, command);
    end
    set(handles.udpconnect,'String','WIFI CONNECT');
    set(handles.tcpconnect,'String','CAMERA CONNECT');
    set(handles.remoteIP, 'Enable', 'On');
    set(handles.remotePort, 'Enable', 'On');
    set(handles.localPort, 'Enable', 'On');
    set(handles.tcpconnect, 'Enable', 'Off');
    set(handles.h264button, 'Enable', 'Off');
    set(handles.jpegbutton, 'Enable', 'Off');
    set(handles.h264button, 'Value', 0);
    set(handles.jpegbutton, 'Value', 0);
    set(handles.wifichannel, 'Enable', 'Off');
    fclose(handles.udpConn);
    handles = rmfield(handles,'udpConn');
end
guidata(hObject, handles);
%--------------------------------------------------------------------------
function udpRead(hObject, eventdata, handles)
global x1_ho;
global y1_ho;
global x1_sharp;
global y1_sharp;
bytesAvailable = hObject.BytesAvailable;
RxText = fread(hObject,bytesAvailable)';
%dataFrom = ['U' 'D' 'P']
if (RxText(1) == '#' && RxText(55) == 13 && RxText(56) == 10) % '#' && 13(\r) && 10(\n)
    if (RxText(21) == '1')
        set(handles.gpsaktiv,'Value',1);
        set(handles.gpsaktiv,'String','GPS AKTÍV');
    end
    set(handles.eszak, 'String',native2unicode(RxText(2:10)))
    set(handles.kelet, 'String',native2unicode(RxText(11:20)));
    set(handles.muholdszam, 'String',native2unicode(RxText(22:23)));
    set(handles.hdop, 'String',native2unicode(RxText(24:28)));
    set(handles.magassag, 'String',native2unicode(RxText(29:34)));

    speed = (round(((100*10^-6)^-1)/(2^8*RxText(35) + RxText(36))/12.8125*3.6*10))/10;
    if (speed > 0.6 && speed < 20)
        set(handles.sebesseg, 'String',speed);
    else
        set(handles.sebesseg, 'String',0);
    end
    
    akkuVoltage = (round(((2^8*RxText(37) + RxText(38))/4096*3.355*97.3/15.8)*100)/100);
    if (akkuVoltage <= 9.6) % 3.2V cellánként
%         command = ['#','S','S','0','0','0',13,10]; % SYSTEM STOP
%         fwrite(handles.udpConn, command);
%         set(handles.elore, 'Value', 50);
%         set(handles.oldalra, 'Value', 140);
%         set(handles.kameraforgat, 'Value', 0);
    end
    set(handles.akkufesz, 'String',akkuVoltage);

    cella3 = (round((((2^8*RxText(37) + RxText(38))/4096*3.355*97.3/15.8)-((2^8*RxText(39) + RxText(40))/4096*3.355*108.2/26.7))*100)/100);
    if (cella3 <= 3.2) % 3.2V cellafeszültség alatt
%         command = ['#','S','S','0','0','0',13,10]; % SYSTEM STOP
%         fwrite(handles.udpConn, command);
%         set(handles.elore, 'Value', 50);
%         set(handles.oldalra, 'Value', 140);
%         set(handles.kameraforgat, 'Value', 0);
    end
    set(handles.cella3, 'String',cella3);

    cella2 = (round((((2^8*RxText(39) + RxText(40))/4096*3.355*108.2/26.7)-((2^8*RxText(41) + RxText(42))/4096*3.355*105.8/50.2))*100)/100);
    if (cella2 <= 3.2) % 3.2V cellafeszültség alatt
%         command = ['#','S','S','0','0','0',13,10]; % SYSTEM STOP
%         fwrite(handles.udpConn, command);
%         set(handles.elore, 'Value', 50);
%         set(handles.oldalra, 'Value', 140);
%         set(handles.kameraforgat, 'Value', 0);
    end
    set(handles.cella2, 'String',cella2);

    cella1 = (round(((2^8*RxText(41) + RxText(42))/4096*3.355*105.8/50.2)*100)/100);
    if (cella1 <= 3.2) % 3.2V cellafeszültség alatt
%         command = ['#','S','S','0','0','0',13,10]; % SYSTEM STOP
%         fwrite(handles.udpConn, command);
%         set(handles.elore, 'Value', 50);
%         set(handles.oldalra, 'Value', 140);
%         set(handles.kameraforgat, 'Value', 0);
    end
    set(handles.cella1, 'String',cella1);

    set(handles.tapfesz1, 'String',(round(((2^8*RxText(43) + RxText(44))/4096*3.355*100.8/61.9)*100)/100));
    set(handles.tapfesz2, 'String',(round(((2^8*RxText(45) + RxText(46))/4096*3.355*101.1/39)*100)/100));

    % hõszenzor, fényerõ, PING
    fenyero = (round(((2^8*RxText(49) + RxText(50))/4096*3.355)*100)/100);
    set(handles.fenyero, 'String', fenyero);
                 
     ping_feszultseg = (round(((2^8*RxText(51) + RxText(52))/4096*3.355)*100)/100);
     if (ping_feszultseg > 2.28)
        set(handles.pingszenzor, 'String', '< 10');
     elseif (ping_feszultseg < 0.4)
        set(handles.pingszenzor, 'String', '> 80');
     else
        akadaly_tavolsag = (round(y1_sharp(find(x1_sharp == ping_feszultseg))*10)/10);
        set(handles.pingszenzor, 'String', akadaly_tavolsag);
     end
                                
     ho_feszultseg = ((2^8*RxText(47) + RxText(48))/4096*3.355);
     hoellenallas = (round((2000*ho_feszultseg)/(3.37 - ho_feszultseg)*10)/10);
     homerseklet = (round(y1_ho(find(x1_ho == hoellenallas))*10)/10);
     set(handles.hoszenzor, 'String', homerseklet);
                
     DCmotor_aram = (round((((((2^8*RxText(53) + RxText(54))/4096*3.355)-1.58)/20)/0.0075)*100)/100);
     if (DCmotor_aram > 0.8)
        set(handles.motoraram, 'String', DCmotor_aram);
     elseif (DCmotor_aram - 0.27 < -0.8)
        set(handles.motoraram, 'String', DCmotor_aram - 0.27);
     else
        set(handles.motoraram, 'String', '0');
     end
     
     speed = (round(10000/(2^8*RxText(35) + RxText(36))/12.8125*3.6*100))/100;
     if (speed > 0.5 && speed < 20 && (~strcmp(get(handles.motoraram,'String'),'0')))
        set(handles.sebesseg, 'String',speed);
     else
        set(handles.sebesseg, 'String',0);
     end
end
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%-------------------------- TCP KAPCSOLAT ---------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%--------------------- H264 STREAM or JPEG STREAM -------------------------
function stream_SelectionChangeFcn(hObject, eventdata, handles)
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'h264button'
        set(handles.tcpconnect, 'Enable', 'On');
        command = ['#','R','P','0','0','3',13,10];     % H264 stream on RPi
        fwrite(handles.udpConn, command);
    case 'jpegbutton'
        set(handles.tcpconnect, 'Enable', 'On');
        command = ['#','R','P','0','0','2',13,10];     % JPEG stream on RPi
        fwrite(handles.udpConn, command);
end
%--------------------------------------------------------------------------
function tcpconnect_Callback(hObject, eventdata, handles)
global tcpBuffer;
global img;
stream = get(get(handles.stream,'SelectedObject'), 'Tag');  % melyiken all a gomb (H264 vagy JPEG)
if(strcmp(get(handles.tcpconnect,'String'),'CAMERA CONNECT'))    
    if(strcmp(stream,'h264button'))  % H264 stream
        set(handles.tcpconnect,'String','CAMERA DISCONNECT');
        set(handles.h264button, 'Enable', 'Off');
        set(handles.jpegbutton, 'Enable', 'Off');
        system('D:\BME\MSC\Diplomatervezes\RaspberryPi\stream\h264_stream.bat &')
        %system('taskkill /F /IM cmd.exe')
    elseif(strcmp(stream,'jpegbutton'))    % JPEG stream
        ipRem = get(handles.remoteIP,'String');
        camPort = str2num(get(handles.cameraport,'String'));
        tcpConn = tcpip(ipRem,camPort);
        tcpConn.InputBufferSize = 5242880;
        tcpConn.Terminator = 'CR/LF';
        tcpConn.BytesAvailableFcnMode = 'terminator';
        handles.tcpConn = tcpConn;
        tcpConn.BytesAvailableFcn = {@tcpRead,handles};
        try
            fopen(tcpConn);
            set(handles.tcpconnect,'String','CAMERA DISCONNECT');
            set(handles.remoteIP, 'Enable', 'Inactive');
            set(handles.cameraport, 'Enable', 'Inactive');
            set(handles.h264button, 'Enable', 'Off');
            set(handles.jpegbutton, 'Enable', 'Off');
            tic;
        catch e
            set(handles.jpegbutton, 'Value', 0);
            set(handles.tcpconnect, 'Enable', 'Off');
            errordlg(e.message);            
        end
    end 
else    % STOP CAMERA
    if(strcmp(stream,'h264button'))  % H264 stream
        set(handles.tcpconnect,'String','CAMERA CONNECT');
        set(handles.h264button, 'Enable', 'On');
        set(handles.jpegbutton, 'Enable', 'On');
        set(handles.h264button, 'Value', 0);
        set(handles.jpegbutton, 'Value', 0);
        set(handles.tcpconnect, 'Enable', 'Off');
        %system('D:\BME\MSC\Diplomatervezes\RaspberryPi\stream\stop_h264_stream.bat &')
        system('taskkill /F /IM mplayer.exe')
        %system('taskkill /F /IM nc64.exe')
        system('taskkill /F /IM cmd.exe')
        command = ['#','R','P','0','0','5',13,10];     % KILL H264 streaming task on RPI
        fwrite(handles.udpConn, command);
    elseif(strcmp(stream,'jpegbutton'))    % JPEG stream
        command = ['#','R','P','0','0','4',13,10];     % KILL JPEG streaming task on RPI
        fwrite(handles.udpConn, command);
        set(handles.tcpconnect,'String','CAMERA CONNECT');
        set(handles.remoteIP, 'Enable', 'On');
        set(handles.cameraport, 'Enable', 'On');
        set(handles.h264button, 'Enable', 'On');
        set(handles.jpegbutton, 'Enable', 'On');
        set(handles.h264button, 'Value', 0);
        set(handles.jpegbutton, 'Value', 0);
        set(handles.tcpconnect, 'Enable', 'Off');
        if(handles.tcpConn.BytesAvailable > 0)
            fread(handles.tcpConn, handles.tcpConn.BytesAvailable);
        end
        tcpBuffer = [];
        img = 0;
        fclose(handles.tcpConn);
        handles = rmfield(handles,'tcpConn');
    end
end
guidata(hObject, handles);
%--------------------------------------------------------------------------
function tcpRead(hObject, eventdata, handles)
global pattern
global tcpBuffer
global idx
global img
global jImg
global h
global w
global p
global camImg
global fps
global fpsAvg
global fpsNum

tcpBuffer = [tcpBuffer; fread(hObject,hObject.BytesAvailable)];
idx = strfind(tcpBuffer',pattern);
if (length(idx) == 1)     % ha 1 frame van a bufferben
    img = tcpBuffer(1:idx-1);
    tcpBuffer = tcpBuffer(idx+10:length(tcpBuffer));
elseif (length(idx) > 1)    % ha tobb frame van a bufferben akkor az utolsot olvassa ki
    img = tcpBuffer(idx(length(idx)-1)+10:idx(length(idx))-1);
    tcpBuffer = tcpBuffer(idx(length(idx))+10:length(tcpBuffer));
end
jImg = javax.imageio.ImageIO.read(java.io.ByteArrayInputStream(img));
h = jImg.getHeight;
w = jImg.getWidth;
p = reshape(typecast(jImg.getData.getDataStorage, 'uint8'), [3,w,h]);
camImg = cat(3, transpose(reshape(p(3,:,:), [w,h])), transpose(reshape(p(2,:,:), [w,h])), transpose(reshape(p(1,:,:), [w,h])));
image(camImg, 'Parent', handles.axes2);
fps(fpsNum) = (1/toc);
if(fpsNum == 30)
    fpsNum = 1;
else
    fpsNum = fpsNum + 1;
end
fpsAvg = round((sum(fps)/30)*10)/10;
set(handles.axes2,'Visible', 'off','Units', 'pixels','Position', [369 209 512 384]);
set(handles.fps, 'String', fpsAvg);
tic
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%-------------------------- SOROS KAPCSOLAT -------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function refresh_Callback(hObject, eventdata, handles)
serialPorts = instrhwinfo('serial');
set(handles.portselect, 'String',[{'Select a port'} ; serialPorts.SerialPorts ]);
%--------------------------------------------------------------------------
function channel_SelectionChangeFcn(hObject, eventdata, handles)
switch get(eventdata.NewValue,'Tag') % Get Tag of selected object.
    case 'wifichannel'
        set(handles.h264button, 'Enable', 'On');
        set(handles.jpegbutton, 'Enable', 'On');
        command = ['#','R','P','0','0','1',13,10];     % change to wifi, RPi open the ports
        fwrite(handles.serial_connection, command);
    case 'radiochannel'
        set(handles.h264button, 'Enable', 'Off');
        set(handles.jpegbutton, 'Enable', 'Off');
        set(handles.h264button, 'Value', 0);
        set(handles.jpegbutton, 'Value', 0);
        command = ['#','R','P','0','0','0',13,10];     % change to radio, RPi close the ports
        fwrite(handles.serial_connection, command);
end
%--------------------------------------------------------------------------
function connect_Callback(hObject, eventdata, handles)
if (strcmp(get(handles.connect,'String'),'RADIO CONNECT'))
    serPortn = get(handles.portselect, 'Value');
    if (serPortn~=1)
        serList = get(handles.portselect,'String');
        serPort = serList{serPortn};
        serial_connection = serial(serPort,'BaudRate',115200,'DataBits',8,'StopBits',1);     
        serial_connection.BytesAvailableFcnCount = 1;
        serial_connection.BytesAvailableFcnMode = 'byte';
        handles.serial_connection = serial_connection;
        serial_connection.BytesAvailableFcn = {@serialRead,handles};
        try
            fopen(serial_connection);
            set(handles.connect,'String','RADIO DISCONNECT');
            set(handles.stopbutton, 'Enable', 'On');
            set(handles.telemetria1, 'Enable', 'On');
            set(handles.radiochannel, 'Enable', 'On');
            set(handles.kameraforgat, 'Enable', 'Inactive');
            set(handles.elore, 'Enable', 'Inactive');
            set(handles.oldalra, 'Enable', 'Inactive');
            set(handles.refresh, 'Enable', 'Off');
            set(handles.portselect, 'Enable', 'Off');
            if (strcmp(get(handles.udpconnect,'String'),'WIFI CONNECT'))   % ha a wifi nincs connectelve van valtas radiora
                set(handles.wifichannel, 'Value', 0);
                set(handles.radiochannel, 'Value', 1);
                command = ['#','R','P','0','0','0',13,10];     % change to radio, RPi close the ports
                fwrite(handles.serial_connection, command);
            end
        catch e
            errordlg(e.message);            
        end
    end
else
    if (strcmp(get(handles.udpconnect,'String'),'WIFI CONNECT'))    % ha a wifi se connectelt
        set(handles.elore, 'Value', 50);
        set(handles.oldalra, 'Value', 140);
        set(handles.kameraforgat, 'Value', 0);
        set(handles.stopbutton, 'Enable', 'Off');
        set(handles.telemetria1, 'Enable', 'Off');
        set(handles.kameraforgat, 'Enable', 'Off');
        set(handles.elore, 'Enable', 'Off');
        set(handles.oldalra, 'Enable', 'Off');
        command = ['#','S','S','0','0','0',13,10];     % change to radio, RPi close the ports
        fwrite(handles.serial_connection, command);
        set(handles.elore, 'Value', 50);
        set(handles.oldalra, 'Value', 140);
        set(handles.kameraforgat, 'Value', 0);
    end
    if (strcmp(get(handles.udpconnect,'String'),'WIFI DISCONNECT'))   % ha a wifi connectelve van valtas wifire
        command = ['#','R','P','0','0','1',13,10];     % change to wifi, RPi open the ports
        fwrite(handles.serial_connection, command);
        set(handles.wifichannel, 'Value', 1);
        set(handles.radiochannel, 'Value', 0);
        set(handles.h264button, 'Enable', 'On');
        set(handles.jpegbutton, 'Enable', 'On');
    end    
    set(handles.connect,'String','RADIO CONNECT');
    set(handles.radiochannel, 'Enable', 'Off');
    set(handles.portselect, 'Enable', 'On');
    set(handles.refresh, 'Enable', 'On');
    fclose(handles.serial_connection);
    handles = rmfield(handles,'serial_connection');
end
guidata(hObject, handles);
%--------------------------------------------------------------------------
function serialRead(hObject, eventdata, handles)
global y1_ho;
global x1_ho;
global x1_sharp;
global y1_sharp;
global uartData;
global uartDataNum;
global uartBuffer;
bytesAvailable = hObject.BytesAvailable;

if (bytesAvailable > 1)
    uartData = fread(hObject,1);
    if (uartData == '#')
        uartDataNum = 1;
    end
    uartBuffer(uartDataNum) = uartData;
    if (uartBuffer(1) == '#')
        if (uartDataNum == 56 && uartBuffer(uartDataNum-1) == 13 && uartBuffer(uartDataNum) == 10)
            %feldolgozás
            %dataFrom = ['S' 'E' 'R']
            RxText = uartBuffer;
            if (RxText(1) == '#')
                if (RxText(21) == '1')
                    set(handles.gpsaktiv,'Value',1);
                    set(handles.gpsaktiv,'String','GPS AKTÍV');
                end
                set(handles.eszak, 'String',native2unicode(RxText(2:10)))
                set(handles.kelet, 'String',native2unicode(RxText(11:20)));
                set(handles.muholdszam, 'String',native2unicode(RxText(22:23)));
                set(handles.hdop, 'String',native2unicode(RxText(24:28)));
                set(handles.magassag, 'String',native2unicode(RxText(29:34)));
            
                akkuVoltage = (round(((2^8*RxText(37) + RxText(38))/4096*3.355*97.3/15.8)*100)/100);
                if (akkuVoltage <= 9.6) % 3.2V cellánként
%                     command = ['#','S','S','0','0','0',13,10]; % SYSTEM STOP
%                     fwrite(handles.serial_connection, command);
%                     set(handles.elore, 'Value', 50);
%                     set(handles.oldalra, 'Value', 140);
%                     set(handles.kameraforgat, 'Value', 0);
                end
                set(handles.akkufesz, 'String',akkuVoltage);
                
                cella3 = (round((((2^8*RxText(37) + RxText(38))/4096*3.355*97.3/15.8)-((2^8*RxText(39) + RxText(40))/4096*3.355*108.2/26.7))*100)/100);
                if (cella3 <= 3.2) % 3.2V cellafeszültség alatt
%                     command = ['#','S','S','0','0','0',13,10]; % SYSTEM STOP
%                     fwrite(handles.serial_connection, command);
%                     set(handles.elore, 'Value', 50);
%                     set(handles.oldalra, 'Value', 140);
%                     set(handles.kameraforgat, 'Value', 0);
                end
                set(handles.cella3, 'String',cella3);

                cella2 = (round((((2^8*RxText(39) + RxText(40))/4096*3.355*108.2/26.7)-((2^8*RxText(41) + RxText(42))/4096*3.355*105.8/50.2))*100)/100);
                if (cella2 <= 3.2) % 3.2V cellafeszültség alatt
%                     command = ['#','S','S','0','0','0',13,10]; % SYSTEM STOP
%                     fwrite(handles.serial_connection, command);
%                     set(handles.elore, 'Value', 50);
%                     set(handles.oldalra, 'Value', 140);
%                     set(handles.kameraforgat, 'Value', 0);
                end
                set(handles.cella2, 'String',cella2);

                cella1 = (round(((2^8*RxText(41) + RxText(42))/4096*3.355*105.8/50.2)*100)/100);
                if (cella1 <= 3.2) % 3.2V cellafeszültség alatt
%                     command = ['#','S','S','0','0','0',13,10]; % SYSTEM STOP
%                     fwrite(handles.serial_connection, command);
%                     set(handles.elore, 'Value', 50);
%                     set(handles.oldalra, 'Value', 140);
%                     set(handles.kameraforgat, 'Value', 0);
                end
                set(handles.cella1, 'String',cella1);

                set(handles.tapfesz1, 'String',(round(((2^8*RxText(43) + RxText(44))/4096*3.355*100.8/61.9)*100)/100));  %3.31(3.2)
                set(handles.tapfesz2, 'String',(round(((2^8*RxText(45) + RxText(46))/4096*3.355*101.1/39)*100)/100));    %5.18(5.05)

                % hõszenzor, fényerõ, PING
                fenyero = (round(((2^8*RxText(49) + RxText(50))/4096*3.355)*100)/100);
                set(handles.fenyero, 'String', fenyero);
                 
                ping_feszultseg = (round(((2^8*RxText(51) + RxText(52))/4096*3.355)*100)/100);
                if (ping_feszultseg > 2.28)
                    set(handles.pingszenzor, 'String', '< 10');
                elseif (ping_feszultseg < 0.4)
                    set(handles.pingszenzor, 'String', '> 80');
                else
                    akadaly_tavolsag = (round(y1_sharp(find(x1_sharp == ping_feszultseg))*10)/10);
                    set(handles.pingszenzor, 'String', akadaly_tavolsag);
                end
                
                ho_feszultseg = ((2^8*RxText(47) + RxText(48))/4096*3.355);
                hoellenallas = (round((2000*ho_feszultseg)/(3.37 - ho_feszultseg)*10)/10);
                homerseklet = (round(y1_ho(find(x1_ho == hoellenallas))*10)/10);
                set(handles.hoszenzor, 'String', homerseklet);
                
                DCmotor_aram = (round((((((2^8*RxText(53) + RxText(54))/4096*3.355)-1.58)/20)/0.0075)*100)/100);
                if (DCmotor_aram > 0.8)
                    set(handles.motoraram, 'String', DCmotor_aram);
                elseif (DCmotor_aram - 0.27 < -0.8)
                    set(handles.motoraram, 'String', DCmotor_aram - 0.27);
                else
                    set(handles.motoraram, 'String', '0');
                end
                
                speed = (round(10000/(2^8*RxText(35) + RxText(36))/12.8125*3.6*100))/100;
                if (speed > 0.5 && speed < 20 && (~strcmp(get(handles.motoraram,'String'),'0')))
                    set(handles.sebesseg, 'String',speed);
                else
                    set(handles.sebesseg, 'String',0);
                end
            end
            uartDataNum = 1;
        elseif (uartDataNum < 56)
            uartDataNum = uartDataNum + 1;
        else
            uartDataNum = 1;
        end
    end
end
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%---------------------------- IRÁNYÍTÁS -----------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
%------------------------------- RADIO ------------------------------------
if (strcmp(get(handles.connect,'String'),'RADIO DISCONNECT') && strcmp(channel,'radiochannel'))
    eventdata.Key;
    display('radio')
    switch eventdata.Key
        case 'w'
            elore = 100 - get(handles.elore, 'Value');
            if(elore - 2 >= 40)
                set(handles.elore, 'Value', (get(handles.elore, 'Value') + 2));
                elore = 100 - get(handles.elore, 'Value');
            else
                set(handles.elore, 'Value', 60);
                elore = 40;
            end
            tizes = num2str(fix(elore/10));
            egyes = num2str(elore-(10*str2num(tizes)));
            command = ['#','D','M','0',tizes,egyes,13,10];     %35=# 68=D 77=M (PWM) 42=*
            fwrite(handles.serial_connection, command);
        case 's'
            hatra = 100 - get(handles.elore, 'Value');
            if(hatra + 2 <= 60)
                set(handles.elore, 'Value', (get(handles.elore, 'Value') - 2));
                hatra = 100 - get(handles.elore, 'Value');
            else
                set(handles.elore, 'Value', 40);
                hatra = 60;
            end
            tizes = num2str(fix(hatra/10));
            egyes = num2str(hatra-(10*str2num(tizes)));
            command = ['#','D','M','0',tizes,egyes,13,10];     %35=# 68=D 77=M (PWM) 42=*
            fwrite(handles.serial_connection, command); 
        case 'd'
            jobbra = 280 - get(handles.oldalra, 'Value');
            if(jobbra - 35 >= 105)
                set(handles.oldalra, 'Value', (get(handles.oldalra, 'Value') + 35));
                jobbra = 280 - get(handles.oldalra, 'Value');
            else
                set(handles.oldalra, 'Value', 175);
                jobbra = 105;
            end
            szazas = num2str(fix(jobbra/100));
            tizes = num2str(fix((jobbra-(100*str2num(szazas)))/10));
            egyes = num2str(jobbra-(100*str2num(szazas)+10*str2num(tizes)));
            command = ['#','S','M',szazas,tizes,egyes,13,10];     %35=# 83=S 77=M (szögelfordulás) 42=*
            fwrite(handles.serial_connection, command);
        case 'a'
            balra = 280 - get(handles.oldalra, 'Value');
            if(balra + 35 <= 175)
                set(handles.oldalra, 'Value', (get(handles.oldalra, 'Value') - 35));
                balra = 280 - get(handles.oldalra, 'Value');
            else
                set(handles.oldalra, 'Value', 105);
                balra = 175;
            end
            szazas = num2str(fix(balra/100));
            tizes = num2str(fix((balra-(100*str2num(szazas)))/10));
            egyes = num2str(balra-(100*str2num(szazas)+10*str2num(tizes)));
            command = ['#','S','M',szazas,tizes,egyes,13,10];     %35=# 83=S 77=M (szögelfordulás) 42=*
            fwrite(handles.serial_connection, command);
        case 'q'
            if(get(handles.kameraforgat, 'Value') > -180)
                set(handles.kameraforgat, 'Value', (get(handles.kameraforgat, 'Value') - 10));
            end
            command = ['#','L','B','0','1','0',13,10];     %35=# 76=L 66=B (szögelfordulás) 42=*
            fwrite(handles.serial_connection, command);
        case 'e'
            if(get(handles.kameraforgat, 'Value') < 180)
                set(handles.kameraforgat, 'Value', (get(handles.kameraforgat, 'Value') + 10));
            end
            command = ['#','L','J','0','1','0',13,10];     %35=# 76=L 74=J (szögelfordulás) 42=*
            fwrite(handles.serial_connection, command);
        case 'l'
            command = ['#','L','C','0','1','4',13,10];     %lepteto default step
            fwrite(handles.serial_connection, command);
            set(handles.kameraforgat, 'Value', 0);
        case 'space'
            command = ['#','S','S','0','0','0',13,10];     %35=# 83=S 83=S - 42=*
            fwrite(handles.serial_connection, command);
            set(handles.elore, 'Value', 50);
            set(handles.oldalra, 'Value', 140);
            set(handles.kameraforgat, 'Value', 0);
    end
end
%------------------------------- WIFI -------------------------------------
if (strcmp(get(handles.udpconnect,'String'),'WIFI DISCONNECT') && strcmp(channel,'wifichannel'))
    eventdata.Key;
    display('wifi')
    switch eventdata.Key
        case 'w'
            elore = 100 - get(handles.elore, 'Value');
            if(elore - 2 >= 40)
                set(handles.elore, 'Value', (get(handles.elore, 'Value') + 2));
                elore = 100 - get(handles.elore, 'Value');
            else
                set(handles.elore, 'Value', 60);
                elore = 40;
            end
            tizes = num2str(fix(elore/10));
            egyes = num2str(elore-(10*str2num(tizes)));
            command = ['#','D','M','0',tizes,egyes,13,10];     %35=# 68=D 77=M (PWM) 42=*
            fwrite(handles.udpConn, command);
        case 's'
            hatra = 100 - get(handles.elore, 'Value');
            if(hatra + 2 <= 60)
                set(handles.elore, 'Value', (get(handles.elore, 'Value') - 2));
                hatra = 100 - get(handles.elore, 'Value');
            else
                set(handles.elore, 'Value', 40);
                hatra = 60;
            end
            tizes = num2str(fix(hatra/10));
            egyes = num2str(hatra-(10*str2num(tizes)));
            command = ['#','D','M','0',tizes,egyes,13,10];     %35=# 68=D 77=M (PWM) 42=*
            fwrite(handles.udpConn, command); 
        case 'd'
            jobbra = 280 - get(handles.oldalra, 'Value');
            if(jobbra - 35 >= 105)
                set(handles.oldalra, 'Value', (get(handles.oldalra, 'Value') + 35));
                jobbra = 280 - get(handles.oldalra, 'Value');
            else
                set(handles.oldalra, 'Value', 175);
                jobbra = 105;
            end
            szazas = num2str(fix(jobbra/100));
            tizes = num2str(fix((jobbra-(100*str2num(szazas)))/10));
            egyes = num2str(jobbra-(100*str2num(szazas)+10*str2num(tizes)));
            command = ['#','S','M',szazas,tizes,egyes,13,10];     %35=# 83=S 77=M (szögelfordulás) 42=*
            fwrite(handles.udpConn, command);
        case 'a'
            balra = 280 - get(handles.oldalra, 'Value');
            if(balra + 35 <= 175)
                set(handles.oldalra, 'Value', (get(handles.oldalra, 'Value') - 35));
                balra = 280 - get(handles.oldalra, 'Value');
            else
                set(handles.oldalra, 'Value', 105);
                balra = 175;
            end
            szazas = num2str(fix(balra/100));
            tizes = num2str(fix((balra-(100*str2num(szazas)))/10));
            egyes = num2str(balra-(100*str2num(szazas)+10*str2num(tizes)));
            command = ['#','S','M',szazas,tizes,egyes,13,10];     %35=# 83=S 77=M (szögelfordulás) 42=*
            fwrite(handles.udpConn, command);
        case 'q'
            if(get(handles.kameraforgat, 'Value') > -180)
                set(handles.kameraforgat, 'Value', (get(handles.kameraforgat, 'Value') - 10));
            end
            command = ['#','L','B','0','1','0',13,10];     %35=# 76=L 66=B (szögelfordulás) 42=*
            fwrite(handles.udpConn, command);
        case 'e'
            if(get(handles.kameraforgat, 'Value') < 180)
                set(handles.kameraforgat, 'Value', (get(handles.kameraforgat, 'Value') + 10));
            end
            command = ['#','L','J','0','1','0',13,10];     %35=# 76=L 74=J (szögelfordulás) 42=*
            fwrite(handles.udpConn, command);
        case 'l'
            command = ['#','L','C','0','1','4',13,10];     %lepteto default step
            fwrite(handles.udpConn, command);
             set(handles.kameraforgat, 'Value', 0);
        case 'space'
            command = ['#','S','S','0','0','0',13,10];     %35=# 83=S 83=S - 42=*
            fwrite(handles.udpConn, command);
            set(handles.elore, 'Value', 50);
            set(handles.oldalra, 'Value', 140);
            set(handles.kameraforgat, 'Value', 0);
    end
end
%--------------------------------------------------------------------------
%--------------------------- STOP MOTORS ----------------------------------
%--------------------------------------------------------------------------
function stopbutton_Callback(hObject, eventdata, handles)
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
command = ['#','S','S','0','0','0',13,10];     %35=# 83=S 83=S - 42=*
if(strcmp(channel,'radiochannel'))
    fwrite(handles.serial_connection, command);
elseif(strcmp(channel,'wifichannel'))
    fwrite(handles.udpConn, command);
end
set(handles.elore, 'Value', 50);
set(handles.oldalra, 'Value', 140);
set(handles.kameraforgat, 'Value', 0);
%--------------------------------------------------------------------------
%----------------------------- TELEMETRIA ---------------------------------
%--------------------------------------------------------------------------
function telemetria1_Callback(hObject, eventdata, handles)
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
if (get(handles.telemetria1,'Value') == 1)      % Telemetria ON
    command = ['#','T','S','0','0','1',13,10];
    if (strcmp(channel,'radiochannel'))    % ha a radio csatlakoztatva van, es radios kuldes van
        fwrite(handles.serial_connection, command);
    elseif (strcmp(channel,'wifichannel')) % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
        fwrite(handles.udpConn, command);
    end
elseif (get(handles.telemetria1,'Value') == 0)      % Telemetria OFF
    command = ['#','T','S','0','0','0',13,10];     
    if (strcmp(channel,'radiochannel'))    % ha a radio csatlakoztatva van, es radios kuldes van
        fwrite(handles.serial_connection, command);
    elseif (strcmp(channel,'wifichannel')) % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
        fwrite(handles.udpConn, command);
    end
end
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%------------------------- CLOSING FUNCTION -------------------------------
%--------------------------------------------------------------------------
function figure1_CloseRequestFcn(hObject, eventdata, handles)
if isfield(handles, 'tcpConn')
    if (strcmp(get(handles.tcpconnect,'String'),'CAMERA DISCONNECT'))
        fclose(handles.tcpConn);
    end
    handles = rmfield(handles,'tcpConn');
end
if isfield(handles, 'udpConn')
    if (strcmp(get(handles.udpconnect,'String'),'WIFI DISCONNECT'))
        command = ['#','S','S','0','0','0',13,10];     %35=# 83=S 83=S - 42=*
        fwrite(handles.udpConn, command);
        fclose(handles.udpConn);
    end
    handles = rmfield(handles,'udpConn');
end
if isfield(handles, 'serial_connection')
    if (strcmp(get(handles.connect,'String'),'RADIO DISCONNECT'))
        command = ['#','S','S','0','0','0',13,10];     %35=# 83=S 83=S - 42=*
        fwrite(handles.serial_connection, command);
        fclose(handles.serial_connection);     
    end
    handles = rmfield(handles,'serial_connection');
end
delete(hObject);
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------



%--------------------------------------------------------------------------
%---------------------------- OBJEKTUMOK ----------------------------------
%--------------------------------------------------------------------------
function cameraport_Callback(~,~,~)
function cameraport_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function remoteIP_Callback(~,~,~)
function remoteIP_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function remotePort_Callback(~,~,~)
function remotePort_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function localIP_Callback(~,~,~)
function localIP_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function localPort_Callback(~,~,~)
function localPort_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function gpsaktiv_Callback(~,~,~)
function eszak_Callback(~,~,~)
function eszak_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function muholdszam_Callback(~,~,~)
function muholdszam_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function magassag_Callback(~,~,~)
function magassag_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function hdop_Callback(~,~,~)
function hdop_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function kelet_Callback(~,~,~)
function kelet_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function akkufesz_Callback(~,~,~)
function akkufesz_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function cella1_Callback(~,~,~)
function cella1_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function cella2_Callback(~,~,~)
function cella2_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function cella3_Callback(~,~,~)
function cella3_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function tapfesz1_Callback(~,~,~)
function tapfesz1_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function tapfesz2_Callback(~,~,~)
function tapfesz2_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function motoraram_Callback(~,~,~)
function motoraram_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function sebesseg_Callback(~,~,~)
function sebesseg_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function hoszenzor_Callback(~,~,~)
function hoszenzor_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function fenyero_Callback(~,~,~)
function fenyero_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function pingszenzor_Callback(~,~,~)
function pingszenzor_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function fps_Callback(~,~,~)
function fps_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function elore_Callback(~,~,~)
function elore_CreateFcn(hObject,~,~)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function oldalra_Callback(~,~,~)
function oldalra_CreateFcn(hObject,~,~)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function kameraforgat_Callback(~,~,~)
function kameraforgat_CreateFcn(hObject,~,~)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
function portselect_Callback(~,~,~)
function portselect_CreateFcn(hObject,~,~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function stream_CreateFcn(hObject, eventdata, handles)
