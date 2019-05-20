clear all
close all
clc

% fenyero szenzor
y=[25, 79, 127];
x=[0.04 0.09 0.15];
[p,~,mu] = polyfit(x,y,1);
x1=0.01:0.001:2.15;
x1 = (round(x1.*1000))/1000;
y1 = polyval(p,x1,[],mu);


% sharp szenzor
% y=[10 15 20 25 30 40 50 60 70 80];
% x=[2.28 1.62 1.27 1.05 0.92 0.75 0.62 0.53 0.46 0.4];
% [p,~,mu] = polyfit(x,y,5);
% x1=2.28:-0.01:0.4;
% x1 = (round(x1.*100))/100;
% y1 = polyval(p,x1,[],mu);
% [p2,~,mu2] = polyfit(y,x,5);
% y12=10:1:80;
% x12 = polyval(p2,y12,[],mu2);

% % homerseklet szenzor
% x = [498 538 581 603 626 672 722 773 826 882 940 1000];
% y = [0 10 20 25 30 40 50 60 70 80 90 100];
% [p,~,mu] = polyfit(x,y,10);
% x1 = 498:0.1:1000;
% y1 = polyval(p,x1,[],mu);

%find(x1 == 0.15);
round(y1(find(x1 == 0.119)))

% akadaly tavolsaghoz tartozo feszultseg
%round(100*x12(find(y12 == 23)))
%y1(find(x1 == 1.12))

hold on
grid on
plot(x,y)
plot(x1,y1)




