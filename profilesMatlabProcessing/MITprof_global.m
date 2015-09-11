function []=MITprof_global(varargin);
%object:    take care of path and global variables (mygrid and mitprofenv), 
%           and sends global variables to caller routine workspace
%notes:     - in any call, if this has not yet been done, 
%           this routine also adds MITprof subdirectories 
%           to the matlab path, and it defines mitprofenv.
%           - this routine replaces MITprof_path

%get/define global variables:
gcmfaces_global;

%take care of path:
test0=which('MITprof_load.m');
if isempty(test0);
    test0=which('MITprof_global.m'); ii=strfind(test0,filesep);
    mydir=test0(1:ii(end));
    %
    addpath(fullfile(mydir));
    addpath(fullfile(mydir,'profiles_process_main_v2'));
    addpath(fullfile(mydir,'profiles_IO_v2'));
    addpath(fullfile(mydir,'profiles_IO_external'));
    addpath(fullfile(mydir,'profiles_misc'));
    addpath(fullfile(mydir,'profiles_stats'));
    addpath(fullfile(mydir,'ecco_v4'));
    addpath(fullfile(mydir,'profiles_devel'));
end;

%environment variables:
if ~isfield(myenv,'MITprof_dir');
    test0=which('MITprof_global.m'); ii=strfind(test0,filesep);
    myenv.MITprof_dir=test0(1:ii(end));
    myenv.MITprof_griddir=fullfile(myenv.gcmfaces_dir,'..','GRID',filesep);
    myenv.MITprof_climdir=fullfile(myenv.gcmfaces_dir,'sample_input','OCCAetcONv4GRID',filesep);
end;

%send to workspace:
evalin('caller','global mygrid mitprofenv');

