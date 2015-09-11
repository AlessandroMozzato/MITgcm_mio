function []=MITprof_create(fileOut,nProf,prof_depth,varargin)
%function: 	MITprof_create
%object:	create a file in the "MIT format". Low-level function.
%author:	Gael Forget (gforget@mit.edu)
%date:		june 21th, 2006
%
%usage:	   [MITprof]=MITprof_create(fileOut,nProf,prof_depth);
%               create an empty MITprof netcdf file 
%               vertical depth levels are set according to prof_depth
%               create empty variables for all usual T/S fields
%
%          [MITprof]=MITprof_create(fileOut,nProf,prof_depth,list_vars);
%               same but specifying the list of variables in list_vars cell
%               array (e.g. list_vars={'prof_T','prof_Tweight'}).
%
%inputs:	fileOut		data file name
%           nProf		number of profiles
%           prof_depth 	vector of depth levels
%           list_vars	variable list (optional)
%


% check that file exists and add prefix and suffix if necessary
[pathstr, name, ext] = fileparts(fileOut);
if isempty(pathstr) | strcmp(pathstr,'.'), pathstr=pwd; end
if isempty(ext) | ~strcmp(ext,'.nc'), ext='.nc'; end
fileOut=[pathstr '/' name ext];

%define netcdf dimensions :
nLev=length(prof_depth);
prof_depth=reshape(prof_depth,length(prof_depth),1);
iPROF=nProf; iDEPTH=nLev;
lTXT=30; fillval=double(-9999);

%=============list of variables that will actually be in the file==============%
list_vars={'prof_T','prof_Tweight','prof_Testim','prof_Terr','prof_Tflag',...
    'prof_S','prof_Sweight','prof_Sestim','prof_Serr','prof_Sflag','prof_D','prof_Destim'};
if nargin>3; list_vars=varargin{1}; end

list_vars_plus=[{'prof_depth','prof_descr','prof_date','prof_YYYYMMDD','prof_HHMMSS',...
    'prof_lon','prof_lat','prof_basin','prof_point','prof_flag'}...
    list_vars];

% eliminate doublons
[list,m]=unique(list_vars_plus);
list_vars_plus=list_vars_plus(sort(m));

%==========masters table of variables, units, names and dimensions=============%

