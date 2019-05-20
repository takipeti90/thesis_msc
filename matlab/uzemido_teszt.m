clear all
close all
clc

%system('D:\BME\MSC\Diplomatervezes\RaspberryPi\WiFi_hotspot.bat &');    % wifi_hotspot
pause(5)

%--------- SOROS kapcsolat ----------
serConn = serial('COM5','BaudRate',115200,'DataBits',8,'StopBits',1);
serConn.InputBufferSize = 5242880;
fopen(serConn);
pause(2);   % wait 2 sec
%---------- UDP kapcsolat -----------
udpConn = udp('192.168.137.2',50001,'LocalPort',50000);
udpConn.InputBufferSize = 5242880;
fopen(udpConn);
pause(2);   % wait 2 sec

%------------------------------------
%----------- UZEMIDO TESZT ----------
%------------------------------------
% command = ['#','R','P','0','0','3',13,10];     % H.264 stream ON
% fwrite(udpConn, command);
% pause(2);
% command = ['#','R','E','0','0','1',13,10];     % valtas radiora
% fwrite(serConn, command);
% pause(2);
% for ciklus = 1:42
%     tic
%     command = ['#','D','F','0','0','0',13,10];     % eloremenet 45%
%     fwrite(serConn, command);
%     pause(2);
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','S','M','1','0','5',13,10];     % kanyarodás jobbra
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','S','M','1','7','5',13,10];     % kanyarodás balra
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','S','M','1','4','0',13,10];     % kanyarodás balra
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','S','S','0','0','0',13,10];     % system stop
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','K','V','0','0','1',13,10];     % vilagitas ON
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','L','J','0','9','0',13,10];     % léptetõ jobbra
%     fwrite(serConn, command);
%     pause(5);
%     command = ['#','L','B','0','9','0',13,10];     % léptetõ balra
%     fwrite(serConn, command);
%     pause(5);
%     command = ['#','K','V','0','0','0',13,10];     % vilagitas OFF
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','D','B','0','0','0',13,10];     % hatramenet 65%
%     fwrite(serConn, command);
%     pause(2);
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','S','M','1','7','5',13,10];     % kanyarodás balra
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','S','M','1','0','5',13,10];     % kanyarodás balra
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','S','M','1','4','0',13,10];     % kanyarodás balra
%     fwrite(serConn, command);
%     pause(1);
%     command = ['#','S','S','0','0','0',13,10];     % system stop
%     fwrite(serConn, command);
%     pause(5);
%     toc
%     ciklus
% end
command = ['#','S','M','1','0','5',13,10];     % kanyarodás jobbra
    fwrite(serConn, command);
    pause(1);
    
command = ['#','D','M','0','4','0',13,10];     % kanyarodás jobbra
command = ['#','S','S','0','0','0',13,10];
    fwrite(serConn, command);
    pause(1);
%------------------------------------
%------------------------------------
%------------------------------------
fclose(serConn);
fclose(udpConn);

%system('D:\BME\MSC\Diplomatervezes\RaspberryPi\WiFi_hotspot_STOP.bat &');    % wifi_hotspot_STOP
pause(5)

clear all
close all
clc