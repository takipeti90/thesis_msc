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
system('D:\BME\MSC\Diplomatervezes\RaspberryPi\WiFi_hotspot.bat &');    % wifi_hotspot
%----- megvilagitas szenzor gorbeje -----
global x1_feny;
global y1_feny;
y_feny=[25, 79, 127];
x_feny=[0.04 0.09 0.15];
[poly_feny,~,mu_feny] = polyfit(x_feny,y_feny,1);
x1_feny=0.01:0.001:2.15;
x1_feny = (round(x1_feny.*1000))/1000;
y1_feny = polyval(poly_feny,x1_feny,[],mu_feny);
%----- homerseklet szenzor gorbeje -----
global x1_ho;
global y1_ho;
x_ho = [498 538 581 603 626 672 722 773 826 882 940 1000];
y_ho = [0 10 20 25 30 40 50 60 70 80 90 100];
[poly_ho,~,mu_ho] = polyfit(x_ho,y_ho,10);
x1_ho = 498:0.1:1000;
x1_ho = (round(x1_ho.*10))/10;
y1_ho = polyval(poly_ho,x1_ho,[],mu_ho);
%----- ping szenzor gorbeje -----
global x1_sharp;
global y1_sharp;
global x12_sharp;
global y12_sharp;
x_sharp = [2.28 1.62 1.27 1.05 0.92 0.75 0.62 0.53 0.46 0.4];
y_sharp = [10 15 20 25 30 40 50 60 70 80]; 
[poly_sharp,~,mu_sharp] = polyfit(x_sharp,y_sharp,5);
x1_sharp = 0.4:0.01:2.28;
x1_sharp = (round(x1_sharp.*100))/100;
y1_sharp = polyval(poly_sharp,x1_sharp,[],mu_sharp);
[p2,~,mu2] = polyfit(y_sharp,x_sharp,5);
y12_sharp=10:1:80;
x12_sharp = polyval(p2,y12_sharp,[],mu2);
%----- alap kamerakep -----
fid = fopen('camera.jpg', 'rb');
b0 = fread(fid, Inf, '*uint8');
fclose(fid);
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
set(handles.remoteIP, 'String','192.168.137.2');
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
global SZERVO_PWM;
SZERVO_PWM = 140;
global LEPTETO_SZOG;
LEPTETO_SZOG = 0;
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
global LEPTETO_SZOG;
global SZERVO_PWM;
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
        set(handles.cameralight, 'Enable', 'On');
        set(handles.aramkorlat, 'Enable', 'On');
        set(handles.sebessegkorlat, 'Enable', 'On');
        set(handles.utkozeselharitas, 'Enable', 'On');
        set(handles.enable4V8, 'Enable', 'On');
        set(handles.raspireboot, 'Enable', 'On');
        set(handles.system_reset, 'Enable', 'On');
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
        set(handles.kameraforgat, 'Value', 3200);
        SZERVO_PWM = 140;
        LEPTETO_SZOG = 0;
        set(handles.telemetria1, 'Enable', 'Off');
        set(handles.cameralight, 'Enable', 'Off');
        set(handles.kameraforgat, 'Enable', 'Off');
        set(handles.stopbutton, 'Enable', 'Off');
        set(handles.elore, 'Enable', 'Off');
        set(handles.oldalra, 'Enable', 'Off');
        set(handles.aramkorlat, 'Enable', 'Off');
        set(handles.sebessegkorlat, 'Enable', 'Off');
        set(handles.utkozeselharitas, 'Enable', 'Off');
        set(handles.enable4V8, 'Enable', 'Off');
        set(handles.raspireboot, 'Enable', 'Off');
        set(handles.system_reset, 'Enable', 'Off');
        command = ['#','S','S','0','0','0',13,10];     % STOP SYSTEM
        fwrite(handles.udpConn, command);
        set(handles.elore, 'Value', 50);
        set(handles.oldalra, 'Value', 140);
        set(handles.kameraforgat, 'Value', 3200);
        SZERVO_PWM = 140;
        LEPTETO_SZOG = 0;
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
global x1_feny;
global y1_feny;
bytesAvailable = hObject.BytesAvailable;
RxText = fread(hObject,bytesAvailable)';
%dataFrom = ['U' 'D' 'P']
if (RxText(1) == '#' && RxText(59) == 13 && RxText(60) == 10) % '#' && 13(\r) && 10(\n)
    set(handles.elore, 'Value', 100 - RxText(55));
    set(handles.oldalra, 'Value', 280 - RxText(56));
    stepNumber = (2^8*RxText(57) + RxText(58));
    set(handles.kameraforgat, 'Value', stepNumber);
    
    if (RxText(21) == '1')
        set(handles.gpsaktiv,'Value',1);
        set(handles.gpsaktiv,'String','GPS AKTÍV');
        set(handles.eszak, 'String',native2unicode(RxText(2:10)))
        set(handles.kelet, 'String',native2unicode(RxText(11:20)));
        set(handles.muholdszam, 'String',native2unicode(RxText(22:23)));
        set(handles.hdop, 'String',native2unicode(RxText(24:28)));
        set(handles.magassag, 'String',native2unicode(RxText(29:34)));
    else
        set(handles.gpsaktiv,'Value',0);
        set(handles.gpsaktiv,'String','GPS INAKTÍV');
        set(handles.eszak, 'String','-')
        set(handles.kelet, 'String','-');
        set(handles.muholdszam, 'String','-');
        set(handles.hdop, 'String','-');
        set(handles.magassag, 'String','-');
    end

    speed = (round(((100*10^-6)^-1)/(2^8*RxText(35) + RxText(36))/12.8125*3.6*10))/10;
    if (speed > 0.6 && speed < 20)
        set(handles.sebesseg, 'String',speed);
    else
        set(handles.sebesseg, 'String',0);
    end
    
    akkuVoltage = (round(((2^8*RxText(37) + RxText(38))/4096*3.355*97.3/15.8)*100)/100);
    if (akkuVoltage <= 9.6) % 3.2V cellánként
        set(handles.akkufesz,'ForegroundColor',[1 0 0])
    else
        set(handles.akkufesz,'ForegroundColor',[0 0 0])
    end
    set(handles.akkufesz, 'String',akkuVoltage);

    cella3 = (round((((2^8*RxText(37) + RxText(38))/4096*3.355*97.3/15.8)-((2^8*RxText(39) + RxText(40))/4096*3.355*108.2/26.7))*100)/100);
    if (cella3 <= 3.2) % 3.2V cellafeszültség alatt
        set(handles.cella3,'ForegroundColor',[1 0 0])
    else
        set(handles.cella3,'ForegroundColor',[0 0 0])
    end
    set(handles.cella3, 'String',cella3);

    cella2 = (round((((2^8*RxText(39) + RxText(40))/4096*3.355*108.2/26.7)-((2^8*RxText(41) + RxText(42))/4096*3.355*105.8/50.2))*100)/100);
    if (cella2 <= 3.2) % 3.2V cellafeszültség alatt
        set(handles.cella2,'ForegroundColor',[1 0 0])
    else
        set(handles.cella2,'ForegroundColor',[0 0 0])
    end
    set(handles.cella2, 'String',cella2);

    cella1 = (round(((2^8*RxText(41) + RxText(42))/4096*3.355*105.8/50.2)*100)/100);
    if (cella1 <= 3.2) % 3.2V cellafeszültség alatt
        set(handles.cella1,'ForegroundColor',[1 0 0])
    else
        set(handles.cella1,'ForegroundColor',[0 0 0])
    end
    set(handles.cella1, 'String',cella1);

    set(handles.tapfesz1, 'String',(round(((2^8*RxText(43) + RxText(44))/4096*3.355*100.8/61.9)*100)/100));
    set(handles.tapfesz2, 'String',(round(((2^8*RxText(45) + RxText(46))/4096*3.355*101.1/39)*100)/100));

    % hõszenzor, fényerõ, PING
    %fenyero = 2^8*RxText(49) + RxText(50)
    fenyszenzor_fesz = (round(((2^8*RxText(49) + RxText(50))/4096*3.355)*1000)/1000);
    if(fenyszenzor_fesz < 0.01)
        fenyszenzor_fesz = 0.01;
    end
    megvilagitas =  round(y1_feny(find(x1_feny == fenyszenzor_fesz)));
    set(handles.fenyero, 'String', megvilagitas);
                 
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
                
     DCmotor_aram = (round((((2^8*RxText(53) + RxText(54))-1935)/4096*3.355/20/0.0075)*100)/100);
     if (DCmotor_aram > 0.7)
        set(handles.motoraram, 'String', DCmotor_aram);
     elseif (DCmotor_aram - 0.4 < -0.7)
        set(handles.motoraram, 'String', DCmotor_aram - 0.4);
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
        system('D:\BME\MSC\Diplomatervezes\RaspberryPi\stream\h264_stream.bat &');
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
        %system('D:\BME\MSC\Diplomatervezes\RaspberryPi\stream\stop_h264_stream.bat &');
        system('taskkill /F /IM mplayer.exe');
        %system('taskkill /F /IM nc64.exe');
        system('taskkill /F /IM cmd.exe');
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
global SZERVO_PWM;
global LEPTETO_SZOG;
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
            set(handles.cameralight, 'Enable', 'On');
            set(handles.radiochannel, 'Enable', 'On');
            set(handles.kameraforgat, 'Enable', 'Inactive');
            set(handles.elore, 'Enable', 'Inactive');
            set(handles.oldalra, 'Enable', 'Inactive');
            set(handles.refresh, 'Enable', 'Off');
            set(handles.portselect, 'Enable', 'Off');
            set(handles.aramkorlat, 'Enable', 'On');
            set(handles.sebessegkorlat, 'Enable', 'On');
            set(handles.utkozeselharitas, 'Enable', 'On');
            set(handles.enable4V8, 'Enable', 'On');
            set(handles.raspireboot, 'Enable', 'On');
            set(handles.system_reset, 'Enable', 'On');
            if (strcmp(get(handles.udpconnect,'String'),'WIFI CONNECT'))   % ha a wifi nincs connectelve valtas radiora
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
        set(handles.kameraforgat, 'Value', 3200);
        SZERVO_PWM = 140;
        LEPTETO_SZOG = 0;
        set(handles.stopbutton, 'Enable', 'Off');
        set(handles.telemetria1, 'Enable', 'Off');
        set(handles.cameralight, 'Enable', 'Off');
        set(handles.kameraforgat, 'Enable', 'Off');
        set(handles.elore, 'Enable', 'Off');
        set(handles.oldalra, 'Enable', 'Off');
        set(handles.aramkorlat, 'Enable', 'Off');
        set(handles.sebessegkorlat, 'Enable', 'Off');
        set(handles.utkozeselharitas, 'Enable', 'Off');
        set(handles.enable4V8, 'Enable', 'Off');
        set(handles.raspireboot, 'Enable', 'Off');
        set(handles.system_reset, 'Enable', 'Off');
        command = ['#','S','S','0','0','0',13,10];     % change to radio, RPi close the ports
        fwrite(handles.serial_connection, command);
        set(handles.elore, 'Value', 50);
        set(handles.oldalra, 'Value', 140);
        set(handles.kameraforgat, 'Value', 3200);
        SZERVO_PWM = 140;
        LEPTETO_SZOG = 0;
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
global x1_feny;
global y1_feny;
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
        if (uartDataNum == 60 && uartBuffer(uartDataNum-1) == 13 && uartBuffer(uartDataNum) == 10)
            %feldolgozás
            %dataFrom = ['S' 'E' 'R']
            RxText = uartBuffer;            
            if (RxText(1) == '#')
                set(handles.elore, 'Value', 100 - RxText(55));
                set(handles.oldalra, 'Value', 280 - RxText(56));
                stepNumber = (2^8*RxText(57) + RxText(58));
                set(handles.kameraforgat, 'Value', stepNumber);
                
                if (RxText(21) == '1')
                    set(handles.gpsaktiv,'Value',1);
                    set(handles.gpsaktiv,'String','GPS AKTÍV');
                    set(handles.eszak, 'String',native2unicode(RxText(2:10)))
                    set(handles.kelet, 'String',native2unicode(RxText(11:20)));
                    set(handles.muholdszam, 'String',native2unicode(RxText(22:23)));
                    set(handles.hdop, 'String',native2unicode(RxText(24:28)));
                    set(handles.magassag, 'String',native2unicode(RxText(29:34)));
                else
                    set(handles.gpsaktiv,'Value',0);
                    set(handles.gpsaktiv,'String','GPS INAKTÍV');
                    set(handles.eszak, 'String','-')
                    set(handles.kelet, 'String','-');
                    set(handles.muholdszam, 'String','-');
                    set(handles.hdop, 'String','-');
                    set(handles.magassag, 'String','-');
                end
                
            
                akkuVoltage = (round(((2^8*RxText(37) + RxText(38))/4096*3.355*97.3/15.8)*100)/100);
                if (akkuVoltage <= 9.6) % 9.6V akkufeszültség alatt
                    set(handles.akkufesz,'ForegroundColor',[1 0 0])
                else
                    set(handles.akkufesz,'ForegroundColor',[0 0 0])
                end
                set(handles.akkufesz, 'String',akkuVoltage);
                
                cella3 = (round((((2^8*RxText(37) + RxText(38))/4096*3.355*97.3/15.8)-((2^8*RxText(39) + RxText(40))/4096*3.355*108.2/26.7))*100)/100);
                if (cella3 <= 3.2) % 3.2V cellafeszültség alatt
                    set(handles.cella3,'ForegroundColor',[1 0 0])
                else
                    set(handles.cella3,'ForegroundColor',[0 0 0])
                end
                set(handles.cella3, 'String',cella3);

                cella2 = (round((((2^8*RxText(39) + RxText(40))/4096*3.355*108.2/26.7)-((2^8*RxText(41) + RxText(42))/4096*3.355*105.8/50.2))*100)/100);
                if (cella2 <= 3.2) % 3.2V cellafeszültség alatt
                    set(handles.cella2,'ForegroundColor',[1 0 0])
                else
                    set(handles.cella2,'ForegroundColor',[0 0 0])
                end
                set(handles.cella2, 'String',cella2);

                cella1 = (round(((2^8*RxText(41) + RxText(42))/4096*3.355*105.8/50.2)*100)/100);
                if (cella1 <= 3.2) % 3.2V cellafeszültség alatt
                    set(handles.cella1,'ForegroundColor',[1 0 0])
                else
                    set(handles.cella1,'ForegroundColor',[0 0 0])
                end
                set(handles.cella1, 'String',cella1);

                set(handles.tapfesz1, 'String',(round(((2^8*RxText(43) + RxText(44))/4096*3.355*100.8/61.9)*100)/100));  %3.31(3.2)
                set(handles.tapfesz2, 'String',(round(((2^8*RxText(45) + RxText(46))/4096*3.355*101.1/39)*100)/100));    %5.18(5.05)

                % hõszenzor, fényerõ, PING
                fenyszenzor_fesz = (round(((2^8*RxText(49) + RxText(50))/4096*3.355)*1000)/1000);
                if(fenyszenzor_fesz < 0.01)
                    fenyszenzor_fesz = 0.01;
                end
                megvilagitas =  round(y1_feny(find(x1_feny == fenyszenzor_fesz)));
                set(handles.fenyero, 'String', megvilagitas);
                 
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
                
                DCmotor_aram = (round((((2^8*RxText(53) + RxText(54))-1935)/4096*3.355/20/0.0075)*100)/100);
                if (DCmotor_aram > 0.7)
                    set(handles.motoraram, 'String', DCmotor_aram);
                elseif (DCmotor_aram - 0.4 < -0.7)
                    set(handles.motoraram, 'String', DCmotor_aram - 0.4);
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
        elseif (uartDataNum < 60)
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
% function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
% %------------------------------- RADIO ------------------------------------
% if (strcmp(get(handles.connect,'String'),'RADIO DISCONNECT') && strcmp(channel,'radiochannel'))
%     eventdata.Key;
%     %display('radio')
%     switch eventdata.Key
%         case 'w'
%             elore = 100 - get(handles.elore, 'Value');
%             if(elore - 2 >= 40)
%                 set(handles.elore, 'Value', (get(handles.elore, 'Value') + 2));
%                 elore = 100 - get(handles.elore, 'Value');
%             else
%                 set(handles.elore, 'Value', 60);
%                 elore = 40;
%             end
%             tizes = num2str(fix(elore/10));
%             egyes = num2str(elore-(10*str2num(tizes)));
%             command = ['#','D','M','0',tizes,egyes,13,10];     %35=# 68=D 77=M (PWM) 42=*
%             fwrite(handles.serial_connection, command);
%         case 's'
%             hatra = 100 - get(handles.elore, 'Value');
%             if(hatra + 2 <= 60)
%                 set(handles.elore, 'Value', (get(handles.elore, 'Value') - 2));
%                 hatra = 100 - get(handles.elore, 'Value');
%             else
%                 set(handles.elore, 'Value', 40);
%                 hatra = 60;
%             end
%             tizes = num2str(fix(hatra/10));
%             egyes = num2str(hatra-(10*str2num(tizes)));
%             command = ['#','D','M','0',tizes,egyes,13,10];     %35=# 68=D 77=M (PWM) 42=*
%             fwrite(handles.serial_connection, command); 
%         case 'd'
%             jobbra = 280 - get(handles.oldalra, 'Value');
%             if(jobbra - 35 >= 105)
%                 set(handles.oldalra, 'Value', (get(handles.oldalra, 'Value') + 35));
%                 jobbra = 280 - get(handles.oldalra, 'Value');
%             else
%                 set(handles.oldalra, 'Value', 175);
%                 jobbra = 105;
%             end
%             szazas = num2str(fix(jobbra/100));
%             tizes = num2str(fix((jobbra-(100*str2num(szazas)))/10));
%             egyes = num2str(jobbra-(100*str2num(szazas)+10*str2num(tizes)));
%             command = ['#','S','M',szazas,tizes,egyes,13,10];     %35=# 83=S 77=M (szögelfordulás) 42=*
%             fwrite(handles.serial_connection, command);
%         case 'a'
%             balra = 280 - get(handles.oldalra, 'Value');
%             if(balra + 35 <= 175)
%                 set(handles.oldalra, 'Value', (get(handles.oldalra, 'Value') - 35));
%                 balra = 280 - get(handles.oldalra, 'Value');
%             else
%                 set(handles.oldalra, 'Value', 105);
%                 balra = 175;
%             end
%             szazas = num2str(fix(balra/100));
%             tizes = num2str(fix((balra-(100*str2num(szazas)))/10));
%             egyes = num2str(balra-(100*str2num(szazas)+10*str2num(tizes)));
%             command = ['#','S','M',szazas,tizes,egyes,13,10];     %35=# 83=S 77=M (szögelfordulás) 42=*
%             fwrite(handles.serial_connection, command);
%         case 'q'
%             if(get(handles.kameraforgat, 'Value') > 14)
%                 set(handles.kameraforgat, 'Value', (get(handles.kameraforgat, 'Value') - 177));
%                 command = ['#','L','B','0','1','0',13,10];     %35=# 76=L 66=B (szögelfordulás) 42=*
%                 fwrite(handles.serial_connection, command);
%             end
%         case 'e'
%             if(get(handles.kameraforgat, 'Value') < 6386)
%                 set(handles.kameraforgat, 'Value', (get(handles.kameraforgat, 'Value') + 177));
%                 command = ['#','L','J','0','1','0',13,10];     %35=# 76=L 74=J (szögelfordulás) 42=*
%                 fwrite(handles.serial_connection, command);
%             end
%         case 'l'
%             command = ['#','L','C','0','1','4',13,10];     %lepteto default step
%             fwrite(handles.serial_connection, command);
%             set(handles.kameraforgat, 'Value', 3200);
%         case 'space'
%             command = ['#','S','S','0','0','0',13,10];     %35=# 83=S 83=S - 42=*
%             fwrite(handles.serial_connection, command);
%             set(handles.elore, 'Value', 50);
%             set(handles.oldalra, 'Value', 140);
%             set(handles.kameraforgat, 'Value', 3200);
%     end
% end
% %------------------------------- WIFI -------------------------------------
% if (strcmp(get(handles.udpconnect,'String'),'WIFI DISCONNECT') && strcmp(channel,'wifichannel'))
%     eventdata.Key;
%     %display('wifi')
%     switch eventdata.Key
%         case 'w'
%             elore = 100 - get(handles.elore, 'Value');
%             if(elore - 2 >= 40)
%                 set(handles.elore, 'Value', (get(handles.elore, 'Value') + 2));
%                 elore = 100 - get(handles.elore, 'Value');
%             else
%                 set(handles.elore, 'Value', 60);
%                 elore = 40;
%             end
%             tizes = num2str(fix(elore/10));
%             egyes = num2str(elore-(10*str2num(tizes)));
%             command = ['#','D','M','0',tizes,egyes,13,10];     %35=# 68=D 77=M (PWM) 42=*
%             fwrite(handles.udpConn, command);
%         case 's'
%             hatra = 100 - get(handles.elore, 'Value');
%             if(hatra + 2 <= 60)
%                 set(handles.elore, 'Value', (get(handles.elore, 'Value') - 2));
%                 hatra = 100 - get(handles.elore, 'Value');
%             else
%                 set(handles.elore, 'Value', 40);
%                 hatra = 60;
%             end
%             tizes = num2str(fix(hatra/10));
%             egyes = num2str(hatra-(10*str2num(tizes)));
%             command = ['#','D','M','0',tizes,egyes,13,10];     %35=# 68=D 77=M (PWM) 42=*
%             fwrite(handles.udpConn, command); 
%         case 'd'
%             jobbra = 280 - get(handles.oldalra, 'Value');
%             if(jobbra - 35 >= 105)
%                 set(handles.oldalra, 'Value', (get(handles.oldalra, 'Value') + 35));
%                 jobbra = 280 - get(handles.oldalra, 'Value');
%             else
%                 set(handles.oldalra, 'Value', 175);
%                 jobbra = 105;
%             end
%             szazas = num2str(fix(jobbra/100));
%             tizes = num2str(fix((jobbra-(100*str2num(szazas)))/10));
%             egyes = num2str(jobbra-(100*str2num(szazas)+10*str2num(tizes)));
%             command = ['#','S','M',szazas,tizes,egyes,13,10];     %35=# 83=S 77=M (szögelfordulás) 42=*
%             fwrite(handles.udpConn, command);
%         case 'a'
%             balra = 280 - get(handles.oldalra, 'Value');
%             if(balra + 35 <= 175)
%                 set(handles.oldalra, 'Value', (get(handles.oldalra, 'Value') - 35));
%                 balra = 280 - get(handles.oldalra, 'Value');
%             else
%                 set(handles.oldalra, 'Value', 105);
%                 balra = 175;
%             end
%             szazas = num2str(fix(balra/100));
%             tizes = num2str(fix((balra-(100*str2num(szazas)))/10));
%             egyes = num2str(balra-(100*str2num(szazas)+10*str2num(tizes)));
%             command = ['#','S','M',szazas,tizes,egyes,13,10];     %35=# 83=S 77=M (szögelfordulás) 42=*
%             fwrite(handles.udpConn, command);
%         case 'q'
%             if(get(handles.kameraforgat, 'Value') > 14)
%                 set(handles.kameraforgat, 'Value', (get(handles.kameraforgat, 'Value') - 177));
%                 command = ['#','L','B','0','1','0',13,10];     %35=# 76=L 66=B (szögelfordulás) 42=*
%                 fwrite(handles.udpConn, command);
%             end
%         case 'e'
%             if(get(handles.kameraforgat, 'Value') < 6386)
%                 set(handles.kameraforgat, 'Value', (get(handles.kameraforgat, 'Value') + 177));
%                 command = ['#','L','J','0','1','0',13,10];     %35=# 76=L 74=J (szögelfordulás) 42=*
%                 fwrite(handles.udpConn, command);
%             end
%         case 'l'
%             command = ['#','L','C','0','1','4',13,10];     %lepteto default step
%             fwrite(handles.udpConn, command);
%              set(handles.kameraforgat, 'Value', 3200);
%         case 'space'
%             command = ['#','S','S','0','0','0',13,10];     %35=# 83=S 83=S - 42=*
%             fwrite(handles.udpConn, command);
%             set(handles.elore, 'Value', 50);
%             set(handles.oldalra, 'Value', 140);
%             set(handles.kameraforgat, 'Value', 3200);
%     end
% end
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
global SZERVO_PWM;
global LEPTETO_SZOG;
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
%------------------------------- RADIO ------------------------------------
if (strcmp(get(handles.connect,'String'),'RADIO DISCONNECT') && strcmp(channel,'radiochannel'))
    eventdata.Key;
    %display('radio')
    switch eventdata.Key
        case 'w'
            command = ['#','D','F','0','0','0',13,10];     % DC forward +1
            fwrite(handles.serial_connection, command);
        case 's'
            command = ['#','D','B','0','0','0',13,10];     % DC backward -1
            fwrite(handles.serial_connection, command);
        case 'd'
            command = ['#','S','J','0','0','0',13,10];
            fwrite(handles.serial_connection, command);
        case 'a'
            command = ['#','S','B','0','0','0',13,10];
            fwrite(handles.serial_connection, command);
        case 'q'
            command = ['#','L','B','0','1','0',13,10];     % 35=# 76=L 66=B (szögelfordulás) 42=*
            fwrite(handles.serial_connection, command);
        case 'e'
            command = ['#','L','J','0','1','0',13,10];     % 35=# 76=L 66=B (szögelfordulás) 42=*
            fwrite(handles.serial_connection, command);
        case 'l'
            command = ['#','L','C','0','1','4',13,10];     % lepteto default step
            fwrite(handles.serial_connection, command);
        case 'space'
            command = ['#','S','S','0','0','0',13,10];     % 35=# 83=S 83=S - 42=*
            fwrite(handles.serial_connection, command);
    end
