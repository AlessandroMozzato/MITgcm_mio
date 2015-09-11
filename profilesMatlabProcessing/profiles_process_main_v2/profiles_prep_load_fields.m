function []=profiles_prep_load_fields(varargin);
% []=profiles_prep_load_fields([loadFromMat,saveToMat]);
%   - object : load grid and atlas data to global variables
%   - optional inputs :
%	if loadFromMat=0 (default) then variables are loaded from gcmfaces/sample_input/ files
%	if loadFromMat=1 then variables are loaded from mat files prepared by users
%       if saveToMat=1 then variables are saved to mat files
%   - result consists of global variables :
%       mygrid : structure containing XC, YC, RAC and RC from the ECCOv4 grid
%       mytri : information used for delaunay triangulation
%       MYBASININDEX : basin index
%       atlas : T/S atlas in a structure format
%           atlas.T, atlas.S are monthly mean 3D T/S climatologies (OCCA by default)
%       sigma : T/S observational standard deviation in a structure format
%           sigma.T and sigma.S are 3D fields (updated Forget and Wunsch 2007 by default)
%           by assumption: the uncertainty fields contain non-zero values
%           (which avoid the complication of handling horiz interpolation here)
%           and we do not mask the data (the model will do this, given a mask)
%   - note : gcmfaces toolbox is required
%

% process arguments
loadFromMat=0;
if nargin==1,
    loadFromMat=varargin{1};
end
saveToMat=0;
if nargin==2,
    saveToMat=varargin{1};
end

%set global variables
gcmfaces_global;
global mytri MYBASININDEX atlas sigma;

% set directories:
dirClim=myenv.MITprof_climdir;
dirGrid=myenv.MITprof_griddir;

%%%%%% part 1 : default usage %%%%%%%

file_basin=[dirClim 'basin_masks_eccollc_90x50.bin'];
file_atlasT=[dirClim 'T_OWPv1_M_eccollc_90x50.bin'];
file_atlasS=[dirClim 'S_OWPv1_M_eccollc_90x50.bin'];
file_varT=[dirClim 'sigma_T_mad_feb2013.bin'];
file_varS=[dirClim 'sigma_S_mad_feb2013.bin'];

if loadFromMat==0,
    
    % read grid :
    disp(['load grid from ' myenv.MITprof_griddir]);
    mygrid=[];
    grid_load(dirGrid,5,'compact'); gcmfaces_bindata;
    mygrid=rmfield(mygrid,{'XG','YG','RAC','RAZ','DXC','DYC','DXG','DYG'});
    mygrid=rmfield(mygrid,{'hFacC','hFacW','hFacS','Depth','AngleCS','AngleSN'});
    mygrid=rmfield(mygrid,{'hFacCsurf','mskW','mskS','DRC','DRF','RF'});
    MYBASININDEX=convert2array(read_bin(file_basin,1,0));
    
    % read T/S Atlas
    disp(['load atlas from ' myenv.MITprof_climdir]);
    atlas=[];
    fldT=mygrid.mskC; fldT(:)=0; fldS=fldT;
    for tt=1:12;
        fldT(:,:,:,tt)=read_bin(file_atlasT,tt).*mygrid.mskC;
        fldS(:,:,:,tt)=read_bin(file_atlasS,tt).*mygrid.mskC;
    end;
    atlas.T={convert2array(fldT)};  atlas.S={convert2array(fldS)};
    
    % read T/S variance fields
    disp(['load sigma from ' myenv.MITprof_climdir]);
    sigma.T=convert2array(read_bin(file_varT));
    sigma.S=convert2array(read_bin(file_varS));
    
end

%%%%%% part 2 : custom usage %%%%%%%

mat_grid=[dirGrid 'MITprof_grid.mat'];
mat_clim=[dirClim 'MITprof_clim.mat'];

if loadFromMat == 1

    if exist(mat_clim,'file') & exist(mat_grid,'file'),

        % load grid, atlas and sigma
        load(mat_grid);
        load(mat_clim);
        return

    else
        error('matlab files could not be found. They need to be generated using profiles_prep_load_fields(1)');
    end
end;

if saveToMat==1;
    disp('save fields')
    save(mat_grid,'mygrid','mytri','MYBASININDEX');
    save(mat_clim,'atlas','sigma');
end;

