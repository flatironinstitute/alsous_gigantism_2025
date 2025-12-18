clc; clear;
global N
filename = 'visual_s58.h5';
velocity = h5read(filename,'/tasks/u'); velocity = velocity.r;
nfield   = h5read(filename,'/tasks/n'); nfield   = nfield.r;
qtensor  = h5read(filename,'/tasks/Q'); qtensor  = qtensor.r;

% Load velocity and polarity
u = velocity(:,:,1,:);    v = velocity(:,:,2,:); 
U = permute(u,[1 2 4 3]); V = permute(v,[1 2 4 3]);
U = [U U(:,1,:)];         V = [V V(:,1,:)]; % This is added to pad the zero angle at the end

nt = nfield(:,:,1,:);   nr = nfield(:,:,2,:); 
nt = permute(nt,[1 2 4 3]); nr = permute(nr,[1 2 4 3]); 
nt = [nt nt(:,1,:)];         nr = [nr nr(:,1,:)]; % This is added to pad the zero angle at the end


% Arrange Q-tensor data
Q11 = qtensor(:,:,1,1,:); Q12 = qtensor(:,:,1,2,:); Q22 = qtensor(:,:,2,2,:); 
Q11 = permute(Q11,[1 2 5 3 4]); Q12 = permute(Q12,[1 2 5 3 4]); Q22 = permute(Q22,[1 2 5 3 4]);

Q11 = [Q11 Q11(:,1,:)]; Q12 = [Q12 Q12(:,1,:)]; Q22 = [Q22 Q22(:,1,:)]; 

time = h5read(filename,'/scales/sim_time');
iter= length(time); 
%-----------------------------------------------------------------------------------------------------
% Load the grid for the data
hinf = h5info(filename);
fname= {hinf.Groups(1).Datasets.Name}; 
phi_var = append('/scales/',fname{3}); r_var = append('/scales/',fname{4});

phi  = h5read(filename,phi_var); mt = length(phi);
r    = h5read(filename,r_var);   mr = length(r);
M    = max([mt,mr]);