end
%------------------------------- WIFI -------------------------------------
if (strcmp(get(handles.udpconnect,'String'),'WIFI DISCONNECT') && strcmp(channel,'wifichannel'))
    eventdata.Key;
    %display('wifi')
    switch eventdata.Key
        case 'w'
            command = ['#','D','F','0','0','0',13,10];     % DC forward +1
            fwrite(handles.udpConn, command);
        case 's'
            command = ['#','D','B','0','0','0',13,10];     % DC backward -1
            fwrite(handles.udpConn, command); 
        case 'd'
            command = ['#','S','J','0','0','0',13,10];
            fwrite(handles.udpConn, command);
        case 'a'
            command = ['#','S','B','0','0','0',13,10];
            fwrite(handles.udpConn, command);
        case 'q'
            command = ['#','L','B','0','1','0',13,10];     % 35=# 76=L 66=B (szögelfordulás) 42=*
            fwrite(handles.udpConn, command);
        case 'e'
            command = ['#','L','J','0','1','0',13,10];     % 35=# 76=L 66=B (szögelfordulás) 42=*
            fwrite(handles.udpConn, command);
        case 'l'
            command = ['#','L','C','0','1','4',13,10];     % lepteto default step
            fwrite(handles.udpConn, command);
        case 'space'
            command = ['#','S','S','0','0','0',13,10];     % 35=# 83=S 83=S - 42=*
            fwrite(handles.udpConn, command);
    end
