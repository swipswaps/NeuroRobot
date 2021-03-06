
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%  NeuroRobot Toolbox by Backyard Brains  %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% https://github.com/BackyardBrains/NeuroRobot  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% Settings
rak_only = 1;
camera_present = 1;
use_webcam = 0;
hd_camera = 1;
use_cnn = 0; % requires gpu
use_rcnn = 0;
grey_background = 1;
vocal = 0; % custom sound output
brain_gen = 0; % algorithmic brain build
pulse_period = 0.1; % in seconds
audio_test = 1;


%% Advanced settings
save_data_and_commands = 1;
save_brain_jpg = 0; % main only
use_profile = 0;
bg_brain = 1;
draw_synapse_strengths = 1;
draw_neuron_numbers = 1;
manual_controls = 0;
save_for_ai = 0;
bluetooth_present = 0;
script_names = {'Fixed Action Pattern 1', 'Fixed Action Pattern 2', 'Fixed Action Pattern 3', ...
    'Fixed Action Pattern 4', 'Fixed Action Pattern 5', 'Fixed Action Pattern 6', ...
    'Fixed Action Pattern 7', 'Fixed Action Pattern 8', 'Fixed Action Pattern 9'};


%% Local configuration
startup_fig_pos = get(0, 'screensize') + [0 40 0 -63];
fig_pos = get(0, 'screensize') + [0 40 0 -63];

% startup_fig_pos = [1 41 1920 1017]; % Change this if your screen size is different 
% fig_pos = [1 41 1920 1017]; % Change this if your screen size is different

% startup_fig_pos = [1956 3 1854 1043];
% fig_pos = [1956 3 1854 1043];

% bfsize = round(startup_fig_pos(3) / 107);
bfsize = 16; % You may want to change this to 14 if your screen is small
computer_name = 'n/a';
% bluetooth_name = 'RNBT-0C56'; % Change this to match your bluetooth name


%% Prepare 1
ext_cam_id = 0;
ext_cam_nsteps = 100; % check this
nsteps_per_loop = 100;
brain_facts = 0;
max_w = 100;
large_brain = 1;
ltp_recency_th_in_sec = 2000; % must be >= pulse_period
permanent_memory_th = 24;
if grey_background
    fig_bg_col = [0.94 0.94 0.94];
    this_workspace_fig = 'workspace2.jpg';
else
    fig_bg_col = [1 1 1];
    this_workspace_fig = 'workspace.jpg';
end
im3 = flipud(255 - ((255 - imread('workspace2.jpg'))));
adjust2 = 0.29;
if exist('runtime_pulse', 'var')
    delete(runtime_pulse)
end

%% MUSIC MONKEY %%%%%%
% if hd_camera
    audx = 626;
% else
%     audx = 500;
% end
temp436 = zeros(audx, nsteps_per_loop);
temp332 = zeros(3, nsteps_per_loop);
monkey_base = 0;
monkey_flag = 0;
monkey_done = 0;
monkey_superflag = 0;
clear monkey_shake

%% MC KITTEN %%%%%
kitten_flag = 0;
kitten_counter = 0;
vocal_buffer = 0;
vocal_durations = [];


%% Clear
if exist('voluntary_restart', 'var') && ~voluntary_restart && ~rak_only
    delete(imaqfind)
    delete(timerfind)
    brain_view_tiled = 0;
end
clear step_timer
clear life_timer
disp('---------')
if camera_present && ~use_webcam && ~rak_only
    HebiCam.loadLibs();
end
if ~exist('voluntary_restart', 'var')
    brain_view_tiled = 0;
end
spinled = 1;
vis_prefs = [];
neuron_scripts = [];
neuron_tones = 0;


%% Prepare 2
base_weight = max_w;
gui_font_name = 'Comic Book';
gui_font_weight = 'normal';
load gong.mat
gong = y;
ms_per_step = round(pulse_period * 1000);
ltp_recency_th_in_steps = round(ltp_recency_th_in_sec / ms_per_step);
speaker_selected = 0;
if ~exist('voluntary_restart', 'var')
    voluntary_restart = 0;
