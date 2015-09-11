function [MITprofCur]=profiles_prep_locate(MITprofCur);
%[MITprofCur]=profiles_prep_locate(MITprofCur);
%	locate MITprofCur profiles on ecco-4g grid, and get month index
%   to do so, set the variables prof_point, prof_basin, ii, jj and imonth
%       of MITprofCur
%
%  global variables mytri and MYBASININDEX must be set in gcmfaces

global  mytri MYBASININDEX

MITprofCur.prof_point=gcmfaces_bindata(MITprofCur.prof_lon,MITprofCur.prof_lat);
MITprofCur.prof_basin=MYBASININDEX(MITprofCur.prof_point);
[MITprofCur.ii,MITprofCur.jj]=gcmfaces_bindata(MITprofCur.prof_lon,MITprofCur.prof_lat);
MITprofCur.imonth=floor(MITprofCur.prof_YYYYMMDD/1e2)-1e2*floor(MITprofCur.prof_YYYYMMDD/1e4);