end
%--------------------------------------------------------------------------
%--------------------------- STOP MOTORS ----------------------------------
%--------------------------------------------------------------------------
function stopbutton_Callback(hObject, eventdata, handles)
global SZERVO_PWM;
global LEPTETO_SZOG;
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
command = ['#','S','S','0','0','0',13,10];     %35=# 83=S 83=S - 42=*
if(strcmp(channel,'radiochannel'))
    fwrite(handles.serial_connection, command);
elseif(strcmp(channel,'wifichannel'))
    fwrite(handles.udpConn, command);
end
set(handles.elore, 'Value', 50);
set(handles.oldalra, 'Value', 140);
set(handles.kameraforgat, 'Value', 3200);
SZERVO_PWM = 140;
LEPTETO_SZOG = 0;
%--------------------------------------------------------------------------
%----------------------------- TELEMETRIA ---------------------------------
%--------------------------------------------------------------------------
function telemetria1_Callback(hObject, eventdata, handles)
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
if (get(handles.telemetria1,'Value') == 1)      % Telemetria ON
    set(handles.akkufesz, 'Enable', 'Inactive')
    set(handles.cella1, 'Enable', 'Inactive')
    set(handles.cella2, 'Enable', 'Inactive')
    set(handles.cella3, 'Enable', 'Inactive')
    set(handles.tapfesz1, 'Enable', 'Inactive')
    set(handles.tapfesz2, 'Enable', 'Inactive')
    set(handles.motoraram, 'Enable', 'Inactive')
    set(handles.sebesseg, 'Enable', 'Inactive')
    set(handles.hoszenzor, 'Enable', 'Inactive')
    set(handles.fenyero, 'Enable', 'Inactive')
    set(handles.pingszenzor, 'Enable', 'Inactive')
    set(handles.gpsaktiv, 'Enable', 'Inactive')
    set(handles.eszak, 'Enable', 'Inactive')
    set(handles.kelet, 'Enable', 'Inactive')
    set(handles.muholdszam, 'Enable', 'Inactive')
    set(handles.magassag, 'Enable', 'Inactive')
    set(handles.hdop, 'Enable', 'Inactive');
    command = ['#','T','S','0','0','1',13,10];
    if (strcmp(channel,'radiochannel'))    % ha a radio csatlakoztatva van, es radios kuldes van
        fwrite(handles.serial_connection, command);
    elseif (strcmp(channel,'wifichannel')) % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
        fwrite(handles.udpConn, command);
    end