end
this_exercise = '';


%% Prepare 3
im = flipud(255 - ((255 - imread(this_workspace_fig))));
im2 = flipud(255 - ((255 - imread(this_workspace_fig))));
contact_xys = [-1.2, 2.05; 1.2, 2.1; -2.08, -0.38; 2.14, -0.38; ...
    -0.05, 2.45; -1.9, 1.45; -1.9, 0.95; -1.9, -1.78; ...
    -1.9, -2.28; 1.92, 1.49; 1.92, 0.95; 1.92, -1.82; 1.92, -2.29];
ncontacts = size(contact_xys, 1);
dist_pref_names = {'Short', 'Medium', 'Long'};
n_dist_prefs = size(dist_pref_names, 2);
% load('brain_im_xy.txt', '-ascii')
load('brain_im_xy')
this_audio = [];

audio_out_names = [];
audio_out_durations = [];
if vocal
    available_sounds = dir('./Sounds/*.mp3');
    n_out_sounds = size(available_sounds, 1);
    for nsound = 1:n_out_sounds
        audio_out_names{nsound} = available_sounds(nsound).name(1:end-4);
        [audio_y,audio_fs] = audioread(horzcat('./Sounds/', available_sounds(nsound).name));
        audio_out_durations = [audio_out_durations length(audio_y)/audio_fs];
    end
end

vis_pref_names = {'red', 'off-center red', 'green', 'off-center green', 'blue', 'off-center blue'};
if use_cnn
    load object_strs
    load object_ns
    vis_pref_names = [vis_pref_names, object_strs];
    score = zeros(1, 1000);
elseif use_rcnn
    vis_pref_names = [vis_pref_names, 'neurorobots', 'off-center neurorobots', 'close-up neurorobots'];
end
n_vis_prefs = size(vis_pref_names, 2);
sens_thresholds = [10 10 10 10 10 10 10 10 10 10 10 10 10 10 10];
encoding_pattern = ones(size(sens_thresholds));
if ~exist('restarting', 'var')
    restarting = 0;
end
if ~exist('restarts', 'var')
    restarts = 0;
end
fx = (0:1000-1)*8;

pulse_led_flag_1 = 0;
pulse_led_flag_2 = 0;
pulse_led_flag_3 = 0;

script_running = 0;
script_step_count = 0;

for nscript = 1:size(script_names, 2)
    script_strs(nscript).name = script_names{nscript};
end

efferent_copy = 0;
r_torque = 0;
l_torque = 0;


%% Prepare figure
fig_startup = figure(1);
clf
set(fig_startup, 'NumberTitle', 'off', 'Name', 'Neurorobot Startup')
set(fig_startup, 'menubar', 'none', 'toolbar', 'none')
set(fig_startup, 'position', startup_fig_pos, 'color', fig_bg_col) 

