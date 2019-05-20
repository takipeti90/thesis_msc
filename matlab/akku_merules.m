clear all
close all
clc

uresjarasi0 = 12.6;
uresjarasi1 = 10.45;
fesz = [12.56 12.40 12.31 12.23 12.15 12.07 12.00 11.92 11.86 11.79 11.73 11.67 11.61 11.56 11.52 11.48 11.44 ...
        11.41 11.38 11.35 11.32 11.30 11.27 11.24 11.21 11.18 11.15 11.11 11.07 11.02 10.95 10.84 10.62 10.15 9.60 8.76];
aram = [1.81 1.78 1.76 1.75 1.74 1.73 1.72 1.71 1.70 1.69 1.68 1.67 1.67 1.66 1.65 1.65 1.64 1.64 1.63 1.63 ...
        1.62 1.62 1.61 1.61 1.61 1.60 1.60 1.59 1.59 1.58 1.57 1.55 1.52 1.46 1.37 1.24];
fesz2 = [12.56];
aram2 = [0];

for i=1:length(fesz)-1
   fesz2(i+1) = (fesz(i)+fesz(i+1))/2;
   aram2(i+1) = (aram(i)+aram(i+1))/2;
end

%fesz2 = [fesz2 8.76];
%aram2 = [aram2 1.24];
    
teljesitmeny = fesz2.*aram2;
energia = [teljesitmeny(1:34)*3/60, teljesitmeny(35:36)*1/60];
ellenallas = sum(fesz./aram)/length(fesz);
ido = 0:3:99;
ido = [ido 100 101];

%terhelt kapocsfeszültség
%plot(ido, fesz)
box on
plot(cumsum(energia), fesz2, 'LineWidth',3);
axis([0,33,9,12.8])
set(gca, 'XTick', [0:1:35])
set(gca, 'YTick', [8:0.2:13])
title('Az akkumulátor E-U görbéje','FontSize', 15,'fontweight','bold')
xlabel('Energia [Wh]','fontweight','bold')
ylabel('Terhelt kapocsfeszültség [V]','fontweight','bold')
grid on


% hl = plot(cumsum(energia), fesz, 'LineWidth',3);
% datacursormode on
% wbdf = get(gcf,'WindowButtonDownFcn');
% dcm = wbdf{3}{2};
% props.Position = [1 12.56];
% dcm.createDatatip(hl,props);