elseif (get(handles.telemetria1,'Value') == 0)      % Telemetria OFF
    set(handles.akkufesz, 'Enable', 'Off')
    set(handles.akkufesz, 'String', '')
    set(handles.cella1, 'Enable', 'Off')
    set(handles.cella1, 'String', '')
    set(handles.cella2, 'Enable', 'Off')
    set(handles.cella2, 'String', '')
    set(handles.cella3, 'Enable', 'Off')
    set(handles.cella3, 'String', '')
    set(handles.tapfesz1, 'Enable', 'Off')
    set(handles.tapfesz1, 'String', '')
    set(handles.tapfesz2, 'Enable', 'Off')
    set(handles.tapfesz2, 'String', '')
    set(handles.motoraram, 'Enable', 'Off')
    set(handles.motoraram, 'String', '')
    set(handles.sebesseg, 'Enable', 'Off')
    set(handles.sebesseg, 'String', '')
    set(handles.hoszenzor, 'Enable', 'Off')
    set(handles.hoszenzor, 'String', '')
    set(handles.fenyero, 'Enable', 'Off')
    set(handles.fenyero, 'String', '')
    set(handles.pingszenzor, 'Enable', 'Off')
    set(handles.pingszenzor, 'String', '')
    set(handles.gpsaktiv, 'Enable', 'Off')
    set(handles.gpsaktiv, 'Value', 0)
    set(handles.eszak, 'Enable', 'Off')
    set(handles.eszak, 'String', '')
    set(handles.kelet, 'Enable', 'Off')
    set(handles.kelet, 'String', '')
    set(handles.muholdszam, 'Enable', 'Off')
    set(handles.muholdszam, 'String', '')
    set(handles.magassag, 'Enable', 'Off')
    set(handles.magassag, 'String', '')
    set(handles.hdop, 'Enable', 'Off');
    set(handles.hdop, 'String', '')
    command = ['#','T','S','0','0','0',13,10];     
    if (strcmp(channel,'radiochannel'))    % ha a radio csatlakoztatva van, es radios kuldes van
        fwrite(handles.serial_connection, command);
    elseif (strcmp(channel,'wifichannel')) % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
        fwrite(handles.udpConn, command);
    end
