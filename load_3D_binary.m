
%% ------------------------------------------------------------------------
function data = load_3D_binary( file_name, nx, ny, nt, accuracy )

% DRM, 01/09/11.
% Script to load a 3D binary file, with assumed big-endian format. The
% order of the data's dimensionas are re-ordered to MITgcm stand (z,y,x)                                                          
                                                                                                                                  
%% ------------------------------------------------------------------------                                                       
% Open the file.                                                                                                                  
[ fid message ] = fopen( file_name, 'r', 'b' );                                                                                   
                                                                                                                                  
%% ------------------------------------------------------------------------                                                       
                                                                                                                                  
% Read in the data.                                                                                                               
data = fread( fid, accuracy );                                                                                                    
                                                                                                                                  
% Reshape the data from a single column.                                                                                          
data = reshape( data, nx, ny, nt*4 );                                                                                       
                                                                                                                                  
% Permute the data into MITgcm standard dimension order.                                                                          
%data = permute( data, [ 3 2 1 ] );                                                                                                
                                                                                                                                  
%% ------------------------------------------------------------------------                                                       
% Close the file.                                                                                                                 
                                                                                                                                  
fclose( fid );                                                                                                                    
                                                                                                                                  
%% ------------------------------------------------------------------------                                                       

