# CoRLEGO
CoRLEGO Project

1. You have to install V-REP and Matlab. 
2. Download Cosivina and open the folder on Matlab
3. Make sure to register COSIVINA path to Matlab by running the 'setpath.m' of the Cosivina folder.
4. Open V-REP and open the CoRLEGO.ttt scene
5. Run the V-REP simulator (before the Matlab script as V-REP is the Server)
6. Now open the file 'launcherImageGrabber.m' with Matlab
7. Run the script 

Note:
The following 3 items on the matlab folder are the V-REP API for Matlab:
remoteApiProto.m
remApi.m
remoteApi.dll

These files are originaly located in V-REP's installation directory, under: programming/remoteApiBindings/matlab.
For windows 10 it is located at: 
C:\Program Files\V-REP3\V-REP_PRO_EDU\programming\remoteApiBindings\matlab\matlab

I just had to Copy and paste these files to the folder of the project.
    
Make sure your Matlab uses the same architecture as the remoteApi library: 32 or 64bit.

If you had to rebuild the remoteApi library, you might have to regenerate the prototype open the file 'remoteApiProto.m' and run it.