end
%--------------------------------------------------------------------------
%------------------------- HATTERVILAGITAS --------------------------------
%--------------------------------------------------------------------------
function cameralight_Callback(hObject, eventdata, handles)
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
if (get(handles.cameralight,'Value') == 1)      % vilagitas ON
    command = ['#','K','V','0','0','1',13,10]
    if (strcmp(channel,'radiochannel'))    % ha a radio csatlakoztatva van, es radios kuldes van
        fwrite(handles.serial_connection, command);
    elseif (strcmp(channel,'wifichannel')) % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
        fwrite(handles.udpConn, command);
    end
elseif (get(handles.cameralight,'Value') == 0)      % vilagitas OFF
    command = ['#','K','V','0','0','0',13,10]
    if (strcmp(channel,'radiochannel'))    % ha a radio csatlakoztatva van, es radios kuldes van
        fwrite(handles.serial_connection, command);
    elseif (strcmp(channel,'wifichannel')) % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
        fwrite(handles.udpConn, command);
    end
end
%--------------------------------------------------------------------------
%------------------------- 4V8 ENABLE -------------------------------------
%--------------------------------------------------------------------------
function enable4V8_Callback(hObject, eventdata, handles)
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
if (get(handles.enable4V8,'Value') == 1)        % 4V8 ENABLE ON
    command = ['#','K','T','0','0','1',13,10];
    if (strcmp(channel,'radiochannel'))         % ha a radio csatlakoztatva van, es radios kuldes van
        fwrite(handles.serial_connection, command);
    elseif (strcmp(channel,'wifichannel'))      % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
        fwrite(handles.udpConn, command);
    end
