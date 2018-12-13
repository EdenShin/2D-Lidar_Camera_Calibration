%% step1. get camera calibration data and get Norm vector about each plane
load('Calib_Results.mat');
cameraPlanes=[];
stringRBase = 'Rc_';
stringTBase = 'Tc_';
base = 1;
%for n = selectionNumbers
while( exist([stringRBase,num2str(base)]) && exist([stringTBase,num2str(base)]) )
     rc = eval([stringRBase,num2str(base)]);
     tc = eval([stringTBase,num2str(base)]);

     plane = -rc(:,3) * dot(rc(:,3)', tc); % see cam/laser paper
     plane = -plane./1000; % in mm not m and from camera to plane not the other way around
     cameraPlanes=[cameraPlanes,plane];

     base = base + 1;
end
Nci = cameraPlanes;

%% step2. read laserdata and get initial estimation
stringlsBase='ls';
Nc = [];
Lpts = [];
run('points_data.m');
for i = 1:19
    newls = eval([stringlsBase, num2str(i)]);
    newmatchCP = repmat(Nci(:,i),1,size(newls,2));
    Lpts = [Lpts, newls];
    Nc = [Nc, newmatchCP];
end
[deltaest,phiest] = getinitest(Lpts, Nc);
rmserror=geterror(Lpts,Nc,deltaest,phiest);

%% step3. optimise transformation

[deltaest,phiest] = getinitest(Lpts, Nc,deltaest,phiest);
rmserror=geterror(Lpts,Nc,deltaest,phiest);
disp(['Initial estimate: delta:',mat2str(deltaest',3),', phi:',mat2str(rad2deg(dcm2angvec(phiest))',3),', rms error:',num2str(rmserror,3)]);


%% step4. Laser Camera Calibration
% disp('Running optimsations. Please wait.'); % no need, fast
[delta,phi] = camlasercalib(Lpts,Nc,deltaest,phiest);
rmserror=geterror(Lpts,Nc,delta,phi);
disp('Results:');
disp(['Delta:',mat2str(delta',3)]);
disp(['Phi (in degrees):',mat2str(rad2deg(dcm2angvec(phi))',3)]);
disp(['Total rms error:',num2str(rmserror,3)]);
deltaest=delta;
phiest=phi;
%% step5. Laser points into Image

% get rotation vector
phiinv=inv(phi);
 
% Get points
Lpts_test=ls2;

% change to mm (camera parameters in mm)
Lpts_test=Lpts_test.*1000;
delta=delta.*1000;

% apply laser to camera transformation
Cpts=phiinv*Lpts_test+repmat(delta,1,size(Lpts_test,2));
xc=Cpts(1,:);
yc=Cpts(2,:);
zc=Cpts(3,:);

%normalise over Z (in this frame);
a=xc./zc;
b=yc./zc;
% add distortion
r = sqrt(a.^2 + b.^2);
k = kc;
alpha = alpha_c;
ad = a.*(1 + k(1).*r.^2 + k(2).*r.^4 + k(5).*r.^6) +  2.*k(3).*a.*b + k(4).*(r.^2 + 2.*a.^2);
bd = b.*(1 + k(1).*r.^2 + k(2).*r.^4 + k(5).*r.^6) +  k(3).*(r.^2 + 2.*b.^2) + 2.*k(4).*a.*b;

% image coordinates
f = fc;
c = cc;
x = f(1).*(ad + alpha.*bd) + c(1) + 1; % add 1 for matlab coords
y = f(2).*bd + c(2) + 1; % add 1 for matlab coords