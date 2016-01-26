% This script is meant to read nc files from nemo runs and produce bin
% files readable by ipython

% Read orca 1/12 files
file = '/scratch/general/am8e13/NEMO_data/ORCA0083-N01_1983to1992y10T.nc' ;

%Read files
nav_lon = ncread(file,'nav_lon');
nav_lat = ncread(file,'nav_lat');
temp = ncread(file,'votemper');
salt = ncread(file,'vosaline');
ice = ncread(file,'soicecov');
depth = ncread(file,'deptht');
mask = ncread('/scratch/general/am8e13/NEMO_data/mask83.nc','tmask');

ice_18 = ncread('/scratch/general/am8e13/results18km_newspinup/spinup18km.nc','ice');

% Write files
% writebin('/scratch/general/am8e13/NEMO_data/NEMO83_lon',nav_lon)
% writebin('/scratch/general/am8e13/NEMO_data/NEMO83_lat',nav_lat)
% writebin('/scratch/general/am8e13/NEMO_data/NEMO83_temp',temp)
% writebin('/scratch/general/am8e13/NEMO_data/NEMO83_salt',salt)
% writebin('/scratch/general/am8e13/NEMO_data/NEMO83_depth',depth) 
% writebin('/scratch/general/am8e13/NEMO_data/NEMO83_mask',mask) 
% writebin('/scratch/general/am8e13/NEMO_data/NEMO83_ice',ice) 

% Read orca 1/4 files
%file = '/scratch/general/am8e13/NEMO_data/ORCA025-N102_1979to2001y01T.nc' ;

% Read files
% nav_lon = ncread(file,'nav_lon');
% nav_lat = ncread(file,'nav_lat');
% temp = ncread(file,'votemper');
% salt = ncread(file,'vosaline');
% ice = ncread(file,'soicecov');
% depth = ncread(file,'deptht');
% mask = ncread('/scratch/general/am8e13/NEMO_data/mask25.nc','tmask');

% Write files
% writebin('/scratch/general/am8e13/NEMO_data/NEMO25_lon',nav_lon)
% writebin('/scratch/general/am8e13/NEMO_data/NEMO25_lat',nav_lat)
% writebin('/scratch/general/am8e13/NEMO_data/NEMO25_temp',temp)
% writebin('/scratch/general/am8e13/NEMO_data/NEMO25_salt',salt)
% writebin('/scratch/general/am8e13/NEMO_data/NEMO25_depth',depth) 
% writebin('/scratch/general/am8e13/NEMO_data/NEMO25_mask',mask) 
% writebin('/scratch/general/am8e13/NEMO_data/NEMO25_ice',ice) 
