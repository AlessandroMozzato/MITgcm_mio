% read obcs

cd /scratch/general/am8e13/cs_36km_tutorial/input_obcs/

accuracy = 'real*4';

% Specify the number of grid boxes. Could look it up in the nc file, but
nx = 210; ny = 192; nz = 50;

% Open the nc file.
ncid = netcdf.open( '/scratch/general/am8e13/results36km/grid.nc', 'NOWRITE' );

% Load the required fields.
hfacs = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacS' ), [ 0 0 0 ], [ nx ny+1 nz ] );
hfacw = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'HFacW' ), [ 0 0 0 ], [ nx+1 ny nz ] );
dxV = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'dxV' ), [ 0 0 ], [ nx+1 ny+1 ] );
dyU = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'dyU' ), [ 0 0 ], [ nx+1 ny+1 ] );
drf = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'drF' ), 0, nz );

% Close the nc file.
netcdf.close( ncid );

% Open the nc file.
ncid = netcdf.open( '/scratch/general/am8e13/results_first/state.nc', 'NOWRITE' );

% Load the required fields.
u_first = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'U' ), [ 0 0 0 0 ], [ nx+1 ny nz 1 ] );
v_first = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'V' ), [ 0 0 0 0 ], [ nx ny+1 nz 1 ] );
temp_first = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 0  ], [ 1 ] );

% Close the nc file.
netcdf.close( ncid );

% Open the nc file.
ncid = netcdf.open( '/scratch/general/am8e13/results_newobcs/state.nc', 'NOWRITE' );

% Load the required fields.
u_newobcs = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'U' ), [ 0 0 0 0 ], [ nx+1 ny nz 1 ] );
v_newobcs = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'V' ), [ 0 0 0 0 ], [ nx ny+1 nz 1 ] );
temp_newobcs = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 0  ], [ 1 ] );

% Close the nc file.
netcdf.close( ncid );

% Open the nc file.
ncid = netcdf.open( '/scratch/general/am8e13/results_newspinup/state.nc', 'NOWRITE' );

% Load the required fields.
u_newspinup = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'U' ), [ 0 0 0 0 ], [ nx+1 ny nz 1 ] );
v_newspinup = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'V' ), [ 0 0 0 0 ], [ nx ny+1 nz 1 ] );
temp_newspinup = netcdf.getVar( ncid, netcdf.inqVarID( ncid, 'T' ), [ 0  ], [ 1 ] );

% Close the nc file.
netcdf.close( ncid );


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

ind = 1 ;

mask = repmat(hfacs,[1 1 1 12]);

for pos = ['N','E','W']
    for var = ['v','u']
        file_name = strcat('OB',num2str(pos),num2str(var),'_arctic_210x192.bin');
        file_name_ave = strcat('OB',num2str(pos),num2str(var),'_arctic_210x192.bin_climyaverage');
        fprintf('now reading %s \n',file_name)
        fid = fopen( file_name, 'r', 'b' );                                                                                                     
        data = fread( fid, accuracy ); 
        fclose(fid);
        if length(data)==1344000
            n = 210 ;
        elseif length(data)==1228800
            n = 192 ;
        else
            fprintf('dimension of file incorrect')
        end
        datares = reshape(data,n,50,128);
        dataav = zeros(n,50,12) ;
        s.(names{ind}) = datares(:,:,1:12) ;
        
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
        
        file_name = strcat('OB',num2str(pos),num2str(var),'_arctic_210x192.bin');
        file_name_ave = strcat('OB',num2str(pos),num2str(var),'_arctic_210x192.bin_climyaverage');
        fprintf('now reading %s \n',file_name)
        fid = fopen( file_name, 'r', 'b' );                                                                                                     
        data = fread( fid, accuracy ); 
        fclose(fid);
        if length(data)==1344000
            n = 210 ;
        elseif length(data)==1228800
            n = 192 ;
        else
            fprintf('dimension of file incorrect')
        end
        datares = reshape(data,n,50,128);
        dataav = zeros(n,50,12) ;
        s.(names{ind}) = datares(:,:,1:12) ;
        
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
        
        corr_wv = 0.012647 ;
        corr_wu = -0.01091 ; 
        corr_ev = -0.000463 ; 
        corr_eu = -0.000463 ; 
        corr_nv = -0.0001;        
        corr_nu = -0.0016335; 
        err = 0.01 ;
        
        %data(abs(data)< err) = data(abs(data)< err) + corr;
        
        s.(avenames{ind}) = data;
        
        data = data1;
        
        if pos == 'N' && var == 'v'
            while (sumflux < 0.01)
                data(abs(data)< err) = data(abs(data)< err) + corr_nv ;
                for i = 1:12
                    s.Wv_flux(i) = mean(mean(s.Wv(:,:,i).*squeeze(dydz_v(1,1:ny,:)))) ;
                end
                sum(s.Wv_flux_ave) ;
            end
                
        elseif pos == 'N' && var == 'u' 
            data(abs(data)< err) = data(abs(data)< err) + corr_nu;
        elseif pos == 'W'&& var == 'v' 
            data(abs(data)< err) = data(abs(data)< err) + corr_wv;            
        elseif pos == 'W'&& var == 'u' 
            data(abs(data)< err) = data(abs(data)< err) + corr_wu;
        elseif pos == 'E' && var == 'v'
            data(abs(data)< err) = data(abs(data)< err) + corr_ev;            
        elseif pos == 'E' && var == 'u'
            data(abs(data)< err) = data(abs(data)< err) + corr_eu;
        else
            fprintf('error \n')
        end
        
        s.(corrnames{ind}) = data;

        ind = ind + 1 ; 
    
