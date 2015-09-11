% read obcs

cd /scratch/general/am8e13/cs_36km_tutorial/input_obcs/

addpath ~/MITgcm_mio/

accuracy = 'real*8';

% Specify the number of grid boxes. Could look it up in the nc file, but
nx = 210; ny = 192; nz = 50;

% Open the nc file.
ncid = netcdf.open( '/scratch/general/am8e13/results36km/grid.nc', 'NOWRITE' );

% Load the required fields.
hfacs = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacS' ), [ 0 0 0 ], [ nx ny+1 nz ] );
hfacw = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacW' ), [ 0 0 0 ], [ nx+1 ny nz ] );
hfacc = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacC' ), [ 0 0 0 ], [ nx ny nz ] );
dxV = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'dxV' ), [ 0 0 ], [ nx+1 ny+1 ] );
dyU = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'dyU' ), [ 0 0 ], [ nx+1 ny+1 ] );
drf = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'drF' ), 0, nz );

% Calculate the area of the western cell face.
dxdz_u = hfacw .* repmat( dxV(:,1:ny), [ 1 1 nz ] ) .* ...
    permute( repmat( drf, [ 1 ny nx+1 ] ), [ 3 2 1 ] );

dydz_u = hfacw .* repmat( dyU(:,1:ny), [ 1 1 nz ] ) .* ...
    permute( repmat( drf, [ 1 ny nx+1 ] ), [ 3 2 1 ] );

dxdz_v = hfacs .* repmat( dxV(1:nx,:), [ 1 1 nz ] ) .* ...
    permute( repmat( drf, [ 1 ny+1 nx ] ), [ 3 2 1 ] );

dydz_v = hfacs .* repmat( dyU(1:nx,:), [ 1 1 nz ] ) .* ...
    permute( repmat( drf, [ 1 ny+1 nx ] ), [ 3 2 1 ] );

names = {'Nv' 'Nu' 'Ev' 'Eu' 'Wv' 'Wu'};
avenames = {'Nv_ave' 'Nu_ave' 'Ev_ave' 'Eu_ave' 'Wv_ave' 'Wu_ave'};
corrnames = {'Nv_ave_corr' 'Nu_ave_corr' 'Ev_ave_corr' 'Eu_ave_corr' 'Wv_ave_corr' 'Wu_ave_corr'};
fluxnames = {'Nv_flux' 'Nu_flux' 'Ev_flux' 'Eu_flux' 'Wv_flux' 'Wu_flux'};
fluxnames_ave = {'Nv_flux_ave' 'Nu_flux_ave' 'Ev_flux_ave' 'Eu_flux_ave' 'Wv_flux_ave' 'Wu_flux_ave'};
fluxnames_ave_corr = {'Nv_flux_ave_corr' 'Nu_flux_ave_corr' 'Ev_flux_ave_corr' 'Eu_flux_ave_corr' 'Wv_flux_ave_corr' 'Wu_flux_ave_corr'};
fluxnames_ave_sum = {'Nv_flux_ave_sum' 'Nu_flux_ave_sum' 'Ev_flux_ave_sum' 'Eu_flux_ave_sum' 'Wv_flux_ave_sum' 'Wu_flux_ave_sum'};
fluxnames_ave_corr_sum = {'Nv_flux_ave_corr_sum' 'Nu_flux_ave_corr_sum' 'Ev_flux_ave_corr_sum' 'Eu_flux_ave_corr_sum' 'Wv_flux_ave_corr_sum' 'Wu_flux_ave_corr_sum'};

corr_val = {'corr_Nv' 'corr_Nu' 'corr_Ev' 'corr_Eu' 'corr_Wv' 'corr_Wu'} ;

ind = 1 ;
corr_value = 0.000001 ;
mask = repmat(hfacs,[1 1 1 12]);

for pos = ['N','E','W']
    for var = ['v','u']
        file_name = strcat('OB',num2str(pos),num2str(var),'_arctic_210x192.bin');
        file_name_ave = strcat('OB',num2str(pos),num2str(var),'_arctic_210x192.bin_climyaverage');
        fprintf('now reading %s \n',file_name_ave)
        fid = fopen( file_name_ave, 'r', 'b' );                                                                                                     
        data = fread( fid, accuracy ); 
        fclose(fid);
        if length(data)==126000
            n = 210 ;
        elseif length(data)==115200
            n = 192 ;
        end
        data = reshape(data,n,50,12);
        data1 = data ;
        
        [data] = recalc_obcs(data,hfacc,pos,var,nx,ny) ;
        
        [s.(fluxnames_ave_sum{ind}), s.(fluxnames_ave{ind}) ] = flux_calc(data1,pos,var,dxdz_u,dxdz_v,dydz_u,dydz_v,nx,ny) ;
        [s.(fluxnames_ave_corr_sum{ind}), s.(fluxnames_ave_corr{ind}) ] = flux_calc(data1,pos,var,dxdz_u,dxdz_v,dydz_u,dydz_v,nx,ny) ;
        s.(avenames{ind}) = data;
        s.(corrnames{ind}) = data ;
        ind = ind + 1 ; 

    end
