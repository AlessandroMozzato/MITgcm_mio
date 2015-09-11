% PLOT_STREAMFUNCTION Plot streamfunction.
% PLOT_STREAMFUNCTION draws a contour plot of the streamfunction with
% contour labels and a colorbar.

%--------------------------------------------------------------------------
% Set directory and filename
%--------------------------------------------------------------------------

% % Build full input file name
% experimentName      = 'equatorial_circulation/run1/output_0001';
% experimentPath      = '../../MITgcm_exp/';
% experimentDirectory = fullfile(experimentPath, experimentName);
% 
% % Set constants
% rSphere  = 6370.0E03;
% deg2dist = pi/180.0*rSphere;

%--------------------------------------------------------------------------
% Read grids
%--------------------------------------------------------------------------

% Read grids from MNC/netcdf files
% (note that fields read with "rdmnc(fullfile(bdir, 'grid.*'))" aquire
% different names and dimensions as compared to fields read with
% "g=mit_loadgrid(bdir);")
grids = rdmnc(fullfile(experimentDirectory, 'grid.*'));
xC = grids.XC;
yC = grids.YC;
xG = grids.XG;
yG = grids.YG;
depth = 100.0; % mean depth/m disregarding any topography

% Set the array sizes
Nx = size(grids.XC, 1);
Ny = size(grids.XC, 2);

%--------------------------------------------------------------------------
% Read field
%--------------------------------------------------------------------------

% Read vector of iterations and find last time slice
a  = rdmnc(fullfile(experimentDirectory, 'state.*'), 'iter');
it = a.iter(end);

% Read data structure from file
inputField = rdmnc(fullfile(experimentDirectory, 'state.*'), it);

% Extract field with all singleton dimensions removed
v  = sq(inputField.V(:, :, :));

%--------------------------------------------------------------------------
% Read field
%--------------------------------------------------------------------------

% Calculate horizontal streamfunction by integrating from east to west
psi = zeros(Nx, Ny);
for j=1:Ny
    for i=Nx-1:-1:1
        if isnan(v(i, j))
            psi(i,j) = psi(i+1, j);
        else
            psi(i,j) = psi(i+1, j) ... 
                     - v(i, j)*(xG(i+1, j) - xG(i, j))* ...
                       deg2dist*cos(yG(i, j)*pi/180.0)*depth*1.0E-6;
        end
    end
end

%--------------------------------------------------------------------------
% Plot field
%--------------------------------------------------------------------------

% Draw filled contour plot of the horizontal streamfunction 'psi'
figure
[C, h] = contourf(xG(1:Nx, 1:Ny), yC, psi);
xlabel('longitude/degW', 'FontSize', 14)
ylabel('latitude/degN', 'FontSize', 14)
title('Streamfunction/Sv of barotropic ocean model (MITgcm)', 'FontSize', 16)

% Label every other contour line by setting the TextStep property to twice 
% the contour interval (i.e., two times the LevelStep property)
set(h,'ShowText','on','TextStep',get(h,'LevelStep')*2)

% Set the contour label text BackgroundColor to a light yellow and the 
% EdgeColor to light gray
text_handle = clabel(C,h);
set(text_handle,'BackgroundColor',[1 1 .6],...
    'Edgecolor',[.7 .7 .7])

% Display horizontal colorbar beneath axes
colorbar('location','southoutside')

% For testing: use M_Map
figure
% Select projection
m_proj('equidistant cylindrical', 'lon', [-75 15], 'lat', [-30 30]);
m_pcolor(xG(1:Nx, 1:Ny), yC, psi);
% m_contourf(xG(1:Nx, 1:Ny), yC, psi);
shading flat;
m_coast('color', [0 .6 0]); % add coast lines and grid
m_grid('xaxis', 'middle');