%         datares = reshape(data,n*50*12,1);
%         file_name_complete = strcat(file_name,'_newobcs2') ;
%         [fid] = fopen( file_name_complete, 'w', 'b' );
%         fwrite(fid,datares,accuracy);
%         fclose(fid);
        
    end
end


for i = 1:12
    s.Wv_flux(i) = mean(mean(s.Wv(:,:,i).*squeeze(dydz_v(1,1:ny,:)))) ;
    s.Wu_flux(i) = mean(mean(s.Wu(:,:,i).*squeeze(dydz_u(1,1:ny,:)))) ;
    s.Ev_flux(i) = mean(mean(s.Ev(:,:,i).*squeeze(dydz_v(210,1:ny,:)))) ;
    s.Eu_flux(i) = mean(mean(s.Eu(:,:,i).*squeeze(dydz_u(211,1:ny,:)))) ;
    s.Nv_flux(i) = mean(mean(s.Nv(:,:,i).*squeeze(dxdz_v(1:nx,192,:)))) ;
    s.Nu_flux(i) = mean(mean(s.Nu(:,:,i).*squeeze(dxdz_u(1:nx,192,:)))) ;
    
    s.Wv_flux_ave(i) = mean(mean(s.Wv_ave(:,:,i).*squeeze(dydz_v(1,1:ny,:)))) ;
    s.Wu_flux_ave(i) = mean(mean(s.Wu_ave(:,:,i).*squeeze(dydz_u(1,1:ny,:)))) ;
    s.Ev_flux_ave(i) = mean(mean(s.Ev_ave(:,:,i).*squeeze(dydz_v(210,1:ny,:)))) ;
    s.Eu_flux_ave(i) = mean(mean(s.Eu_ave(:,:,i).*squeeze(dydz_u(211,1:ny,:)))) ;
    s.Nv_flux_ave(i) = mean(mean(s.Nv_ave(:,:,i).*squeeze(dxdz_v(1:nx,192,:)))) ;
    s.Nu_flux_ave(i) = mean(mean(s.Nu_ave(:,:,i).*squeeze(dxdz_u(1:nx,192,:)))) ;
    
    s.Wv_flux_ave_corr(i) = mean(mean(s.Wv_ave_corr(:,:,i).*squeeze(dydz_v(1,1:ny,:)))) ;
    s.Wu_flux_ave_corr(i) = mean(mean(s.Wu_ave_corr(:,:,i).*squeeze(dydz_u(1,1:ny,:)))) ;
    s.Ev_flux_ave_corr(i) = mean(mean(s.Ev_ave_corr(:,:,i).*squeeze(dydz_v(210,1:ny,:)))) ;
    s.Eu_flux_ave_corr(i) = mean(mean(s.Eu_ave_corr(:,:,i).*squeeze(dydz_u(211,1:ny,:)))) ;
    s.Nv_flux_ave_corr(i) = mean(mean(s.Nv_ave_corr(:,:,i).*squeeze(dxdz_v(1:nx,192,:)))) ;
    s.Nu_flux_ave_corr(i) = mean(mean(s.Nu_ave_corr(:,:,i).*squeeze(dxdz_u(1:nx,192,:)))) ;
      