elseif (get(handles.enable4V8,'Value') == 0)      % 4V8 ENABLE OFF
    command = ['#','K','T','0','0','0',13,10];
    if (strcmp(channel,'radiochannel'))         % ha a radio csatlakoztatva van, es radios kuldes van
        fwrite(handles.serial_connection, command);
    elseif (strcmp(channel,'wifichannel'))      % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
        fwrite(handles.udpConn, command);
    end
    set(handles.wifichannel, 'Value', 0);
    set(handles.radiochannel, 'Value', 1);
end
%--------------------------------------------------------------------------
%---------------------- REBOOT RASPBERRY PI -------------------------------
%--------------------------------------------------------------------------
function raspireboot_Callback(hObject, eventdata, handles)
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
command = ['#','R','P','0','0','6',13,10];
if (strcmp(channel,'radiochannel'))         % ha a radio csatlakoztatva van, es radios kuldes van
    fwrite(handles.serial_connection, command);
elseif (strcmp(channel,'wifichannel'))      % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
    fwrite(handles.udpConn, command);
end
set(handles.wifichannel, 'Value', 0);
set(handles.radiochannel, 'Value', 1);
%--------------------------------------------------------------------------
%------------------------- ARAMKORLAT -------------------------------------
%--------------------------------------------------------------------------
function aramkorlat_Callback(hObject, eventdata, handles)
aramkorlat = get(handles.aramkorlat, 'String');
aramkorlat = round(str2num(aramkorlat)*10)/10;
if(aramkorlat > 9.9)
    aramkorlat = 9.9;
