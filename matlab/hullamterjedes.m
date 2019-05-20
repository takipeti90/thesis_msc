clear all
close all
clc

%----- ITU* Model for Indoor Attenuation -----
f = 433;        % frekvencia MHz-ben
N = 34;         % The distance power loss coefficient, 30-2.4GHz, 34-433MHz
d = 15;         % távolság m-ben
n = 4;          % folyosók száma
Pf = 15+4*(n-1);  % the floor loss penetration factor

L = 20*log10(f)+N*log10(d)+Pf-28     % szakaszcsillapítás dB-ben


%----- Fresnel zónák ----
D = 24 /1000;       % antennák távolsága km-ben
d = D/2;            % vizsgált távolság, középen a legnagyobb az ellipszoid
%r = 8.657*sqrt(D/(f/1000))
r2= 17.3*sqrt((d*(D-d))/((f/1000)*D))