end

sumflux = s.Eu_flux_ave_corr_sum + s.Wu_flux_ave_corr_sum + s.Nv_flux_ave_corr_sum ;
corr_value = 0.0000001 ;
while(abs(sumflux) > 10)

        s.Eu_ave_corr(s.Eu_ave ~= 0) = s.Eu_ave(s.Eu_ave ~= 0 ) + (-1)*sign(sumflux)*corr_value/5 ;
        s.Wu_ave_corr(s.Wu_ave ~= 0) = s.Wu_ave(s.Wu_ave ~= 0 ) + (-1)*sign(sumflux)*corr_value*1.5;
        s.Nv_ave_corr(s.Nv_ave ~= 0) = s.Nv_ave(s.Nv_ave ~= 0 ) + (-1)*sign(sumflux)*corr_value*1.5 ;
        [s.Eu_flux_ave_corr_sum,s.Eu_flux_ave_corr] = flux_calc(s.Eu_ave_corr,'E','u',dxdz_u,dxdz_v,dydz_u,dydz_v,nx,ny) ;
        [s.Wu_flux_ave_corr_sum,s.Wu_flux_ave_corr] = flux_calc(s.Wu_ave_corr,'W','u',dxdz_u,dxdz_v,dydz_u,dydz_v,nx,ny) ;
        [s.Nv_flux_ave_corr_sum,s.Nv_flux_ave_corr] = flux_calc(s.Nv_ave_corr,'N','v',dxdz_u,dxdz_v,dydz_u,dydz_v,nx,ny) ;
        sumflux = s.Eu_flux_ave_corr_sum + s.Wu_flux_ave_corr_sum + s.Nv_flux_ave_corr_sum ;
        corr_value = corr_value + 0.0000001 ;
        fprintf('sumflux = %d, corr_value = %d \n', sumflux, corr_value)
        
end

%s.(corr_val{ind}) = corr_value ;

% s.(corrnames{ind}) = data1;
% [s.(fluxnames_ave_corr_sum{ind}), s.(fluxnames_ave_corr{ind}) ] = flux_calc(data1,pos,var,dxdz_u,dxdz_v,dydz_u,dydz_v,nx,ny) ;
ind = 1 ;
for pos = ['N','E','W']
    for var = ['v','u']
        file_name = strcat('OB',num2str(pos),num2str(var),'_arctic_210x192.bin');
         if pos == 'N'
             n = 210 ;
         else 
             n = 192 ;
         end
         data1 = s.(corrnames{ind}) ;
         datares = reshape(data1,n*50*12,1);
         file_name_complete = strcat(file_name,'_zeroed_div') ;
         [fid] = fopen( file_name_complete, 'w', 'b' );
         fwrite(fid,datares,accuracy);
         fclose(fid);         
         ind = ind +1 ;
    end
end
         

subplot(3,2,1)
plot(s.Wu_flux_ave,'g')
hold on
plot(s.Wu_flux_ave_corr,'b')

subplot(3,2,2)
plot(s.Wv_flux_ave,'g')
hold on
plot(s.Wv_flux_ave_corr,'b')

subplot(3,2,3)
plot(s.Eu_flux_ave,'g')
hold on
plot(s.Eu_flux_ave_corr,'b')

subplot(3,2,4)
plot(s.Ev_flux_ave,'g')
hold on
plot(s.Ev_flux_ave_corr,'b')

subplot(3,2,5)
plot(s.Nu_flux_ave,'g')
hold on
plot(s.Nu_flux_ave_corr,'b')

subplot(3,2,6)
plot(s.Nv_flux_ave,'g')
hold on
plot(s.Nv_flux_ave_corr,'b')

fprintf('Wv_flux_ave = %d, Corrected value = %d \n',s.Wv_flux_ave_sum,s.Wv_flux_ave_corr_sum)
fprintf('Wu_flux_ave = %d, Corrected value = %d \n',s.Wu_flux_ave_sum,s.Wu_flux_ave_corr_sum)
fprintf('Ev_flux_ave = %d, Corrected value = %d \n',s.Ev_flux_ave_sum,s.Ev_flux_ave_corr_sum)
fprintf('Eu_flux_ave = %d, Corrected value = %d \n',s.Eu_flux_ave_sum,s.Eu_flux_ave_corr_sum)
fprintf('Nv_flux_ave = %d, Corrected value = %d \n',s.Nv_flux_ave_sum,s.Nv_flux_ave_corr_sum)
fprintf('Nu_flux_ave = %d, Corrected value = %d \n',s.Nu_flux_ave_sum,s.Nu_flux_ave_corr_sum)

cd ~/MITgcm_mio/