%     s.Wv_flux_obcs(i) = mean(mean(squeeze(v_newobcs(1,:,:,i)).*squeeze(dydz_v(1,:,:)))) ;
%     s.Wu_flux_obcs(i) = mean(mean(squeeze(u_newobcs(1,:,:,i)).*squeeze(dydz_u(1,:,:)))) ;
%     s.Ev_flux_obcs(i) = mean(mean(squeeze(v_newobcs(210,:,:,i)).*squeeze(dydz_v(210,:,:)))) ;
%     s.Eu_flux_obcs(i) = mean(mean(squeeze(u_newobcs(211,:,:,i)).*squeeze(dydz_u(211,:,:)))) ;
%     s.Nv_flux_obcs(i) = mean(mean(squeeze(v_newobcs(:,193,:,i)).*squeeze(dxdz_v(:,193,:)))) ;
%     s.Nu_flux_obcs(i) = mean(mean(squeeze(u_newobcs(:,192,:,i)).*squeeze(dxdz_u(:,192,:)))) ;
%     
%     s.Wv_flux_spinup(i) = mean(mean(squeeze(v_newspinup(1,:,:,i)).*squeeze(dydz_v(1,:,:)))) ;
%     s.Wu_flux_spinup(i) = mean(mean(squeeze(u_newspinup(1,:,:,i)).*squeeze(dydz_u(1,:,:)))) ;
%     s.Ev_flux_spinup(i) = mean(mean(squeeze(v_newspinup(210,:,:,i)).*squeeze(dydz_v(210,:,:)))) ;
%     s.Eu_flux_spinup(i) = mean(mean(squeeze(u_newspinup(211,:,:,i)).*squeeze(dydz_u(211,:,:)))) ;
%     s.Nv_flux_spinup(i) = mean(mean(squeeze(v_newspinup(:,193,:,i)).*squeeze(dxdz_v(:,193,:)))) ;
%     s.Nu_flux_spinup(i) = mean(mean(squeeze(u_newspinup(:,192,:,i)).*squeeze(dxdz_u(:,192,:)))) ;
%      
%     s.Wv_flux_first(i) = mean(mean(squeeze(v_first(1,:,:,i)).*squeeze(dydz_v(1,:,:)))) ;
%     s.Wu_flux_first(i) = mean(mean(squeeze(u_first(1,:,:,i)).*squeeze(dydz_u(1,:,:)))) ;
%     s.Ev_flux_first(i) = mean(mean(squeeze(v_first(210,:,:,i)).*squeeze(dydz_v(210,:,:)))) ;
%     s.Eu_flux_first(i) = mean(mean(squeeze(u_first(211,:,:,i)).*squeeze(dydz_u(211,:,:)))) ;
%     s.Nv_flux_first(i) = mean(mean(squeeze(v_first(:,193,:,i)).*squeeze(dxdz_v(:,193,:)))) ;
%     s.Nu_flux_first(i) = mean(mean(squeeze(u_first(:,192,:,i)).*squeeze(dxdz_u(:,192,:)))) ;
end

%area = squeeze(dydz(1,:,:)) ;
% 
% subplot(3,2,1)
% plot(temp_newobcs, s.Wu_flux_obcs,'r')
% hold on
% plot(temp_newspinup, s.Wu_flux_spinup,'g')
% plot(temp_first, s.Wu_flux_first,'b')
% 
% subplot(3,2,2)
% plot(temp_newobcs, s.Wv_flux_obcs,'r')
% hold on
% plot(temp_newspinup, s.Wv_flux_spinup,'g')
% plot(temp_first, s.Wv_flux_first,'b')
% 
% subplot(3,2,3)
% plot(temp_newobcs, s.Eu_flux_obcs,'r')
% hold on
% plot(temp_newspinup, s.Eu_flux_spinup,'g')
% plot(temp_first, s.Eu_flux_first,'b')
% 
% subplot(3,2,4)
% plot(temp_newobcs, s.Ev_flux_obcs,'r')
% hold on
% plot(temp_newspinup, s.Ev_flux_spinup,'g')
% plot(temp_first, s.Ev_flux_first,'b')
% 
% subplot(3,2,5)
% plot(temp_newobcs, s.Nu_flux_obcs,'r')
% hold on
% plot(temp_newspinup, s.Nu_flux_spinup,'g')
% plot(temp_first, s.Nu_flux_first,'b')
% 
% subplot(3,2,6)
% plot(temp_newobcs, s.Nv_flux_obcs,'r')
% hold on
% plot(temp_newspinup, s.Nv_flux_spinup,'g')
% plot(temp_first, s.Nv_flux_first,'b')


