clear all
close all
clc

%----- ITU* Model for Indoor Attenuation -----
f = 433;        % frekvencia MHz-ben
N = 34;         % The distance power loss coefficient, 30-2.4GHz, 34-433MHz
d = 15;         % t�vols�g m-ben
n = 4;          % folyos�k sz�ma
Pf = 15+4*(n-1);  % the floor loss penetration factor

L = 20*log10(f)+N*log10(d)+Pf-28     % szakaszcsillap�t�s dB-ben


%----- Fresnel z�n�k ----
D = 24 /1000;       % antenn�k t�vols�ga km-ben
d = D/2;            % vizsg�lt t�vols�g, k�z�pen a legnagyobb az ellipszoid
%r = 8.657*sqrt(D/(f/1000))
r2= 17.3*sqrt((d*(D-d))/((f/1000)*D))