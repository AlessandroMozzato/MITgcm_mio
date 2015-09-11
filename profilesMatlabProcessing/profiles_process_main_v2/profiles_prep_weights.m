function [MITprofCur]=profiles_prep_weights(dataset,MITprofCur,sigma);
%[MITprofCur]=profiles_prep_weights(dataset,MITprofCur,sigma);
%	Attributes least square weights to MITprofCur
%	based upon dataset specs, instrumental and
%	representation error estimates
%
%by assumption:
%	neither the representation error fields (sigma.T and sigma.S)
%	nor the data is 'land-masked'. And sigma.T/S>0 everywhere.
%
% global variable mygrid must be set.

global mygrid

nk=size(sigma.T,3); kk=ones(1,nk); np=length(MITprofCur.ii); pp=ones(np,1);
ind2prof=sub2ind(size(sigma.T),MITprofCur.ii*kk,MITprofCur.jj*kk,pp*[1:nk]);

%collocate sigma.T to profiles locations:
sig_in=sigma.T(ind2prof);
%interpolate in the vertical:
sig_out=interp1(-mygrid.RC',sig_in',MITprofCur.prof_depth)';
%add instrumental error and compute weight:
sig_instr=MITprofCur.prof_Terr; sig_instr(sig_instr==dataset.fillval)=0;
MITprofCur.prof_Tweight=1./(sig_out.^2+sig_instr.^2);


if dataset.inclS;
    %collocate sigma.S to profiles locations:
    sig_in=sigma.S(ind2prof);
    %interpolate in the vertical:
    sig_out=interp1(-mygrid.RC',sig_in',MITprofCur.prof_depth)';
    %add instrumental error and compute weight:
    sig_instr=MITprofCur.prof_Serr; sig_instr(sig_instr==dataset.fillval)=0;
    MITprofCur.prof_Sweight=1./(sig_out.^2+sig_instr.^2);
end;


