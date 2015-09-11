function []=profiles_prep_mygrid(fileData,dirIn,dirOut,ni,nj);
%[]=profiles_prep_mygrid(fileData,dirIn,dirOut,ni,nj);
%
%object:    add interpolation information for use by MITgcm/pkg/profiles
%
%input:     fileData is the name of the MITprof file to augment
%           dirIn is the corresponding direcroty name
%           dirOut is the directory name for the new (augmented) file
%           ni,nj is the MITgcm tile size
%
%output:    (none -- a file will be created)
%
%example:
% fileData='argo_indian.nc';
% dirIn='processed/';
% dirOut='mygrid/';
% ni=30; nj=30;
% profiles_prep_mygrid(fileData,dirIn,dirOut,ni,nj);

if strcmp(dirIn,dirOut);
    error('dirOut must differ from dirIn (to avoid loosing the original file)');
end;

gcmfaces_global;

if isempty(mygrid);
  fprintf(['it is a pre-requisiste that you load the grid according to e.g. \n' ...
         'grid_load(''./'',5,''compact''); \n']);
  error('missing grid');
end;

dirGrid0=[myenv.gcmfaces_dir '/sample_input/GRIDv4/'];
if strcmp(mygrid.dirGrid,dirGrid0);
    fprintf('\n\n reminder: be sure to specify the grid \n');
    fprintf(' directory of your own MITgcm set-up. \n');
    fprintf(' By default we use ecco_v4 here.\n\n');
end;

%triangulate data and get grid locations:
%----------------------------------------
eval(['ncload ' dirIn fileData ' prof_lon prof_lat;']);
loc_tile=gcmfaces_loc_tile(ni,nj,prof_lon,prof_lat);

%prepare output fields:
%----------------------
list_in={'XC11','YC11','XCNINJ','YCNINJ','iTile','jTile','XC','YC'};
list_out={'XC11','YC11','XCNINJ','YCNINJ','i','j','lon','lat'};
for iF=1:length(list_out);
    eval(['myVec.prof_interp_' list_out{iF} '=loc_tile.' list_in{iF} ';']);
end;
%use 1 as weight since we do nearest neighbor interp
myVec.prof_interp_weights=ones(size(loc_tile.XC)); list_out={list_out{:},'weights'};

%append myVec.* to file:
%-----------------------

test0=dir([dirOut fileData]);
if ~isempty(test0);
    test1=input(['\n\n !! ' dirOut fileData '\n !! already exists. Type 1 to erase it and proceed or 0 to stop.\n\n']);
    if test1;
        system(['rm -f ' dirOut fileData]);
    else;
        return;
    end;
end;

system(['cp -f ' dirIn fileData ' ' dirOut fileData]);

list1d={'prof_interp_XC11','prof_interp_YC11','prof_interp_XCNINJ','prof_interp_YCNINJ'};
list2d={'prof_interp_i','prof_interp_j','prof_interp_lon','prof_interp_lat','prof_interp_weights'};
listAll={list1d{:},list2d{:}};

if (myenv.useNativeMatlabNetcdf);
    nc=netcdf.open([dirOut fileData],'write');
    iPROFid = netcdf.inqDimID(nc,'iPROF');
    netcdf.reDef(nc);
    %add dimension:
    iINTERPid = netcdf.defDim(nc,'iINTERP',1);
    %add variables:
    for ii=1:length(list1d); netcdf.defVar(nc,list1d{ii},'double',iPROFid); end;
    for ii=1:length(list2d); netcdf.defVar(nc,list2d{ii},'double',[iINTERPid iPROFid]); end;
    netcdf.endDef(nc);
    %fill variables:
    for ii=1:length(listAll); ncputvar(nc,listAll{ii},getfield(myVec,listAll{ii})); end;
    netcdf.close(nc);
else;
    nc=netcdf([dirOut fileData],'write');
    %add dimension:
    nc('iINTERP') = 1;
    %add variables:
    for ii=1:length(list1d); nc{list1d{ii}}=ncdouble('iPROF'); end;
    for ii=1:length(list2d); nc{list2d{ii}}=ncdouble('iPROF','iINTERP'); end;
    %fill variables:
    for ii=1:length(listAll); ncputvar(nc,listAll{ii},getfield(myVec,listAll{ii})); end;
    close(nc);
end;

