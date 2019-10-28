
% Connexion to V-REP
vrep=remApi('remoteApi'); % using the prototype file (remoteApiProto.m)
vrep.simxFinish(-1); % just in case, close all opened connections
clientID=vrep.simxStart('127.0.0.1',19999,true,true,5000,5);

if (clientID>-1)
    disp('Matlab and V-Rep connected')
    vrep.simxAddStatusbarMessage(clientID,'Matlab successfully connected!',vrep.simx_opmode_oneshot);
    % Before closing the connection to V-REP, make sure that the last command sent out had time to arrive. You can guarantee this with (for example):
    vrep.simxGetPingTime(clientID);


% Launcher for a simulation of two coupled dynamic nodes. The rates of
% change in dependence of the node activation are plotted, with attractor
% and repellor states marked.
% Hover over sliders and buttons to see a description of their function.


%% setting up the simulator

    historyDuration = 100;
    samplingRange = [-10, 10];
    samplingResolution = 0.05;

    sim = Simulator();

    sim.addElement(BoostStimulus('stimulus s_1', 0));
    sim.addElement(BoostStimulus('stimulus s_2', 0));

    sim.addElement(SingleNodeDynamics('node u_1', 20, -5, 4, 0, 0, samplingRange, samplingResolution), 'stimulus s_1');
    sim.addElement(SingleNodeDynamics('node u_2', 20, -5, 4, 0, 0, samplingRange, samplingResolution), 'stimulus s_2');

    sim.addElement(ScaleInput('c_21', [1, 1]), 'node u_1', 'output', 'node u_2');
    sim.addElement(ScaleInput('c_12', [1, 1]), 'node u_2', 'output', 'node u_1');

    sim.addElement(RunningHistory('history u_1', [1, 1], historyDuration, 1), 'node u_1', 'activation');
    sim.addElement(RunningHistory('history u_2', [1, 1], historyDuration, 1), 'node u_2', 'activation');

    sim.addElement(SumInputs('shifted stimulus s_1', [1, 1]), {'stimulus s_1', 'node u_1'}, {'output', 'h'});
    sim.addElement(SumInputs('shifted stimulus s_2', [1, 1]), {'stimulus s_2', 'node u_2'}, {'output', 'h'});

    sim.addElement(RunningHistory('stimulus history s_1', [1, 1], historyDuration, 1), 'shifted stimulus s_1');
    sim.addElement(RunningHistory('stimulus history s_2', [1, 1], historyDuration, 1), 'shifted stimulus s_2');


    %% setting up the GUI
    elementGroups = {'node u_1', 'node u_2', 'stimulus s_1', 'stimulus s_2'};

    gui = StandardGUI(sim, [50, 50, 1020, 500], 0.01, [0.0, 0.0, 0.75, 1.0], [2, 3], [0.045, 0.08], ...
      [0.75, 0.0, 0.25, 1.0], [20, 1], elementGroups, elementGroups);

    gui.addVisualization(XYPlot({'node u_1', 'history u_1'}, {'activation', 'output'}, ...
      {'node u_2', 'history u_2'}, {'activation', 'output'}, ...
      {'XLim', [-10, 10], 'YLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
      { {'bo', 'MarkerFaceColor', 'b'}, {'b-', 'LineWidth', 2} }, '', 'activation u_1', 'activation u_2'), [1.5, 1]);
    gui.addVisualization(MultiPlot({'node u_1', 'stimulus history s_1', 'history u_1'}, {'activation', 'output', 'output'}, ...
      [1, 1, 1], 'horizontal', ...
      {'XLim', [-historyDuration, 10], 'YLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
      { {'bo', 'XData', 0, 'MarkerFaceColor', 'b'}, {'Color', [0, 0.5, 0], 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1}, ...
      {'b-', 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1} }, ...
      'node u_1', 'relative time', 'activation'), [1, 2]);
    gui.addVisualization(MultiPlot({'node u_2', 'stimulus history s_2', 'history u_2'}, {'activation', 'output', 'output'}, ...
      [1, 1, 1], 'horizontal', ...
      {'XLim', [-historyDuration, 10], 'YLim', [-10, 10], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
      { {'bo', 'XData', 0, 'MarkerFaceColor', 'b'}, {'Color', [0, 0.5, 0], 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1}, ...
      {'b-', 'LineWidth', 2, 'XData', 0:-1:-historyDuration+1} }, ...
      'node u_2', 'relative time', 'activation'), [2, 2]);

    gui.addVisualization(XYPlot({[], 'node u_1', 'node u_1', 'node u_1'}, ...
      {samplingRange(1):samplingResolution:samplingRange(2), 'attractorStates', 'repellorStates', 'activation'}, ...
      {'node u_1', 'node u_1', 'node u_1', 'node u_1'}, ...
      {'sampledRatesOfChange', 'attractorRatesOfChange', 'repellorRatesOfChange' 'rateOfChange'}, ...
      {'XLim', samplingRange, 'YLim', [-1, 1], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
      { {'r', 'LineWidth', 2}, {'ks'}, {'kd'}, {'ro', 'MarkerFaceColor', 'r'} }, ...
      'activation dynamics u_1', 'activation', 'rate of change'), [1, 3]);
    gui.addVisualization(XYPlot({[], 'node u_2', 'node u_2', 'node u_2'}, ...
      {samplingRange(1):samplingResolution:samplingRange(2), 'attractorStates', 'repellorStates', 'activation'}, ...
      {'node u_2', 'node u_2', 'node u_2', 'node u_2'}, ...
      {'sampledRatesOfChange', 'attractorRatesOfChange', 'repellorRatesOfChange' 'rateOfChange'}, ...
      {'XLim', samplingRange, 'YLim', [-1, 1], 'Box', 'on', 'XGrid', 'on', 'YGrid', 'on'}, ...
      { {'r', 'LineWidth', 2}, {'ks'}, {'kd'}, {'ro', 'MarkerFaceColor', 'r'} }, ...
      'activation dynamics u_2', 'activation', 'rate of change'), [2, 3]);


    % add parameter sliders
    gui.addControl(ParameterSlider('h_1', 'node u_1', 'h', [-10, 0], '%0.1f', 1, 'resting level of node u_1'), [1, 1]);
    gui.addControl(ParameterSlider('q_1', 'node u_1', 'noiseLevel', [0, 1], '%0.1f', 1, 'noise level for node u_1'), [2, 1]);
    gui.addControl(ParameterSlider('c_11', 'node u_1', 'selfExcitation', [-10, 10], '%0.1f', 1, ...
      'connection strength from node u_1 to itself'), [3, 1]);
    gui.addControl(ParameterSlider('c_12', 'c_12', 'amplitude', [-10, 10], '%0.1f', 1, ...
      'connection strength from node u_2 to node u_1'), [4, 1]);
    gui.addControl(ParameterSlider('s_1', 'stimulus s_1', 'amplitude', [0, 20], '%0.1f', 1, ...
      'stimulus strength for node u_1'), [5, 1]);

    gui.addControl(ParameterSlider('h_2', 'node u_2', 'h', [-10, 0], '%0.1f', 1, 'resting level of node u'), [8, 1]);
    gui.addControl(ParameterSlider('q_2', 'node u_2', 'noiseLevel', [0, 1], '%0.1f', 1, 'noise level for node u'), [9, 1]);
    gui.addControl(ParameterSlider('c_22', 'node u_2', 'selfExcitation', [-10, 10], '%0.1f', 1, ...
      'connection strength from node u_2 to itself'), [10, 1]);
    gui.addControl(ParameterSlider('c_21', 'c_21', 'amplitude', [-10, 10], '%0.1f', 1, ...
      'connection strength from node u_1 to node u_2'), [11, 1]);
    gui.addControl(ParameterSlider('s_2', 'stimulus s_2', 'amplitude', [0, 20], '%0.1f', 1, ...
      'stimulus strength for node u_2'), [12, 1]);

    % add buttons
    gui.addControl(GlobalControlButton('Pause', gui, 'pauseSimulation', true, false, false, 'pause simulation'), [15, 1]);
    gui.addControl(GlobalControlButton('Reset', gui, 'resetSimulation', true, false, true, 'reset simulation'), [16, 1]);
    gui.addControl(GlobalControlButton('Parameters', gui, 'paramPanelRequest', true, false, false, 'open parameter panel'), [17, 1]);
    gui.addControl(GlobalControlButton('Save', gui, 'saveParameters', true, false, true, 'save parameter settings'), [18, 1]);
    gui.addControl(GlobalControlButton('Load', gui, 'loadParameters', true, false, true, 'load parameter settings'), [19, 1]);
    gui.addControl(GlobalControlButton('Quit', gui, 'quitSimulation', true, false, false, 'quit simulation'), [20, 1]);

    sim.init();
    gui.init();
    while ~gui.quitSimulation && sim.t < 100000
        gui.step();
        if any(sim.getComponent('node u_1', 'activation') > 5)
            vrep.simxCallScriptFunction(clientID, 'Base',vrep.sim_scripttype_childscript, 'upperArmSpeed', [],[],'',[],vrep.simx_opmode_oneshot);
        end
    end
    %gui.run(inf);

    vrep.simxFinish(-1); % just in case, close all opened connections
else
    disp('Failed connecting to remote API server');        
end

vrep.delete(); % call the destructor!
    
disp('Program ended');