elseif(aramkorlat < 1.2)
    aramkorlat = 1.2;
end
set(handles.aramkorlat, 'String',aramkorlat);
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
egyes = num2str(fix(aramkorlat));
tizedes = num2str((aramkorlat-str2num(egyes))*10);
command = ['#','A','K',egyes,'.',tizedes,13,10];
if(strcmp(channel,'radiochannel'))
    fwrite(handles.serial_connection, command);
elseif(strcmp(channel,'wifichannel'))
    fwrite(handles.udpConn, command);
end
%--------------------------------------------------------------------------
%------------------------ SEBESSEGKORLAT ----------------------------------
%--------------------------------------------------------------------------
function sebessegkorlat_Callback(hObject, eventdata, handles)
sebessegkorlat = get(handles.sebessegkorlat, 'String');
sebessegkorlat = round(str2num(sebessegkorlat));
if(sebessegkorlat < 2)
    sebessegkorlat = 2;
elseif(sebessegkorlat > 20)
    sebessegkorlat = 20;
end
set(handles.sebessegkorlat, 'String',sebessegkorlat);
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
szazas = num2str(fix(sebessegkorlat/100));
tizes = num2str(fix((sebessegkorlat-(100*str2num(szazas)))/10));
egyes = num2str(sebessegkorlat-(100*str2num(szazas)+10*str2num(tizes)));
command = ['#','S','K',szazas,tizes,egyes,13,10];
if(strcmp(channel,'radiochannel'))
    fwrite(handles.serial_connection, command);