% Title
text_title = uicontrol('Style', 'text', 'String', 'Neurorobot Startup', 'units', 'normalized', 'position', [0.05 0.9 0.9 0.05], ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 10, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

% Select brain
text_load = uicontrol('Style', 'text', 'String', 'Select brain', 'units', 'normalized', 'position', [0.05 0.79 0.35 0.05], ...
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 8, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
clear brain_string
brain_string{1} = '-- Create new brain --';
brain_directory = './Brains/*.mat';
available_brains = dir(brain_directory);
nbrains = size(available_brains, 1);
for nbrain = 1:nbrains
    brain_string{nbrain + 1} = available_brains(nbrain).name(1:end-4);
end
popup_select_brain = uicontrol('Style', 'popup', 'String', brain_string, 'callback', 'update_brain_name_edit', 'units', 'normalized', ...
    'position', [0.05 0.7 0.35 0.1], 'fontsize', bfsize + 8, 'fontweight', gui_font_weight, 'FontName', gui_font_name);
if ~restarting
    brain_name = '';
end
brain_text_name = uicontrol('Style', 'text', 'String', 'Brain:', 'units', 'normalized', 'position', [0.05 0.68 0.35 0.05], ....
    'backgroundcolor', fig_bg_col, 'fontsize', bfsize + 8, 'horizontalalignment', 'left', 'fontweight', gui_font_weight, 'FontName', gui_font_name);
brain_edit_name = uicontrol('Style', 'edit', 'String', brain_name, 'units', 'normalized', 'position', [0.05 0.63 0.35 0.06], 'fontsize', bfsize + 10, ....
    'FontName', gui_font_name, 'fontweight', gui_font_weight);

% Camera button
dis_cam_button = 0;
if ~use_webcam && exist('rak_cam', 'var') && (isa(rak_cam, 'NeuroRobot_matlab')) && rak_cam.isRunning()
    this_col = [0.6 0.95 0.6];
    dis_cam_button = 1;
elseif ~use_webcam && exist('rak_cam', 'var') && (isa(rak_cam, 'NeuroRobot_matlab')) && ~rak_cam.isRunning() 
    this_col = [1 0.5 0.5];
else
    this_col = [0.8 0.8 0.8];
end
button_camera = uicontrol('Style', 'pushbutton', 'String', 'Connect', 'units', 'normalized', 'position', [0.075 0.39 0.25 0.07]);
set(button_camera, 'Callback', 'camera_button_callback', 'FontSize', bfsize + 7, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, 'BackgroundColor', this_col)
if ~camera_present
    set(button_camera, 'BackgroundColor', [0.8 0.8 0.8], 'enable', 'off')
% elseif ~dis_cam_button
%     set(button_camera, 'BackgroundColor', [0.6 0.95 0.6], 'enable', 'off')
end

% Bluetooth button
distance_read = 0;
if ~rak_only
    if exist('bluetooth_modem', 'var')
        while bluetooth_modem.BytesAvailable
            distance_read = fgetl(bluetooth_modem);
        end
        distance_read = str2double(distance_read);    
    end
    if exist('bluetooth_modem', 'var') && ~isnan(distance_read)
        this_col = [0.6 0.95 0.6];
    elseif exist('bluetooth_modem', 'var') && isnan(distance_read)
        this_col = [1 0.5 0.5];
    else
        this_col = [0.8 0.8 0.8];
    end
    button_bluetooth = uicontrol('Style', 'pushbutton', 'String', 'Bluetooth', 'units', 'normalized', 'position', [0.075 0.3 0.25 0.07]);
    set(button_bluetooth, 'Callback', 'bluetooth_modem = connect_bluetooth(bluetooth_name, button_bluetooth, text_title, text_load, popup_select_brain, brain_edit_name, button_camera, button_startup_complete, camera_present, bluetooth_present); ', 'FontSize', bfsize + 7, 'FontName', gui_font_name, ...
        'FontWeight', gui_font_weight, 'BackgroundColor', this_col)
    if ~bluetooth_present
        set(button_bluetooth, 'BackgroundColor', [0.8 0.8 0.8], 'enable', 'off')
    end
else
    button_bluetooth = uicontrol('Style', 'pushbutton', 'String', 'Bluetooth', 'units', 'normalized', 'position', [0.075 0.3 0.25 0.07]);
    set(button_bluetooth, 'Callback', 'bluetooth_modem = connect_bluetooth(bluetooth_name, button_bluetooth, text_title, text_load, popup_select_brain, brain_edit_name, button_camera, button_startup_complete, camera_present, bluetooth_present); ', 'FontSize', bfsize + 7, 'FontName', gui_font_name, ...
        'FontWeight', gui_font_weight, 'BackgroundColor', [0.8 0.8 0.8])
    set(button_bluetooth, 'enable', 'off')
end

% Start button
button_startup_complete = uicontrol('Style', 'pushbutton', 'String', 'Start', 'units', 'normalized', 'position', [0.075 0.21 0.25 0.07]);
set(button_startup_complete, 'Callback', 'startup_complete', 'FontSize', bfsize + 10, 'FontName', gui_font_name, 'FontWeight', gui_font_weight, ...
    'BackgroundColor', [0.8 0.8 0.8])

% Brain display
brain_ax = axes('position', [0.475 0.16 0.45 0.69]);
image('CData',im2,'XData',[-3 3],'YData',[-3 3])
set(brain_ax, 'xtick', [], 'ytick', [], 'xcolor', fig_bg_col, 'ycolor', fig_bg_col)
axis([-3 3 -3 3])
hold on
box off
ext_ax = brain_ax;



% Brain info
info_bar = uicontrol('Style', 'text', 'String', [], 'units', 'normalized', 'position', [0.05 0.04 0.45 0.04], ...
    'FontName', gui_font_name, 'backgroundcolor', fig_bg_col, 'fontsize', bfsize, 'horizontalalignment', 'center', 'fontweight', gui_font_weight);

% New restart code
if exist('brain_name.mat', 'file')
    disp('Restarting...')
    load('brain_name')
	delete brain_name.mat
    for nbrain = 1:nbrains
        if strcmp(brain_name, available_brains(nbrain).name(1:end-4))
            nbrains = size(available_brains, 1);
            popup_select_brain.Value = nbrain + 1;
        end
    end    
    brain_edit_name.String = brain_name;      
    try
%         rak_cam = connect_rak(button_camera, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, brain_edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only);
        [rak_cam, rak_cam_h, rak_cam_w] = connect_rak(button_camera, use_webcam, text_title, text_load, button_bluetooth, popup_select_brain, brain_edit_name, button_startup_complete, camera_present, bluetooth_present, rak_only, hd_camera);
        start(rak_pulse)
        disp('RAK reconnected')
        startup_complete
    catch
        if bluetooth_present
            set(button_bluetooth, 'enable', 'on')
        end
        set(popup_select_brain, 'visible', 'on')
        set(brain_edit_name, 'enable', 'on')
        if camera_present
            set(button_camera, 'enable', 'on')
        end
        set(button_startup_complete, 'enable', 'on')
        button_camera.BackgroundColor = [1 0.5 0.5];
        disp('Unable to reconnect to RAK')
    end    
end


% Manual restart code
if exist('restarting', 'var') && restarting
    for nbrain = 1:nbrains
        if strcmp(brain_name, available_brains(nbrain).name(1:end-4))
            nbrains = size(available_brains, 1);
            popup_select_brain.Value = nbrain + 1;
        end
    end    
    brain_edit_name.String = brain_name;
    restarting = 0;
    voluntary_restart = 0;
    startup_complete
end
    


%% Get DLLs
if ispc && ~isfile('avcodec-58.dll')
    
    disp('DLLs not found in main directory')
    
    try
        dll_dir = NeuroRobotToolbox.getInstallationLocation('boost-and-ffmpeg-libraries');
        dll_dir(end-3:end) = [];
        
        this_file = horzcat(dll_dir, '\avcodec-58.dll');
        movefile(this_file, '.\', 'f')

        this_file = horzcat(dll_dir, '\avdevice-58.dll');
        movefile(this_file, '.\', 'f')

        this_file = horzcat(dll_dir, '\avfilter-7.dll');
        movefile(this_file, '.\', 'f')
        
        this_file = horzcat(dll_dir, '\avformat-58.dll');
        movefile(this_file, '.\', 'f')
        
        this_file = horzcat(dll_dir, '\avutil-56.dll');
        movefile(this_file, '.\', 'f')
        
        this_file = horzcat(dll_dir, '\swresample-3.dll');
        movefile(this_file, '.\', 'f')
        
        this_file = horzcat(dll_dir, '\swscale-5.dll');
        movefile(this_file, '.\', 'f')        
        
        this_file = horzcat(dll_dir, '\NeuroRobot_MatlabBridge.mexw64');
        movefile(this_file, '.\', 'f')
        
        disp('DLLs moved in from additional software location')
        
    catch
        
        disp('Unable to find or move DLLs')
        disp('WiFi communication with RAK will not work')
        
    end        
        
end