mt_v={'prof_depth'}; mt_u={'me'}; mt_n={'depth'}; mt_d={'iDEPTH'};
%mt_v=[mt_v '']; mt_u=[mt_u ' ']; mt_n=[mt_n '']; mt_d=[mt_d ''];
mt_v=[mt_v 'prof_date']; mt_u=[mt_u ' ']; mt_n=[mt_n 'Julian day since Jan-1-0000']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_YYYYMMDD']; mt_u=[mt_u ' ']; mt_n=[mt_n 'year (4 digits), month (2 digits), day (2 digits)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_HHMMSS']; mt_u=[mt_u ' ']; mt_n=[mt_n 'hour (2 digits), minute (2 digits), second (2 digits)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_lon']; mt_u=[mt_u ' ']; mt_n=[mt_n 'Longitude (degree East)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_lat']; mt_u=[mt_u ' ']; mt_n=[mt_n 'Latitude (degree North)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_basin']; mt_u=[mt_u ' ']; mt_n=[mt_n 'ocean basin index (ecco 4g)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_point']; mt_u=[mt_u ' ']; mt_n=[mt_n 'grid point index (ecco 4g)']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_flag']; mt_u=[mt_u ' ']; mt_n=[mt_n 'flag = i > 0 for suspicious profile ']; mt_d=[mt_d 'iPROF'];
%
mt_v=[mt_v 'prof_T']; mt_u=[mt_u 'degree C']; mt_n=[mt_n 'potential temperature']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Tweight']; mt_u=[mt_u '(degree C)^-2']; mt_n=[mt_n 'pot. temp. least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Testim']; mt_u=[mt_u 'degree C']; mt_n=[mt_n 'pot. temp. estimate (e.g. from atlas)']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Terr']; mt_u=[mt_u 'degree C']; mt_n=[mt_n 'pot. temp. instrumental error']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Tflag']; mt_u=[mt_u ' ']; mt_n=[mt_n 'flag = i > 0 means test i rejected data.']; mt_d=[mt_d 'iPROF,iDEPTH'];
%
mt_v=[mt_v 'prof_S']; mt_u=[mt_u 'psu']; mt_n=[mt_n 'salinity']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Sweight']; mt_u=[mt_u '(psu)^-2']; mt_n=[mt_n 'salinity least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Sestim']; mt_u=[mt_u 'psu']; mt_n=[mt_n 'salinity estimate (e.g. from atlas)']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Serr']; mt_u=[mt_u 'psu']; mt_n=[mt_n 'salinity instrumental error']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Sflag']; mt_u=[mt_u ' ']; mt_n=[mt_n 'flag = i > 0 means test i rejected data.']; mt_d=[mt_d 'iPROF,iDEPTH'];
%
mt_v=[mt_v 'prof_U']; mt_u=[mt_u 'm/s']; mt_n=[mt_n 'eastward velocity comp.']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Uweight']; mt_u=[mt_u '(m/s)^-2']; mt_n=[mt_n 'east. v. least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_V']; mt_u=[mt_u 'm/s']; mt_n=[mt_n 'northward velocity comp.']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Vweight']; mt_u=[mt_u '(m/s)^-2']; mt_n=[mt_n 'north. v. least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_ptr']; mt_u=[mt_u 'X']; mt_n=[mt_n 'passive tracer']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_ptrweight']; mt_u=[mt_u '(X)^-2']; mt_n=[mt_n 'pass. tracer least-square weight']; mt_d=[mt_d 'iPROF,iDEPTH'];
%
mt_v=[mt_v 'prof_D']; mt_u=[mt_u 'me']; mt_n=[mt_n 'variable depth']; mt_d=[mt_d 'iPROF,iDEPTH'];
mt_v=[mt_v 'prof_Destim']; mt_u=[mt_u 'me']; mt_n=[mt_n 'variable depth estimate (e.g. from atlas)']; mt_d=[mt_d 'iPROF,iDEPTH'];
%
mt_v=[mt_v 'prof_bp']; mt_u=[mt_u 'cm']; mt_n=[mt_n 'bottom pressure']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_bpweight']; mt_u=[mt_u '(cm)^-2']; mt_n=[mt_n 'bot. pres. least-square weight']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_ssh']; mt_u=[mt_u 'cm']; mt_n=[mt_n 'sea surface height']; mt_d=[mt_d 'iPROF'];
mt_v=[mt_v 'prof_sshweight']; mt_u=[mt_u '(cm)^-2']; mt_n=[mt_n 'ssh least-square weight']; mt_d=[mt_d 'iPROF'];

%=============================create the file=================================%

% write the netcdf structure
ncid=nccreate(fileOut,'clobber');

aa=sprintf(['Format: MITprof netcdf. This file was created using \n' ...
    'the matlab toolbox which can be obtained (see README) from \n'...
    'http://mitgcm.org/viewvc/MITgcm/MITgcm_contrib/gael/profilesMatlabProcessing/']);
ncputAtt(ncid,'','description',aa);
ncputAtt(ncid,'','date',date);

ncdefDim(ncid,'iPROF',iPROF);
ncdefDim(ncid,'iDEPTH',iDEPTH);
ncdefDim(ncid,'lTXT',lTXT);

for ii=1:length(list_vars_plus);
    jj=find(strcmp(mt_v,list_vars_plus{ii}));
    if ~isempty(jj);
        if strcmp(mt_d{jj},'iPROF,iDEPTH');
            ncdefVar(ncid,mt_v{jj},'double',{'iDEPTH','iPROF'});%note the direction flip
        else;
            ncdefVar(ncid,mt_v{jj},'double',{mt_d{jj}});
        end;
        ncputAtt(ncid,mt_v{jj},'long_name',mt_n{jj});
        ncputAtt(ncid,mt_v{jj},'units',mt_u{jj});
        ncputAtt(ncid,mt_v{jj},'missing_value',fillval);
        ncputAtt(ncid,mt_v{jj},'_FillValue',fillval);
    else;
        if strcmp(list_vars_plus{ii},'prof_descr')
            ncdefVar(ncid,'prof_descr','char',{'lTXT','iPROF'});
            ncputAtt(ncid,'prof_descr','long_name','profile description');
        else
            warning([list_vars_plus{ii} ' not included -- it is not a MITprof variable']);
        end
    end;
end;

ncclose(ncid);

%=============================set prof_depth=================================%

ncid=ncopen(fileOut,'write');
ncputvar(ncid,'prof_depth',prof_depth);
ncclose(ncid);


