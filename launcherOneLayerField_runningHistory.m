
% Connexion to V-REP
vrep=remApi('remoteApi'); % using the prototype file (remoteApiProto.m)
vrep.simxFinish(-1); % just in case, close all opened connections
clientID=vrep.simxStart('127.0.0.1',19999,true,true,5000,5);

if (clientID>-1)
    disp('Matlab and V-Rep connected')
    vrep.simxAddStatusbarMessage(clientID,'Matlab successfully connected!',vrep.simx_opmode_oneshot);
    % Before closing the connection to V-REP, make sure that the last command sent out had time to arrive. You can guarantee this with (for example):
    vrep.simxGetPingTime(clientID);

% Launcher for a one-layer neural field simulator.
% The script sets up an architecture with a single one-dimensional neural
% field, lateral interactions, and three Gaussian inputs to the field. It
% then creates a GUI for this architecture and starts that GUI.
% Hover over sliders and buttons to see a description of their function.


%% setting up the simulator

    % shared parameters
    fieldSize = 50;
    sigma_exc = 5;
    sigma_inh = 12.5;

    % create simulator object
    sim = Simulator();

    % create inputs (and sum for visualization)
    sim.addElement(GaussStimulus1D('stimulus 1', fieldSize, sigma_exc, 0, round(1/4*fieldSize), true, false));
    sim.addElement(GaussStimulus1D('stimulus 2', fieldSize, sigma_exc, 0, round(1/2*fieldSize), true, false));
    sim.addElement(GaussStimulus1D('stimulus 3', fieldSize, sigma_exc, 0, round(3/4*fieldSize), true, false));
    sim.addElement(SumInputs('stimulus sum', fieldSize), {'stimulus 1', 'stimulus 2', 'stimulus 3'});

    % create neural field
    sim.addElement(NeuralField('field u', fieldSize, 20, -5, 4), 'stimulus sum');
    sim.addElement(SumInputs('shifted stimulus sum', fieldSize), {'stimulus sum', 'field u'}, {'output', 'h'}); % for plot

    % create interactions
    sim.addElement(LateralInteractions1D('u -> u', fieldSize, sigma_exc, 0, sigma_inh, 0, 0, true, true), ...
      'field u', 'output', 'field u');

    % create noise stimulus and noise kernel
    sim.addElement(NormalNoise('noise', fieldSize, 1.0));
    sim.addElement(GaussKernel1D('noise kernel', fieldSize, 0, 1.0, true, true), 'noise', 'output', 'field u');

    % store activation history
    sim.addElement(RunningHistory('history', fieldSize, 200, 1), 'field u', 'activation');


    %% setting up the GUI

    elementGroups = {'field u', 'u -> u', 'stimulus 1', 'stimulus 2', 'stimulus 3', 'noise kernel'};
    elementGroupLabels = {'field u', 'kernel u -> u', 'stimulus 1', 'stimulus 2', 'stimulus 3', 'noise kernel'};

    gui = StandardGUI(sim, [50, 50, 1000, 720], 0.01, [0.0, 1/4, 1.0, 3/4], [2, 1], 0.06, [0.0, 0.0, 1.0, 1/4], [6, 4], ...
      elementGroupLabels, elementGroups);

    gui.addVisualization(MultiPlot({'field u', 'field u', 'shifted stimulus sum'}, {'activation', 'output', 'output'}, ...
      [1, 10, 1], 'horizontal', {'YLim', [-15, 15], 'XGrid', 'on', 'YGrid', 'on'}, ...
      {{'b', 'LineWidth', 3}, {'r', 'LineWidth', 2}, {'Color', [0, 0.75, 0], 'LineWidth', 2}}, ...
      'field u (blue - activation, green - external input, red - output)', ...
      'feature space', 'activation / input / output'), [1, 1]);
    gui.addVisualization(ScaledImage('history', 'output', [-10, 10], {}, {}, 'history of field u activation', ...
      'feature space', 'time (back from current step)'), [2, 1]);


    % add sliders
    % resting level and noise
    gui.addControl(ParameterSlider('h', 'field u', 'h', [-10, 0], '%0.1f', 1, 'resting level of field u'), [1, 1]);
    gui.addControl(ParameterSlider('q', 'noise kernel', 'amplitude', [0, 10], '%0.1f', 1, ...
      'noise level for field u'), [1, 3]);
    % lateral interactions
    gui.addControl(ParameterSlider('c_exc', 'u -> u', 'amplitudeExc', [0, 50], '%0.1f', 1, ...
      'strength of lateral excitation'), [2, 1]);
    gui.addControl(ParameterSlider('c_inh', 'u -> u', 'amplitudeInh', [0, 50], '%0.1f', 1, ...
      'strength of lateral inhibition'), [2, 2]);
    gui.addControl(ParameterSlider('c_glob', 'u -> u', 'amplitudeGlobal', [0, 2], '%0.2f', -1, ...
      'strength of global inhibition'), [2, 3]);

    % stimuli
    gui.addControl(ParameterSlider('w_s1', 'stimulus 1', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 1'), [4, 1]);
    gui.addControl(ParameterSlider('p_s1', 'stimulus 1', 'position', [0, fieldSize], '%0.1f', 1, ...
      'position of stimulus 1'), [4, 2]);
    gui.addControl(ParameterSlider('a_s1', 'stimulus 1', 'amplitude', [0, 20], '%0.1f', 1, ...
      'amplitude of stimulus 1'), [4, 3]);
    gui.addControl(ParameterSlider('w_s2', 'stimulus 2', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 2'), [5, 1]);
    gui.addControl(ParameterSlider('p_s2', 'stimulus 2', 'position', [0, fieldSize], '%0.1f', 1, ...
      'position of stimulus 2'), [5, 2]);
    gui.addControl(ParameterSlider('a_s2', 'stimulus 2', 'amplitude', [0, 20], '%0.1f', 1, ...
      'amplitude of stimulus 2'), [5, 3]);
    gui.addControl(ParameterSlider('w_s3', 'stimulus 3', 'sigma', [0, 20], '%0.1f', 1, 'width of stimulus 3'), [6, 1]);
    gui.addControl(ParameterSlider('p_s3', 'stimulus 3', 'position', [0, fieldSize], '%0.1f', 1, ...
      'position of stimulus 3'), [6, 2]);
    gui.addControl(ParameterSlider('a_s3', 'stimulus 3', 'amplitude', [0, 20], '%0.1f', 1, ...
      'amplitude of stimulus 3'), [6, 3]);

    % add buttons
    gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [1, 4]);
    gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [2, 4]);
    gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [3, 4]);
    gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [4, 4]);
    gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [5, 4]);
    gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [6, 4]);


    %% run the simulator in the GUI
    s1 = sim.getElement('stimulus 1');
    s3 = sim.getElement('stimulus 3');
    sim.init();
    gui.init();
    %while ~gui.quitSimulation && sim.t < 100000
    while ~gui.quitSimulation
        gui.step();
        %if any(sim.getComponent('field u', 'activation') > 10)

        if any( s3.amplitude > 10)     
            sim.setElementParameters('stimulus 1', 'amplitude', 10);
            if (s1.amplitude > 5 )
                vrep.simxCallScriptFunction(clientID, 'base',vrep.sim_scripttype_childscript, 'handleIk', [],[],'',[],vrep.simx_opmode_oneshot);
            end
        end
    end
    
    %gui.run(inf);
    
    vrep.simxFinish(-1); % just in case, close all opened connections
else
    disp('Failed connecting to remote API server');        
end

vrep.delete(); % call the destructor!
    
disp('Program ended');

    