elseif(strcmp(channel,'wifichannel'))
    fwrite(handles.udpConn, command);
end
%--------------------------------------------------------------------------
%----------------------- UTKOZESELHARITAS ---------------------------------
%--------------------------------------------------------------------------
function utkozeselharitas_Callback(hObject, eventdata, handles)
global x12_sharp;
global y12_sharp;
utkozeselharitas = get(handles.utkozeselharitas, 'String');
utkozeselharitas = round(str2num(utkozeselharitas));
if(utkozeselharitas < 20)
    utkozeselharitas = 20;
elseif(utkozeselharitas > 70)
    utkozeselharitas = 70;
end
set(handles.utkozeselharitas, 'String',utkozeselharitas);
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
pingfesz = round(100*(x12_sharp(find(y12_sharp == utkozeselharitas))));
szazas = num2str(fix(pingfesz/100));
tizes = num2str(fix((pingfesz-(100*str2num(szazas)))/10));
egyes = num2str(pingfesz-(100*str2num(szazas)+10*str2num(tizes)));
command = ['#','U','E',szazas,tizes,egyes,13,10];
if(strcmp(channel,'radiochannel'))
    fwrite(handles.serial_connection, command);
elseif(strcmp(channel,'wifichannel'))
    fwrite(handles.udpConn, command);
end
%--------------------------------------------------------------------------
%--------------------------- SYSTEM RESET ---------------------------------
%--------------------------------------------------------------------------
function system_reset_Callback(hObject, eventdata, handles)
channel = get(get(handles.channel,'SelectedObject'), 'Tag');    % radio vagy wifi channel
command = ['#','S','R','0','0','0',13,10];
if (strcmp(channel,'radiochannel'))         % ha a radio csatlakoztatva van, es radios kuldes van
    fwrite(handles.serial_connection, command);
elseif (strcmp(channel,'wifichannel'))      % ha a WIFI csatlakoztatva van, es WIFIs kuldes van
    fwrite(handles.udpConn, command);
end
close(gcbf)
diplomamunka
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%------------------------- CLOSING FUNCTION -------------------------------
%--------------------------------------------------------------------------
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
%system('D:\BME\MSC\Diplomatervezes\RaspberryPi\WiFi_hotspot_STOP.bat &');    % wifi_hotspot_STOP
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

function aramkorlat_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function sebessegkorlat_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function utkozeselharitas_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end