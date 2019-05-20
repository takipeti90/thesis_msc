clear all
close all
clc
% get a stream of bytes representing an endcoded JPEG image
% (in your case you have this by decoding the base64 string)
fid = fopen('img.jpg', 'rb');
b = fread(fid, Inf, '*uint8');
fclose(fid);
% tic
figure(1);
% toc
% tic
% decode image stream using Java
jImg = javax.imageio.ImageIO.read(java.io.ByteArrayInputStream(b));
h = jImg.getHeight;
w = jImg.getWidth;
% convert Java Image to MATLAB image
p = reshape(typecast(jImg.getData.getDataStorage, 'uint8'), [3,w,h]);
img = cat(3, transpose(reshape(p(3,:,:), [w,h])), transpose(reshape(p(2,:,:), [w,h])), transpose(reshape(p(1,:,:), [w,h])));
% check results against directly reading the image using IMREAD
% toc
%tic
%image(img);
%toc


% get a stream of bytes representing an endcoded JPEG image
% (in your case you have this by decoding the base64 string)
fid2 = fopen('img2.jpg', 'rb');
b2 = fread(fid2, Inf, '*uint8');
fclose(fid2);
% decode image stream using Java
jImg = javax.imageio.ImageIO.read(java.io.ByteArrayInputStream(b2));
h2 = jImg.getHeight;
w2 = jImg.getWidth;
% convert Java Image to MATLAB image
p2 = reshape(typecast(jImg.getData.getDataStorage, 'uint8'), [3,w2,h2]);
img2 = cat(3, transpose(reshape(p2(3,:,:), [w2,h2])), transpose(reshape(p2(2,:,:), [w2,h2])), transpose(reshape(p2(1,:,:), [w2,h2])));
% check results against directly reading the image using IMREAD

fid3 = fopen('img3.jpg', 'rb');
b3 = fread(fid3, Inf, '*uint8');
fclose(fid3);
% decode image stream using Java
jImg = javax.imageio.ImageIO.read(java.io.ByteArrayInputStream(b3));
h3 = jImg.getHeight;
w3 = jImg.getWidth;
% convert Java Image to MATLAB image
p3 = reshape(typecast(jImg.getData.getDataStorage, 'uint8'), [3,w3,h3]);
img3 = cat(3, transpose(reshape(p3(3,:,:), [w3,h3])), transpose(reshape(p3(2,:,:), [w3,h3])), transpose(reshape(p3(1,:,:), [w3,h3])));
% check results against directly reading the image using IMREAD

fid4 = fopen('img4.jpg', 'rb');
b4 = fread(fid4, Inf, '*uint8');
fclose(fid4);
% decode image stream using Java
jImg = javax.imageio.ImageIO.read(java.io.ByteArrayInputStream(b4));
h4 = jImg.getHeight;
w4 = jImg.getWidth;
% convert Java Image to MATLAB image
p4 = reshape(typecast(jImg.getData.getDataStorage, 'uint8'), [3,w4,h4]);
img4 = cat(3, transpose(reshape(p4(3,:,:), [w4,h4])), transpose(reshape(p4(2,:,:), [w4,h4])), transpose(reshape(p4(1,:,:), [w4,h4])));
% check results against directly reading the image using IMREAD
tic
image(img4);
toc
tic
image(img3);
toc
tic
image(img2);
toc
tic
image(img);
toc