% Make angle periodic for plotting
theta = [phi' 0];

% Disc geometry
r = r-r(1); L = r(end);

% Grid-to-plot
[Theta, R] = meshgrid(theta, r);
X = R.*cos(Theta); Y = R.*sin(Theta);

% Set up the cartesian interpolant domain
x = linspace(-L,L,M); 
[Xc,Yc] = meshgrid(x,x);
mask = ones(M,M); mask(Xc.^2+Yc.^2 > L^2) = NaN;
Xcart = Xc.*mask; Ycart = Yc.*mask; L = 2*L;

% Colormap properties
pl = 1:ceil(M/40):M; 

% disk plot 
tt = linspace(0,2*pi,200); xcirc = r(end)*cos(tt); ycirc = r(end)*sin(tt); 

for i = iter
    % Definep data that will bce used to plot 
    ut = U(:,:,i); ur = V(:,:,i); 
    Nt = nt(:,:,i);Nr = nr(:,:,i);
    
    % Components of the Q-tensor
    qtt=Q11(:,:,i); qtr=Q12(:,:,i); qrr=Q22(:,:,i);
    [Qxx,Qxy,Qyy] = pol2cartens(qtt,qtr,qrr,theta);
    
    % Convert to cartesian coordinaes
    [u , v] = pol2carvec(ut,ur,theta);
    [nx, ny]= pol2carvec(Nt,Nr,theta);


    % Compute data on a cartesian grid for plotting 
    uc = scatinterp(X,Y, u,Xc,Yc); vc = scatinterp(X,Y, v,Xc,Yc);
    uc = uc.*mask; vc = vc.*mask;

    nxc= scatinterp(X,Y,nx,Xc,Yc); nyc= scatinterp(X,Y,ny,Xc,Yc);
    nxc= nxc.*mask; nyc= nyc.*mask;

    Qxx = scatinterp(X,Y, Qxx,Xc,Yc); Qxy = scatinterp(X,Y, Qxy,Xc,Yc);
    Qxx = Qxx.*mask; Qxy = Qxy.*mask; 
end

% Pick the point where we want to evaluate psi
[qxc,qyc,lam] = scalOP(Qxx,Qxy,1-Qxx);
nmag = sqrt(nxc.^2+nyc.^2);
I = 1:1:length(qxc); [I,J] = meshgrid(I,I);

figure(1)
set(gcf,'position',[800 1170  1000 500])

subplot(1,2,1)
pcolor(lam); shading interp; hold on; axis square; clim([0.5 1]);  colorbar
del = 3; ex= del*qxc(pl,pl); ey= del*qyc(pl,pl);
q = arrows(I(pl,pl)-ex,J(pl,pl)-ey,2*ex,2*ey,'Cartesian',[0, 0, 0, 0],'linewidth',1.3); axis square;

subplot(1,2,2)
pcolor(nmag); shading interp; axis square; colorbar
%% Reconstruct psi from BQ_closure
clc;
i = 94; j = 100;

% The values at the chosen points
qxx = Qxx(i,j); qxy = Qxy(i,j)+1e-15;
n1  = nxc(i,j); n2  = nyc(i,j); 
OP  = lam(i,j); NP  = sqrt(n1.^2+n2.^2);
arr = [OP NP]

if (qxx > 1)
    flag= 1
    qxx = 0.95*qxx;
end

% Define the function
fun = @(x) BQfunc(x,qxx,qxy,n1,n2);

% Solve for BQ-parameters
options = optimoptions('fsolve','Display','final-detailed');
vals = fsolve(fun,[2 1 0.1 0.1],options);

% Reconstructed distribtuion function 
nt = 1024; t = linspace(0,2*pi,nt);
psi = reconstBQ(t,vals);
figure(2)
polarplot(t,psi/max(psi),'linewidth',2,'color',[1 1 1]*0.4); hold on

% Setting properties for the polar axes
ax = gca;
set(ax, 'fontsize', 30, 'color', 'w');
set(ax, 'rTick', [0.3 0.7 1]);
set(ax, 'rTickLabel', {'', '', ''})
set(ax, 'ThetaTick', [0, pi/2, pi, 3*pi/2]*180/pi);
set(ax, 'ThetaTickLabel', {'$0$', '$\frac{\pi}{2}$', '$\pi$', '$\frac{3\pi}{2}$'}, ...
    'TickLabelInterpreter','latex','color','k');
ax.ThetaColor = 'k'; ax.RColor = 'k';

% Setting background color to black
ax.Color = 'white';
ax.GridColor = 'k';
set(ax, 'LineWidth', 1.5,'GridAlpha', 0.5);
set(gcf,'color','w'); set(gca,'color','none')
%% All functions
function [nx,ny,lam] = scalOP(Q11,Q12,Q22)
global N
[N,M] = size(Q11);
lam = zeros(N,M); nx = lam; ny = lam;

%direc = zeros(N^2); c = 1;
for i = 1:N
    for j = 1:M
        Q = [Q11(i,j) Q12(i,j);Q12(i,j) Q22(i,j)];
        %Q = Q-trace(Q)*eye(2)/2;
        [v,d] = eig(Q);
        lam(i,j) = max(max(d));
        
        ang= atan(v(2,2)/v(2,1)); %lam(i,j) = ang;
        
        nx(i,j) = cos(ang);
        ny(i,j) = sin(ang);   
    end
end
end

function [ax,ay] = pol2carvec(at,ar,theta)
    ax = ar.*cos(theta) - at.*sin(theta);
    ay = ar.*sin(theta) + at.*cos(theta);
end

function [Qxx,Qxy,Qyy] = pol2cartens(Qtt,Qtr,Qrr,theta)
    [Nr,Nt] = size(Qtt);
    Qxx = zeros(Nr,Nt); Qxy = Qxx*0; Qyy = Qxx*0;
    for k = 1:Nt
        R = [cos(theta(k)) sin(theta(k));-sin(theta(k)) cos(theta(k))];
        for j = 1:Nr
            Q = [Qrr(j,k) Qtr(j,k);Qtr(j,k) Qtt(j,k)];
            Q = R'*Q*R;
            Qxx(j,k) = Q(1,1); Qxy(j,k) = Q(1,2); Qyy(j,k) = Q(2,2);
        end
    end
end

function uxy = scatinterp(Xdisc,Ydisc,udisc,X,Y)
    Su = scatteredInterpolant(Xdisc(:), Ydisc(:), udisc(:));
    uxy = Su(X, Y); 
end

function [] = beautify(L,var,cmap,str)
    if (isnan(var) < 1)
    hc = colorbar;
    set(hc,'fontsize',12,'TickLabelInterpreter','latex')
    xhc=get(hc,'Position');
    xhc(3)=xhc(3)*0.6; xhc(1) = xhc(1)+0.028; % half the size
    set(hc,'Position',xhc)
    clim([min(min(var-1e-5)) max(max(var+1e-5))]); 
    end

    xlim([-L/2 L/2]);ylim([-L/2 L/2])
    xticks(linspace(-floor(L/2),floor(L/2),5)); yticks(linspace(-floor(L/2),floor(L/2),5))
    ax = gca;
    ax.YRuler.MinorTick = 'on';     ax.XRuler.MinorTick = 'on';
    set(gca,'fontsize',13,'TickLabelInterpreter','latex','layer','top'); 
    set(gca,'LineWidth',0.8,'TickLength',[0.012 0.012]);
    title(str, 'interpreter', 'latex');
    colormap(ax,cmap)

    xlabel('$x$','interpreter','latex'); ylabel('$y$','interpreter','latex')

end