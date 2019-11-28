
% Connexion to V-REP
vrep=remApi('remoteApi'); % using the prototype file (remoteApiProto.m)
vrep.simxFinish(-1); % just in case, close all opened connections
clientID=vrep.simxStart('127.0.0.1',19999,true,true,5000,5);
test = 0;
if (clientID>-1)
    disp('Matlab and V-Rep connected')
    vrep.simxAddStatusbarMessage(clientID,'Matlab successfully connected!',vrep.simx_opmode_oneshot);

    
    % Before closing the connection to V-REP, make sure that the last command sent out had time to arrive. You can guarantee this with (for example):
    vrep.simxGetPingTime(clientID);


% Demonstration of the mechanisms to grab images from file (may also be
% adjusted to grab images from camera, but requires additional files).
% The architecture fetches one of several images from a file and
% performs a color extraction on it (for a subregion of the image,
% integrated over the vertical axis). The color extraction result is then
% used as input for a set of fields.

%#ok<*UNRCH>
    %USE_CAMERA = false; % choose whether actual camera should be used

    %% setting up the simulator

    % shared parameters
    fieldSize = 50;
    sigma_exc = 5;
    sigma_inh = 12.5;

    % create simulator object
    sim = Simulator();

    % add elements
%     if USE_CAMERA
%       %sim.addElement(CameraGrabber('grabber', 0, [240, 320]));
%     else
%       %          ImageLoader(label, filePath, fileNames, imageSize, currentSelection)  
%       %sim.addElement(ImageLoader('grabber', '', ...
%        % {'sceneSnapshot1.png', 'sceneSnapshot2.png', 'sceneSnapshot3.png'}, [240, 320], 1));
         sim.addElement(ImageLoader('grabber', '', ...
         {'im.jpg'}, [240, 320], 1));
%     end
    sim.addElement(ColorExtraction('ce', [1, 320], [1, 240], [3, fieldSize], ...
      [0, 1/6, 1; 1/6, 1/2, 2; 1/2, 5/6, 3; 5/6, inf, 1], 0.4, 0.4), 'grabber', 'image');

    sim.addElement(ScaleInput('ce scaled', [3, fieldSize], 0.1), 'ce', 'output');
    sim.addElement(NeuralField('field u', [3, fieldSize], 20, -5, 4), 'ce scaled', 'output');
    sim.addElement(MexicanHatKernel1D('u -> u', [3, fieldSize], sigma_exc, 0, sigma_inh, 0, false), ...
      'field u', 'output', 'field u');


    %% setting up the GUI
    gui = StandardGUI(sim, [50, 50, 750, 700], 0.05, [0.0, 0.0, 2/3, 1], [7, 1], 0.05, ...
      [2/3, 0, 1/3, 1], [15, 1]);

    % add visualizations
    gui.addVisualization(RGBImage('grabber', 'image', {'XTick', [], 'YTick', []}, {}), [1, 1], [3, 1]);
    gui.addVisualization(SlicePlot('ce', 'output', [1, 2, 3], 'horizontal', 1, 'horizontal', ...
      {'YLim', [0, 50], 'XLim', [1, fieldSize], 'Box', 'on'}, {{'r-'}, {'g-'}, {'b-'}}, ...
      'color extraction', 'horizontal image position', 'number of pixels'), [4, 1], [2, 1]);
    gui.addVisualization(SlicePlot({'field u', 'field u'}, {'activation', 'output'}, ...
      {[1, 2, 3], [1, 2, 3]}, {'horizontal', 'horizontal'}, [1, 10], 'horizontal', ...
      {'YLim', [-10, 10], 'XLim', [1, fieldSize], 'Box', 'on'}, ...
      {{'r-'}, {'g-'}, {'b-'}, {'--' 'Color', [0.5, 0, 0]}, ...
      {'--', 'Color', [0, 0.5, 0]}, {'--', 'Color', [0, 0, 0.5]} }, ...
      'neural field', 'horizontal image position', 'activation'), ...
      [6, 1], [2, 1]);

    % add controls
%    if ~USE_CAMERA
      gui.addControl(ParameterDropdownSelector('image', 'grabber', 'currentSelection', [1, 2, 3], ...
        {'scene 1', 'scene 2', 'scene 3'}, 1, 'image source'), [1, 1]);
 %   end
    gui.addControl(ParameterSlider('c_stim', 'ce scaled', 'amplitude', [0, 1], '%0.1f', 1, ...
      'strengh of input to field u'), [3, 1]);
    gui.addControl(ParameterSlider('h_u', 'field u', 'h', [-10, 0], '%0.1f', 1, ...
      'resting level of field u'), [4, 1]);
    gui.addControl(ParameterSlider('c_exc', 'u -> u', 'amplitudeExc', [0, 20], '%0.1f', 1, ...
      'strength of lateral excitation in field u'), [5, 1]);
    gui.addControl(ParameterSlider('c_inh', 'u -> u', 'amplitudeInh', [0, 20], '%0.1f', 1, ...
      'strength of lateral inhibition in field u'), [6, 1]);

    % add buttons
    gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [10, 1]);
    gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [11, 1]);
    gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [12, 1]);
    gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, false, 'save parameter settings'), [13, 1]);
    gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [14, 1]);
    gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [15, 1]);


    
    %% Loop to step the simulator and update the gui
    
    
    % Grab the vision_sensor handle from Vrep
    [err,camhandle]=vrep.simxGetObjectHandle(clientID,'Vision_sensor',vrep.simx_opmode_oneshot_wait);

    % run the simulator in the GUI
    sim.init();
    gui.init();
    
    while ~gui.quitSimulation
        [res,objs]=vrep.simxGetObjects(clientID,vrep.sim_handle_all,vrep.simx_opmode_oneshot_wait);
        if (res==vrep.simx_error_noerror)
        
            % Stream the video from Vrep to Matlab, the frame is saved on the img Matlab
            [errorCode,resolution,img]=vrep.simxGetVisionSensorImage2(clientID,camhandle,0,vrep.simx_opmode_oneshot_wait);
            
            % for debbug purpose
            %imshow(img)
            
            % Save the img into a file called 'im.jpg' into the root folder of the project
            imwrite(img,'im.jpg');
         	[test, ob1, ob2, ob3] = vrep.simxCallScriptFunction(clientID, 'base',vrep.sim_scripttype_childscript, 'allumer', [],[],'',[],vrep.simx_opmode_oneshot);
            
            if test == 1
                sim.setElementParameters('ce scaled', 'amplitude', 10);
            end 
                
            % update the gui (Note: The class ImageLoader have been modified in the step() function, by adding: init(obj) )
            gui.step();

        else
            fprintf('Remote API function call returned with error code: %d\n',res);
        end
    end
    
    %gui.run(inf, true, true);
  
    vrep.simxFinish(-1); % just in case, close all opened connections
else
    disp('Failed connecting to remote API server');        
end

vrep.delete(); % call the destructor!
    
disp('Program ended');