% plot(s.Ev_flux,'r')
% hold on
% plot(s.Eu_flux,'r')
% plot(s.Ev_flux_ave,'b')
% plot(s.Eu_flux_ave,'b')
% 
% plot(s.Nv_flux,'m')
% plot(s.Nu_flux,'m')
% plot(s.Nv_flux_ave,'g')
% plot(s.Nu_flux_ave,'g')
% 
% sum(s.Wv_flux) 
% sum(s.Wu_flux) 
% sum(s.Wv_flux_ave) 
% sum(s.Wu_flux_ave) 
% sum(s.Nv_flux) 
% sum(s.Nu_flux) 
% sum(s.Nv_flux_ave) 
% sum(s.Nu_flux_ave) 
% sum(s.Ev_flux) 
% sum(s.Eu_flux) 
% sum(s.Ev_flux_ave) 
% sum(s.Eu_flux_ave) 

subplot(3,2,1)
plot(s.Wu_flux(1:12),'r')
hold on
plot(s.Wu_flux_ave,'g')
plot(s.Wu_flux_ave_corr,'b')

subplot(3,2,2)
plot(s.Wv_flux(1:12),'r')
hold on
plot(s.Wv_flux_ave,'g')
plot(s.Wv_flux_ave_corr,'b')

subplot(3,2,3)
plot(s.Eu_flux(1:12),'r')
hold on
plot(s.Eu_flux_ave,'g')
plot(s.Eu_flux_ave_corr,'b')

subplot(3,2,4)
plot(s.Ev_flux(1:12),'r')
hold on
plot(s.Ev_flux_ave,'g')
plot(s.Ev_flux_ave_corr,'b')

subplot(3,2,5)
plot(s.Nu_flux(1:12),'r')
hold on
plot(s.Nu_flux_ave,'g')
plot(s.Nu_flux_ave_corr,'b')

subplot(3,2,6)
plot(s.Nv_flux(1:12),'r')
hold on
plot(s.Nv_flux_ave,'g')
plot(s.Nv_flux_ave_corr,'b')

%unaveragedsum = sum(s.Wv_flux) + sum(s.Nu_flux) + sum(s.Wu_flux) +sum(s.Nv_flux) + sum(s.Ev_flux)  + sum(s.Eu_flux)
%averagedsum = sum(s.Wv_flux_ave)  + sum(s.Nu_flux_ave) + sum(s.Wu_flux_ave) + sum(s.Nv_flux_ave) + sum(s.Ev_flux_ave)  + sum(s.Eu_flux_ave)
%fluxfirst = sum(s.Wv_flux_first) + sum(s.Nu_flux_first) + sum(s.Wu_flux_first) +sum(s.Nv_flux_first) + sum(s.Ev_flux_first)  + sum(s.Eu_flux_first)
%fluxspiup =  sum(s.Wv_flux_spinup) + sum(s.Nu_flux_spinup) + sum(s.Wu_flux_spinup) +sum(s.Nv_flux_spinup) + sum(s.Ev_flux_spinup)  + sum(s.Eu_flux_spinup)
%fluxobcs = sum(s.Wv_flux_obcs) + sum(s.Nu_flux_obcs) + sum(s.Wu_flux_obcs) +sum(s.Nv_flux_obcs) + sum(s.Ev_flux_obcs)  + sum(s.Eu_flux_obcs)


fprintf('Wv_flux_ave = %d, Corrected value = %d \n',sum(s.Wv_flux_ave),sum(s.Wv_flux_ave_corr))
fprintf('Wu_flux_ave = %d, Corrected value = %d \n',sum(s.Wu_flux_ave),sum(s.Wu_flux_ave_corr))
fprintf('Ev_flux_ave = %d, Corrected value = %d \n',sum(s.Ev_flux_ave),sum(s.Ev_flux_ave_corr))
fprintf('Eu_flux_ave = %d, Corrected value = %d \n',sum(s.Eu_flux_ave),sum(s.Eu_flux_ave_corr))
fprintf('Nv_flux_ave = %d, Corrected value = %d \n',sum(s.Nv_flux_ave),sum(s.Nv_flux_ave_corr))
fprintf('Nu_flux_ave = %d, Corrected value = %d \n',sum(s.Nu_flux_ave),sum(s.Nu_flux_ave_corr))

cd ~/MITgcm_mio/