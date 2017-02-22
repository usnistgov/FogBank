% NIST-developed software is provided by NIST as a public service. You may use, copy and distribute copies of the software in any medium, provided that you keep intact this entire notice. You may improve, modify and create derivative works of the software or any portion of the software, and you may copy and distribute such modifications or works. Modified works should carry a notice stating that you changed the software and should note the date and nature of any such change. Please explicitly acknowledge the National Institute of Standards and Technology as the source of the software.

% NIST-developed software is expressly provided "AS IS." NIST MAKES NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, NON-INFRINGEMENT AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR WARRANTS THAT THE OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE, OR THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT WARRANT OR MAKE ANY REPRESENTATIONS REGARDING THE USE OF THE SOFTWARE OR THE RESULTS THEREOF, INCLUDING BUT NOT LIMITED TO THE CORRECTNESS, ACCURACY, RELIABILITY, OR USEFULNESS OF THE SOFTWARE.

% You are solely responsible for determining the appropriateness of using and distributing the software and you assume all risks associated with its use, including but not limited to the risks and costs of program errors, compliance with applicable laws, damage to or loss of data, programs or equipment, and the unavailability or interruption of operation. This software is not intended to be used in any situation where a failure could cause risk of injury or damage to property. The software developed by NIST employees is not subject to copyright protection within the United States.



function FogBank_GUI()

if ~isdeployed
  addpath([pwd filesep 'src']);
  addpath([pwd filesep 'src/gui_functions']);
  addpath([pwd filesep 'imgs']);
  addpath([pwd filesep 'doc']);
end

% Global Params
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
warning('off','MATLAB:hg:uicontrol:ParameterValuesMustBeValid'); % suppress warnings if the sliders min and max values are both 1
raw_images_path = [pwd filesep 'test' filesep];
raw_images_common_name = '';
raw_image_files = [];
nb_frames = 0;
current_frame_nb = 1;
pre_image_loading = true;

load_seed_mask_path = raw_images_path;
load_seed_mask_common_name = raw_images_common_name;
use_load_seed_mask = false;
seed_img_files = [];

% used in foreground mask and object separation panels
min_object_size = 1000;

img = [];
foreground_mask = [];

colormap_options = {'gray','jet','hsv','hot','cool'};
contour_color_options = {'Red', 'Green', 'Blue', 'Black', 'White'};

threshold_operator_modifiers = {'>','<','>=','<='};
seed_threshold_operator_modifiers = {'<','<='};
threshold_modifiers = {'Pixel','Percentile'};
grayscale_modifiers = {'Intensity','Gradient','Std','Entropy'};
fg_adjust_contrast_display_raw_image = false;
os_adjust_contrast_display_raw_image = false;




% Figure setup
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
GUI_Name = 'FogBank';

% if the GUI is already open, don't open another copy, bring the current copy to the front
open_fig_handle = findobj('type','figure','name',GUI_Name);
if ~isempty(open_fig_handle)
  figure(open_fig_handle);
  return;
  %     close(open_fig_handle);
end

% Define General colors
lt_gray = [0.86,0.86,0.86];
dark_gray = [0.7,0.7,0.7];
green_blue = [0.0,0.3,0.4];
% purple_color = [0.6,0.6,0.9];

%   Get user screen size
SC = get(0, 'ScreenSize');
MaxMonitorX = SC(3);
MaxMonitorY = SC(4);

%   Set the figure window size values
main_tabFigScale = 0.5;          % Change this value to adjust the figure size
gui_ratio = 0.6;
gui_width = round(MaxMonitorX*main_tabFigScale);
gui_height = gui_width*gui_ratio;
% MaxWindowY = round(MaxMonitorY*main_tabFigScale);
% if MaxWindowX <= MaxWindowY, MaxWindowX = round(1.6*MaxWindowY); end
offset = 0;
if (SC(2) ~= 1)
  offset = abs(SC(2));
end
XPos = (MaxMonitorX-gui_width)/2 - offset;
YPos = (MaxMonitorY-gui_height)/2 + offset;


hctfig = figure(...
  'units', 'pixels',...
  'Position',[ XPos, YPos, gui_width, gui_height ],...
  'Name',GUI_Name,...
  'Toolbar','figure',...
  'NumberTitle','off');


% Tab Setup
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
TabLabels = {'Main'; 'Foreground Mask'; 'Object Separation'};

%-----------------------------------------------------------------------------------------
% Option Tabs
%-----------------------------------------------------------------------------------------
tab_label_text_size = 0.5;

% Create main menu tab, 'Main'
h_tabpanel(1) = uipanel('Units', 'normalized', 'Parent', hctfig, 'Visible', 'on', 'Backgroundcolor', lt_gray,'BorderWidth',0, 'Position', [0,0,1,1] );
% Create main menu tab, 'Foreground Segmentation'
h_tabpanel(2) = uipanel('Units', 'normalized', 'Parent', hctfig,'Visible', 'off', 'Backgroundcolor', lt_gray,'BorderWidth',0,'Position', [0,0,1,1]);
% Create main menu tab, 'Object Seperation'
h_tabpanel(3) = uipanel('Units', 'normalized','Parent', hctfig, 'Visible', 'off', 'Backgroundcolor', lt_gray, 'BorderWidth',0, 'Position', [0,0,1,1]);

h_tabpb(1) = push_button(hctfig, [0 0.95 .307 0.05], TabLabels(1), 'center', 'k', dark_gray, tab_label_text_size, 'serif', 'bold', 'on', {@first_tab_callback} );
h_tabpb(2) = push_button(hctfig, [.307 0.95 .307 0.05], TabLabels(2), 'center', 'k', dark_gray, tab_label_text_size, 'serif', 'bold', 'off', {@second_tab_callback} );
h_tabpb(3) = push_button(hctfig, [.614 0.95 .307 0.05], TabLabels(3), 'center', 'k', dark_gray, tab_label_text_size, 'serif', 'bold', 'off', {@third_tab_callback} );

% Create main menu tab, 'Help'
push_button(hctfig, [0.92 0.95 0.08 0.05], 'Help', 'center', 'k', dark_gray, tab_label_text_size, 'serif', 'bold', 'on', {@Open_Help_callback} );

  function first_tab_callback(varargin)
    set(h_tabpb(1), 'Backgroundcolor', lt_gray);
    set(h_tabpanel(1), 'Visible', 'on');
    
    set(h_tabpb(2), 'Backgroundcolor', dark_gray);
    set(h_tabpanel(2), 'Visible', 'off');
    
    set(h_tabpb(3), 'Backgroundcolor', dark_gray);
    set(h_tabpanel(3), 'Visible', 'off');
    
    initMainImagePanel();
  end

  function second_tab_callback(varargin)
    set(h_tabpb(1), 'Backgroundcolor', dark_gray);
    set(h_tabpanel(1), 'Visible', 'off');
    
    set(h_tabpb(2), 'Backgroundcolor', lt_gray);
    set(h_tabpanel(2), 'Visible', 'on');
    
    set(h_tabpb(3), 'Backgroundcolor', dark_gray);
    set(h_tabpanel(3), 'Visible', 'off');
    
    initFgImagePanel();
    set(h_tabpb(3), 'enable', 'on');
  end

  function third_tab_callback(varargin)
    set(h_tabpb(1), 'Backgroundcolor', dark_gray);
    set(h_tabpanel(1), 'Visible', 'off');
    
    set(h_tabpb(2), 'Backgroundcolor', dark_gray);
    set(h_tabpanel(2), 'Visible', 'off');
    
    set(h_tabpb(3), 'Backgroundcolor', lt_gray);
    set(h_tabpanel(3), 'Visible', 'on');
    
    initOsImagePanel();
  end

  function Open_Help_callback(varargin)
    pathstr = which('wiki.html');
    web([pathstr]);
  end



% Main Tab
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------

component_height = .05;

main_tab_panel = sub_panel(h_tabpanel(1), [0 0 1 1], '', 'lefttop', 'k', lt_gray, 0.05, 'serif');
set(main_tab_panel, 'borderwidth', 0);

display_panel = sub_panel(main_tab_panel, [.01 .02 .7 .93], ['Image: <' '>'], 'lefttop', green_blue, lt_gray, 0.05, 'serif');
options_panel = sub_panel(main_tab_panel, [.72 .02 .27 .93], 'Data', 'lefttop', green_blue, lt_gray, 0.05, 'serif');

axes('Parent', options_panel, 'Units', 'normalized', 'Position', [.05 0 .9 .25]);
axis image;
axis off

try
  imshow('NIST_Logo.png');
catch err
  warning('Unable to load and show NIST logo.');
end



push_button(options_panel, [.88 .96 .1 component_height], '?', 'center', 'k', 'default', .6, 'sans serif', 'bold', 'on', {@main_help_callback});

  function main_help_callback(varargin)
    pathstr = which('wiki.html');
    web([pathstr '#main-tab']);
  end


label(options_panel, [.01 .89 .99 component_height], 'Raw Images Path:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
input_dir_editbox = editbox(options_panel, [.01 .85 .98 component_height], raw_images_path, 'left', 'k', 'w', .6, 'normal');
push_button(options_panel, [.5 .795 .485 component_height], 'Browse', 'center', 'k', 'default', 0.5, 'sans serif', 'bold', 'on',  {@choose_raw_images_callback} );

label(options_panel, [.01 .69 .95 .05], 'Raw Common Name:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
common_name_editbox = editbox(options_panel, [.01 .65 .98 component_height], '', 'left', 'k', 'w', .6, 'normal');

  function choose_raw_images_callback(varargin)
    % get directory
    sdir = uigetdir(pwd,'Select Image(s)');
    if sdir ~= 0
      try
        raw_images_path = validate_filepath(sdir);
      catch err
        if (strcmp(err.identifier,'validate_filepath:notFoundInPath')) || ...
            (strcmp(err.identifier,'validate_filepath:argChk'))
          errordlg('Invalid directory selected');
          return;
        else
          rethrow(err);
        end
      end
      set(input_dir_editbox, 'String', raw_images_path);
    end
  end



push_button(options_panel, [.1 .49 .8 1.5*component_height], 'Load Images', 'center', 'k', dark_gray, 0.6, 'sans serif', 'bold', 'on',  {@initImages} );


  function initImages(varargin)
    
    % get path and common name info from gui
    raw_images_path = get(input_dir_editbox, 'string');
    if raw_images_path(end) ~= filesep
      raw_images_path = [raw_images_path filesep];
    end
    raw_images_common_name = get(common_name_editbox, 'string');
    
    if ~isempty(raw_images_common_name)
      raw_image_files = dir([raw_images_path '*' raw_images_common_name '*.tif']);
    else
      raw_image_files = dir([raw_images_path '*.tif']);
    end
    nb_frames = length(raw_image_files);
    if nb_frames <= 0
      errordlg('Chosen img folder doesn''t contain any .tif images.');
      return;
    end
    
    % explore the possibility that this single image contains a sequence internally
    if nb_frames == 1
      stats = imfinfo([raw_images_path raw_image_files(1).name]);
      if numel(stats) > 1
        nb_frames = numel(stats);
        raw_image_files = repmat(raw_image_files, nb_frames,1);
      end
    end
    
    
    % Get first img to check its size
    current_frame_nb = 1;
    img = loadCurrentImage();
    
    % if img is very large, send the user a warning
    if numel(img) > 10^7
      
      response = questdlg('Images are large! Visualization might be slow, Continue?', ...
        'Notice','Yes','Cancel','Cancel');
      % Handle response
      switch response
        case 'Yes'
          % continue displaying images
        case 'Cancel'
          return; % if the user did not select yes for continue, abort visualization
      end
      
    end
    
    pre_image_loading = false; % images have been loaded
    destroyMasks();
    initMainImagePanel();
    
    set(h_tabpb(2), 'enable', 'on');
    
    
  end

  function I = loadCurrentImage(nb)
    if nargin == 0
      nb = current_frame_nb;
    end
    if numel(imfinfo([raw_images_path raw_image_files(nb).name])) > 1
      I = imread([raw_images_path raw_image_files(nb).name], 'Index', nb);
    else
      I = imread([raw_images_path raw_image_files(nb).name]);
    end
  end


  function initMainImagePanel(varargin)
    
    if pre_image_loading, return, end
    
    
    
    % Create Slider for img display
    image_slider_edit = uicontrol('style','slider',...
      'Parent',display_panel,...
      'unit','normalized',...
      'Min',1,'Max',nb_frames,'Value',current_frame_nb, ...
      'position',[.01 0.01 0.6 0.05],...
      'SliderStep', [1, 1]/max((nb_frames - 1),1), ...  % Map SliderStep to whole number, Actual step = SliderStep * (Max slider value - Min slider value)
      'callback',{@imgSliderCallback});
    
    % Edit: Cell Numbers to show
    goto_user_frame_edit = uicontrol('style','Edit',...
      'Parent',display_panel,...
      'unit','normalized',...
      'position',[.63 0.01 0.1 0.05],...
      'HorizontalAlignment','center',...
      'String',num2str(current_frame_nb),...
      'FontUnits', 'normalized',...
      'fontsize',.5,...
      'fontweight','normal',...
      'backgroundcolor', 'w',...
      'callback',{@gotoFrameCallback});
    
    % # of frames label
    uicontrol('style','text',...
      'Parent',display_panel,...
      'unit','normalized',...
      'position',[.74 .005 .09 .05],...
      'HorizontalAlignment','left',...
      'String',['of ' num2str(nb_frames)],...
      'FontUnits', 'normalized',...
      'fontsize',.6,...
      'backgroundcolor', lt_gray,...
      'fontweight','normal');
    
    
    function imgSliderCallback(varargin)
      current_frame_nb = ceil(get(image_slider_edit, 'value'));
      set(goto_user_frame_edit, 'String', num2str(current_frame_nb));
      
      destroyMasks();
      img = loadCurrentImage();
      update_main_img();
    end
    
    function gotoFrameCallback(varargin)
      new_frame_nb = str2double(get(goto_user_frame_edit, 'String'));
      if isnan(new_frame_nb)
        errordlg('Invalid frame, please input a valid number.');
        set(goto_user_frame_edit, 'String', num2str(current_frame_nb));
        return;
      end
      
      % constrain the new frame number to the existing frame numbers
      new_frame_nb = min(new_frame_nb, nb_frames);
      new_frame_nb = max(1, new_frame_nb);
      
      current_frame_nb = new_frame_nb;
      set(goto_user_frame_edit, 'string', num2str(current_frame_nb));
      set(image_slider_edit, 'value', current_frame_nb);
      
      destroyMasks();
      img = loadCurrentImage();
      update_main_img();
    end
    
    img = loadCurrentImage();
    update_main_img();
    
  end

main_img_disp_axis = axes('Parent', display_panel, 'Units','normalized', 'Position', [.001 .1 .999 .90]);
axis off; axis image;
  function update_main_img(varargin)
    % Read corresponding images
    set(display_panel, 'Title', ['Image: <' raw_image_files(current_frame_nb).name '>']);
    img = double(img);
    
    
    delete(get(main_img_disp_axis, 'Children'));
    imshow(img, [], 'parent', main_img_disp_axis);
    
  end



%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
% Foreground Mask
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------

fg_colormap_selected_option = colormap_options{1};
fg_countour_color_selected_opt = contour_color_options{1};

fg_display_contour = true;
fg_display_raw_image = true;
fg_import_masks = false;
fg_strel_disk_radius = 2;

morphological_operations = {'None','Dilate','Erode','Close','Open'};
fg_morph_operation = morphological_operations{1};
fg_min_object_size = min_object_size;
fg_min_hole_size = 2*fg_min_object_size;
fg_max_hole_size = Inf;
fg_hole_min_perct_intensity = 0;
fg_hole_max_perct_intensity = 100;


greedy_range = 50;

foreground_mask_panel = sub_panel(h_tabpanel(2), [0 0 1 1], '', 'lefttop', 'k', lt_gray, 0.05, 'serif');
set(foreground_mask_panel, 'borderwidth', 0);

fg_display_panel = sub_panel(foreground_mask_panel, [.01 .02 .7 .93], ['Image: <' '>'], 'lefttop', green_blue, lt_gray, 0.05, 'serif');



%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
% Foereground EGT Panel
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
fg_options_panel = sub_panel(foreground_mask_panel, [.72 .02 .27 .93], 'Options', 'lefttop', green_blue, lt_gray, 0.04, 'serif');

push_button(fg_options_panel, [.88 .96 .1 component_height], '?', 'center', 'k', 'default', .6, 'sans serif', 'bold', 'on', {@fg_help_callback});

  function fg_help_callback(varargin)
    pathstr = which('wiki.html');
    web([pathstr '#foreground-mask-tab']);
  end


fg_import_checkbox = checkbox(fg_options_panel, [.05 .94 .8 component_height], 'Import Foreground Mask(s)', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@fg_import_checkbox_Callback});
set(fg_import_checkbox, 'value',fg_import_masks);
  function fg_import_checkbox_Callback(varargin)
    if fg_import_masks
      fg_import_masks = logical(get(fg_import_checkbox2, 'value'));
    else
      fg_import_masks = logical(get(fg_import_checkbox, 'value'));
    end
    set(fg_import_checkbox, 'value',fg_import_masks);
    set(fg_import_checkbox2, 'value',fg_import_masks);
    
    
    if fg_import_masks
      set(fg_options_panel, 'visible','off');
      set(fg_options_panel2, 'visible','on');
    else
      set(fg_options_panel, 'visible','on');
      set(fg_options_panel2, 'visible','off');
    end
  end


y = 0.865;
label(fg_options_panel, [.05 y .45 component_height], 'Min Object Area', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
fg_min_object_size_edit = editbox_check(fg_options_panel, [.5 y .3 component_height], num2str(fg_min_object_size), 'left', 'k', 'w', .6, 'normal', @fg_min_object_size_Callback);
label(fg_options_panel, [.82 y .1 component_height], 'px', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');

  function bool = fg_min_object_size_Callback(varargin)
    bool = false;
    temp = str2double(get(fg_min_object_size_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Min Object Size');
      return;
    end
    fg_min_object_size = temp;
    bool = true;
  end

% Fill holes sub-panel
fg_fill_holes_panel = sub_panel(fg_options_panel, [.02 .63 .96 .22], 'Keep Holes with', 'lefttop', green_blue, lt_gray, 0.16, 'serif');
fill_hole_subpanel_height = 0.25;
y = .7;
fg_min_hole_size_edit = editbox_check(fg_fill_holes_panel, [.03 y .19 fill_hole_subpanel_height], num2str(fg_min_hole_size), 'left', 'k', 'w', .7, 'normal', @fg_min_hole_size_Callback);
label(fg_fill_holes_panel, [.22 y .54 fill_hole_subpanel_height], '< size (pixels) <', 'center', 'k', lt_gray, .8, 'sans serif', 'normal');
fg_max_hole_size_edit = editbox_check(fg_fill_holes_panel, [.78 y .19 fill_hole_subpanel_height], num2str(fg_max_hole_size), 'left', 'k', 'w', .7, 'normal', @fg_max_hole_size_Callback);

y = .4;
fill_holes_options = {'AND','OR'};
fg_hole_fill_pop = popupmenu(fg_fill_holes_panel, [0.39 y 0.22 0.22], fill_holes_options, 'k', 'w', .7, 'normal',[]);

y = .05;
fg_hole_min_perct_intensity_edit = editbox_check(fg_fill_holes_panel, [.03 y .19 fill_hole_subpanel_height], num2str(fg_hole_min_perct_intensity), 'left', 'k', 'w', .7, 'normal', @fg_hole_min_perct_intensity_Callback);
label(fg_fill_holes_panel, [.22 y .54 fill_hole_subpanel_height], '< intensity (%) <', 'center', 'k', lt_gray, .8, 'sans serif', 'normal');
fg_hole_max_perct_intensity_edit = editbox_check(fg_fill_holes_panel, [.78 y .19 fill_hole_subpanel_height], num2str(fg_hole_max_perct_intensity), 'left', 'k', 'w', .7, 'normal', @fg_hole_max_perct_intensity_Callback);

  function bool = fg_min_hole_size_Callback(varargin)
    bool = false;
    temp = str2double(get(fg_min_hole_size_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Min Hole Size');
      return;
    end
    fg_min_hole_size = temp;
    bool = true;
  end

  function bool = fg_max_hole_size_Callback(varargin)
    bool = false;
    temp = str2double(get(fg_max_hole_size_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Max Hole Size');
      return;
    end
    fg_max_hole_size = temp;
    bool = true;
  end

  function bool = fg_hole_min_perct_intensity_Callback(varargin)
    bool = false;
    temp = str2double(get(fg_hole_min_perct_intensity_edit, 'String'));
    if isnan(temp) || temp < 0 || temp > 100
      errordlg('Invalid Percentile Intensity threshold');
      return;
    end
    fg_hole_min_perct_intensity = temp;
    bool = true;
  end

  function bool = fg_hole_max_perct_intensity_Callback(varargin)
    bool = false;
    temp = str2double(get(fg_hole_max_perct_intensity_edit, 'String'));
    if isnan(temp) || temp < 0 || temp > 100
      errordlg('Invalid Min Hole Size');
      return;
    end
    fg_hole_max_perct_intensity = temp;
    bool = true;
  end

y = .565;
label(fg_options_panel, [.05 y .95 component_height], 'Morphological Operation', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
fg_morph_dropdown = popupmenu(fg_options_panel, [.05 y-.04 .38 component_height], morphological_operations, 'k', 'w', .6, 'normal', @fg_morph_Callback);
label(fg_options_panel, [.43 y-.045 .34 component_height], 'with radius:', 'center', 'k', lt_gray, .6, 'sans serif', 'normal');
fg_strel_radius_edit = editbox_check(fg_options_panel, [.77 y-.04 .18 component_height], num2str(fg_strel_disk_radius), 'right', 'k', 'w', .6, 'normal', @fg_strel_radius_Callback);

  function fg_morph_Callback(varargin)
    temp = get(fg_morph_dropdown, 'value');
    fg_morph_operation = morphological_operations{temp};
  end

  function bool = fg_strel_radius_Callback(varargin)
    bool = false;
    temp = round(str2double(get(fg_strel_radius_edit, 'string')));
    if temp < 0
      errordlg('Invalid strel radius');
      return;
    end
    fg_strel_disk_radius = temp;
    bool = true;
  end


y = .46;
label(fg_options_panel, [.05 y .95 component_height], 'Greedy', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');

% Create Slider for img display
fg_greedy_slider_num = 0;
fg_greedy_edit = uicontrol('style','slider',...
  'Parent',fg_options_panel,...
  'unit','normalized',...
  'Min',-greedy_range,'Max',greedy_range,'Value',fg_greedy_slider_num, ...
  'position',[.05 y-.04 .8 component_height],...
  'SliderStep', [1, 1]/(greedy_range - -greedy_range), ...  % Map SliderStep to whole number, Actual step = SliderStep * (Max slider value - Min slider value)
  'callback',{@fgGreedySliderCallback});

fg_slider_num_label = label(fg_options_panel, [.875 y-.04 .1 component_height], fg_greedy_slider_num, 'center', 'k', lt_gray, .6, 'sans serif', 'normal');

  function fgGreedySliderCallback(varargin)
    fg_greedy_slider_num = ceil(get(fg_greedy_edit, 'value'));
    set(fg_slider_num_label, 'String', num2str(fg_greedy_slider_num));
  end


push_button(fg_options_panel, [.1 .335 .78 1.2*component_height], 'Update Preview', 'center', 'k', dark_gray, 0.5, 'sans serif', 'bold', 'on', {@fg_update_image});


label(fg_options_panel, [.05 .26 .95 component_height], 'ColorMap:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
fg_colormap_dropdown = popupmenu(fg_options_panel, [.05 .22 .91 component_height], colormap_options, 'k', 'w', .6, 'normal', @fg_colormap_Callback);
  function fg_colormap_Callback(varargin)
    temp = get(fg_colormap_dropdown, 'value');
    fg_colormap_selected_option = colormap_options(temp);
    fg_colormap_selected_option = fg_colormap_selected_option{1};
    fg_update_display();
  end


fg_contour_checkbox = checkbox(fg_options_panel, [.05 .14 .54 component_height], 'Display Contour', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@fg_contour_checkbox_Callback});
set(fg_contour_checkbox, 'value',fg_display_contour);
  function fg_contour_checkbox_Callback(varargin)
    fg_display_contour = logical(get(fg_contour_checkbox, 'value'));
    if(nb_frames <= 0)
      return;
    else
      fg_update_display();
    end
  end

fg_contour_color_dropdown = popupmenu(fg_options_panel, [.66 .14 .3 component_height], contour_color_options, 'k', 'w', .6, 'normal', @contour_color_callback);
  function contour_color_callback(varargin)
    temp1 = get(fg_contour_color_dropdown, 'value');
    fg_countour_color_selected_opt = contour_color_options(temp1);
    fg_update_display();
  end

fg_raw_image_checkbox = checkbox(fg_options_panel, [.05 .08 .65 component_height], 'Display Raw Image', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@fg_raw_image_checkbox_Callback});
set(fg_raw_image_checkbox, 'value',fg_display_raw_image);
  function fg_raw_image_checkbox_Callback(varargin)
    fg_display_raw_image = logical(get(fg_raw_image_checkbox, 'value'));
    if(nb_frames <= 0)
      return;
    else
      fg_update_display();
    end
  end

Adjust_Contrast_raw_image_checkbox1 = checkbox(fg_options_panel, [.05 .03 .65 component_height], 'Adjust Contrast', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@Adjust_Contrast_raw_image_checkbox_Callback});
set(Adjust_Contrast_raw_image_checkbox1, 'value',fg_adjust_contrast_display_raw_image);
  function Adjust_Contrast_raw_image_checkbox_Callback(varargin)
    fg_adjust_contrast_display_raw_image = logical(get(Adjust_Contrast_raw_image_checkbox1, 'value'));
    if(nb_frames <= 0)
      return;
    else
      fg_update_display();
    end
  end


%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
% Foreground Mask Load Panel
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
fg_options_panel2 = sub_panel(foreground_mask_panel, [.72 .02 .27 .93], 'Options', 'lefttop', green_blue, lt_gray, 0.05, 'serif');
if fg_import_masks
  set(fg_options_panel, 'visible','off');
  set(fg_options_panel2, 'visible','on');
else
  set(fg_options_panel, 'visible','on');
  set(fg_options_panel2, 'visible','off');
end
push_button(fg_options_panel2, [.88 .96 .1 component_height], '?', 'center', 'k', 'default', .6, 'sans serif', 'bold', 'on', {@fg_help_callback});


fg_import_checkbox2 = checkbox(fg_options_panel2, [.05 .94 .8 component_height], 'Import Foreground Mask(s)', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@fg_import_checkbox_Callback});
set(fg_import_checkbox2, 'value',fg_import_masks);

fg_mask_path = [pwd filesep 'test' filesep];
fg_common_name = '';
fg_img_files = [];

label(fg_options_panel2, [.01 .86 .99 component_height], 'Foreground Mask Path:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
fg_input_dir_editbox = editbox(fg_options_panel2, [.01 .8 .98 component_height], fg_mask_path, 'left', 'k', 'w', .6, 'normal');
push_button(fg_options_panel2, [.5 .74 .485 component_height], 'Browse', 'center', 'k', 'default', 0.5, 'sans serif', 'bold', 'on',  {@choose_fg_images_callback} );

label(fg_options_panel2, [.01 .62 .95 component_height], 'Foreground Mask Common Name:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
fg_common_name_editbox = editbox(fg_options_panel2, [.01 .58 .98 component_height], fg_common_name, 'left', 'k', 'w', .6, 'normal');

  function choose_fg_images_callback(varargin)
    % get directory
    sdir = uigetdir(pwd,'Select Image(s)');
    if sdir ~= 0
      try
        fg_mask_path = validate_filepath(sdir);
      catch err
        if (strcmp(err.identifier,'validate_filepath:notFoundInPath')) || ...
            (strcmp(err.identifier,'validate_filepath:argChk'))
          errordlg('Invalid directory selected');
          return;
        else
          rethrow(err);
        end
      end
      set(fg_input_dir_editbox, 'String', fg_mask_path);
    end
  end


% Update Button
push_button(fg_options_panel2, [.1 .35 .78 1.2*component_height], 'Update Foreground Mask', 'center', 'k', dark_gray, .5, 'sans serif', 'bold', 'on', {@fg_update_image});


label(fg_options_panel2, [.05 .26 .95 component_height], 'ColorMap:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
fg_colormap2_dropdown = popupmenu(fg_options_panel2, [.05 .22 .91 component_height], colormap_options, 'k', 'w', .6, 'normal', @fg_colormap2_Callback);
  function fg_colormap2_Callback(varargin)
    temp = get(fg_colormap2_dropdown, 'value');
    fg_colormap_selected_option = colormap_options(temp);
    fg_colormap_selected_option = fg_colormap_selected_option{1};
    fg_update_display();
  end


fg_contour2_checkbox = checkbox(fg_options_panel2, [.05 .14 .54 component_height], 'Display Contour', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@fg_contour2_checkbox_Callback});
set(fg_contour2_checkbox, 'value',fg_display_contour);
  function fg_contour2_checkbox_Callback(varargin)
    fg_display_contour = logical(get(fg_contour2_checkbox, 'value'));
    if(nb_frames <= 0)
      return;
    else
      fg_update_display();
    end
  end

fg_contour_color2_dropdown = popupmenu(fg_options_panel2, [.66 .14 .3 component_height], contour_color_options, 'k', 'w', .6, 'normal', @contour_color2_callback);
  function contour_color2_callback(varargin)
    temp1 = get(fg_contour_color2_dropdown, 'value');
    fg_countour_color_selected_opt = contour_color_options(temp1);
    fg_update_display();
  end

fg_raw_image2_checkbox = checkbox(fg_options_panel2, [.05 .08 .65 component_height], 'Display Raw Image', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@fg_raw_image2_checkbox_Callback});
set(fg_raw_image2_checkbox, 'value',fg_display_raw_image);
  function fg_raw_image2_checkbox_Callback(varargin)
    fg_display_raw_image = logical(get(fg_raw_image2_checkbox, 'value'));
    if(nb_frames <= 0)
      return;
    else
      fg_update_display();
    end
  end

Adjust_Contrast_raw_image2_checkbox1 = checkbox(fg_options_panel2, [.05 .03 .65 component_height], 'Adjust Contrast', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@Adjust_Contrast2_raw_image_checkbox_Callback});
set(Adjust_Contrast_raw_image2_checkbox1, 'value',fg_adjust_contrast_display_raw_image);
  function Adjust_Contrast2_raw_image_checkbox_Callback(varargin)
    fg_adjust_contrast_display_raw_image = logical(get(Adjust_Contrast_raw_image2_checkbox1, 'value'));
    if(nb_frames <= 0)
      return;
    else
      fg_update_display();
    end
  end


% ---------------------------------------------------------------------------------------
% Display Panel

% setup the display panel for the foreground tab

  function bool = Foreground_Options_validate(varargin)
    bool = false;
    fg_morph_Callback();
    fg_strel_radius_Callback();
    if ~fg_min_object_size_Callback(), return, end
    if ~fg_min_hole_size_Callback(), return, end
    bool = true;
    
  end

  function initFgImagePanel(varargin)
    
    % Create Slider for img display
    image_slider_edit = uicontrol('style','slider',...
      'Parent',fg_display_panel,...
      'unit','normalized',...
      'Min',1,'Max',nb_frames,'Value',current_frame_nb, ...
      'position',[.01 0.01 0.6 0.05],...
      'SliderStep', [1, 1]/max((nb_frames - 1),1), ...  % Map SliderStep to whole number, Actual step = SliderStep * (Max slider value - Min slider value)
      'callback',{@imgSliderCallback});
    
    % Edit: Cell Numbers to show
    goto_user_frame_edit = uicontrol('style','Edit',...
      'Parent',fg_display_panel,...
      'unit','normalized',...
      'position',[.63 0.01 0.1 0.05],...
      'HorizontalAlignment','center',...
      'String',num2str(current_frame_nb),...
      'FontUnits', 'normalized',...
      'fontsize',.5,...
      'fontweight','normal',...
      'backgroundcolor', 'w',...
      'callback',{@gotoFrameCallback});
    
    % # of frames label
    uicontrol('style','text',...
      'Parent',fg_display_panel,...
      'unit','normalized',...
      'position',[.74 .005 .09 .05],...
      'HorizontalAlignment','left',...
      'String',['of ' num2str(nb_frames)],...
      'FontUnits', 'normalized',...
      'fontsize',.6,...
      'backgroundcolor', lt_gray,...
      'fontweight','normal');
    
    function imgSliderCallback(varargin)
      current_frame_nb = ceil(get(image_slider_edit, 'value'));
      set(goto_user_frame_edit, 'String', num2str(current_frame_nb));
      
      destroyMasks();
      img = loadCurrentImage();
      fg_update_image();
      
    end
    
    function gotoFrameCallback(varargin)
      new_frame_nb = str2double(get(goto_user_frame_edit, 'String'));
      if isnan(new_frame_nb)
        errordlg('Invalid frame, please input a valid number.');
        set(goto_user_frame_edit, 'String', num2str(current_frame_nb), 'Index', current_frame_nb);
        return;
      end
      
      % constrain the new frame number to the existing frame numbers
      new_frame_nb = min(new_frame_nb, nb_frames);
      new_frame_nb = max(1, new_frame_nb);
      
      current_frame_nb = new_frame_nb;
      set(goto_user_frame_edit, 'string', num2str(current_frame_nb));
      set(image_slider_edit, 'value', current_frame_nb);
      
      destroyMasks();
      img = loadCurrentImage();
      fg_update_image();
    end
    
    img = loadCurrentImage();
    fg_update_image();
    
  end



fg_axis = axes('Parent', fg_display_panel, 'Units','normalized', 'Position', [.001 .1 .999 .90]);
axis off; axis image;
colors_vector = 0;

% recompute foreground mask and update display, used for img slider and goto frame input
  function fg_update_image(varargin)
    h = msgbox('Foreground Segmentation...');
    computeFgMask();
    
    if isempty(img) || isempty(foreground_mask)
      return;
    end
    delete(get(fg_axis, 'Children'));
    [disp_I, colors_vector] = superimpose_colormap_contour(img, foreground_mask, colormap([fg_colormap_selected_option '(65000)']), fg_countour_color_selected_opt, fg_display_raw_image, fg_display_contour, fg_adjust_contrast_display_raw_image, colors_vector);
    imshow(disp_I, 'Parent', fg_axis);
    if ishandle(h), close(h); end
  end

% updates foreground img display without recomputing the mask, used for displaying raw img, img contours, and colormaps
  function fg_update_display(varargin)
    delete(get(fg_axis, 'Children'));
    [disp_I, colors_vector] = superimpose_colormap_contour(img, foreground_mask, colormap([fg_colormap_selected_option '(65000)']), fg_countour_color_selected_opt, fg_display_raw_image, fg_display_contour, fg_adjust_contrast_display_raw_image, colors_vector);
    imshow(disp_I, 'Parent', fg_axis);
    
    %         set(fg_axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
  end


% Computes the foreground mask
% NOTE: also used in object separation slider to recompute the foreground mask when the img is changed
  function computeFgMask(varargin)
    if ~Foreground_Options_validate(), return, end
    
    set(fg_display_panel, 'Title', ['Image: <' raw_image_files(current_frame_nb).name '>']);
    BW = get_Foreground_Mask();
    if ~isempty(BW)
      foreground_mask = BW;
    end
  end


  function BW = get_Foreground_Mask(img_nb)
    if nargin == 0
      img_nb = current_frame_nb;
    end
    if fg_import_masks
      % load the required image
      
      fg_mask_path = get(fg_input_dir_editbox, 'String');
      if fg_mask_path(end) ~= filesep
        fg_mask_path = [fg_mask_path filesep];
      end
      
      fg_common_name = get(fg_common_name_editbox, 'String');
      
      % validate that the number of images matches
      fg_img_files = dir([fg_mask_path '*' fg_common_name '*.tif']);
      nb_fg_frames = length(fg_img_files);
      if nb_fg_frames == 1
        stats = imfinfo([fg_mask_path fg_img_files(img_nb).name]);
        if numel(stats) > 1
          nb_fg_frames = numel(stats);
          fg_img_files = repmat(fg_img_files, nb_fg_frames, 1);
        end
      end
      
      if nb_fg_frames ~= nb_frames
        errordlg('Chosen foreground image folder doesn''t the same number of .tif images as the images being segmented.');
        return;
      end
      
      set(fg_display_panel, 'Title', ['Image: <' fg_img_files(img_nb).name '>']);
      
      if numel(imfinfo([fg_mask_path fg_img_files(img_nb).name])) > 1
        BW = imread([fg_mask_path fg_img_files(img_nb).name], 'Index', img_nb);
      else
        BW = imread([fg_mask_path fg_img_files(img_nb).name]);
      end
      BW = logical(BW);
      
      % check that the image is the same size
      if size(img,1) ~= size(BW,1) || size(img,2) ~= size(BW,2)
        BW = [];
        errordlg('Loaded foreground image is a different size than the image being segmented.');
        return;
      end
      
      
    else
      fill_holes_bool_oper = fill_holes_options{get(fg_hole_fill_pop, 'value')};
      BW = EGT_Segmentation(img,fg_min_object_size,fg_min_hole_size, fg_max_hole_size, fg_hole_min_perct_intensity, fg_hole_max_perct_intensity, fill_holes_bool_oper, fg_greedy_slider_num);
      fg_morph_operation = lower(regexprep(fg_morph_operation, '\W', ''));
      BW = morphOp(img, BW, fg_morph_operation, fg_strel_disk_radius);
      
      BW = fill_holes(BW, img, fg_min_hole_size, fg_max_hole_size, fg_hole_min_perct_intensity, fg_hole_max_perct_intensity, fill_holes_bool_oper);
      BW = bwareaopen(BW ,fg_min_object_size,8);
    end
  end

%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
% Object Separation Tab
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------

os_display_use_border = false;
os_display_use_seed = false;
os_display_use_mitotic = false;
os_display_contour = true;
os_display_raw_image = true;

fogbank_input_options = {'Grayscale Image','Distance Transform from Seeds', 'Distance Transform from Background','Gradient'};
fog_bank_directions = {'Min -> Max','Max -> Min'};
os_selected_colormap_opt = colormap_options{1};
os_display_labeled_text = false;
os_text_location = 0;
use_distance_transform_in_fogbank_flag = false;
fogbank_direction = fog_bank_directions{1};

min_peak_size = 1000;
nb_obj = 0;

border_mask = [];
seed_mask = [];
mitotic_mask = [];
segmented_image = [];



os_panel = sub_panel(h_tabpanel(3), [0 0 1 1], '', 'lefttop', 'k', lt_gray, 0.05, 'serif');
set(os_panel, 'borderwidth', 0);

os_display_panel = sub_panel(os_panel, [.01 .02 .7 .93], ['Image: <' '>'], 'lefttop', green_blue, lt_gray, 0.05, 'serif');
os_options_panel = sub_panel(os_panel, [.72 .02 .27 .93], 'Options', 'lefttop', green_blue, lt_gray, 0.05, 'serif');


push_button(os_options_panel, [.88 .96 .1 component_height], '?', 'center', 'k', 'default', .6, 'sans serif', 'bold', 'on', {@os_help_callback});

  function os_help_callback(varargin)
    pathstr = which('wiki.html');
    web([pathstr '#object-separation-tab']);
  end


%-----------------------------------------------------------------------------------------
% Border Mask
os_use_border_checkbox = checkbox(os_options_panel, [.05 .9 .65 component_height], 'Use Border Mask', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@os_use_border_checkbox_Callback});
set(os_use_border_checkbox, 'value', os_display_use_border);

  function os_use_border_checkbox_Callback(varargin)
    os_display_use_border = logical(get(os_use_border_checkbox, 'value'));
    if os_display_use_border
      set(border_mask_pb, 'enable', 'on');
    else
      set(border_mask_pb, 'enable', 'off');
    end
  end

border_mask_pb = push_button(os_options_panel, [.63 .9 .33 component_height], 'Generate', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'off', {@os_Border_Mask_Callback});


%-----------------------------------------------------------------------------------------
% Mitotic Mask
os_use_mitotic_checkbox = checkbox(os_options_panel, [.05 .83 .65 component_height], 'Use Mitotic Mask', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@os_use_mitotic_checkbox_Callback});
set(os_use_mitotic_checkbox, 'value', os_display_use_mitotic);

  function os_use_mitotic_checkbox_Callback(varargin)
    os_display_use_mitotic = logical(get(os_use_mitotic_checkbox, 'value'));
    
    if os_display_use_mitotic
      set(mitotic_mask_pb, 'enable', 'on');
    else
      set(mitotic_mask_pb, 'enable', 'off');
    end
  end

mitotic_mask_pb = push_button(os_options_panel, [.63 .83 .33 component_height], 'Generate', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'off', {@os_Mitotic_Mask_Callback});


%-----------------------------------------------------------------------------------------
% Seed Mask
os_use_seed_checkbox = checkbox(os_options_panel, [.05 .76 .65 component_height], 'Use Seed Mask', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@os_use_seed_checkbox_Callback});
set(os_use_seed_checkbox, 'value', os_display_use_seed);

  function os_use_seed_checkbox_Callback(varargin)
    os_display_use_seed = logical(get(os_use_seed_checkbox, 'value'));
    
    if os_display_use_seed
      set(os_min_peak_size_edit, 'visible', 'off');
      set(os_min_peak_size_label, 'visible', 'off');
      set(seed_mask_pb, 'visible', 'on');
      set(seed_mask_pb, 'enable', 'on');
      set(seed_mask_load_pb, 'visible', 'on');
      set(seed_mask_load_pb, 'enable', 'on');
    else
      set(os_min_peak_size_edit, 'visible', 'on');
      set(os_min_peak_size_label, 'visible', 'on');
      set(seed_mask_pb, 'visible', 'off');
      set(seed_mask_pb, 'enable', 'off');
      set(seed_mask_load_pb, 'visible', 'off');
      set(seed_mask_load_pb, 'enable', 'off');
    end
  end

os_min_peak_size_label = label(os_options_panel, [.05 .71 .65 component_height], 'Min Seed Size:', 'center', 'k', lt_gray, .6, 'sans serif', 'normal');
os_min_peak_size_edit = editbox_check(os_options_panel, [.63 .715 .33 component_height], num2str(min_peak_size), 'center', 'k', 'w', .6, 'normal', @os_min_peak_size_Callback);
  function bool = os_min_peak_size_Callback(varargin)
    bool = false;
    temp = str2double(get(os_min_peak_size_edit, 'string'));
    if isnan(temp) || temp < 0
      errordlg('Invalid min seed size');
      return;
    end
    min_peak_size = temp;
    bool = true;
  end

% seed mask push button, hidden until seed mask checkbox is selected
seed_mask_pb = push_button(os_options_panel, [.63 .76 .33 component_height], 'Generate', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'off', {@os_Seed_Mask_Callback});
set(seed_mask_pb, 'visible', 'off');

seed_mask_load_pb = push_button(os_options_panel, [.63 .70 .33 component_height], 'Load', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'off', {@os_Seed_Load_Mask_Callback});
set(seed_mask_load_pb, 'visible', 'off');


%-----------------------------------------------------------------------------------------
% Object Separation Panel Options
label(os_options_panel, [.05 .64 .95 component_height], 'Apply FogBank On:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
os_fogbank_input_dropdown = popupmenu(os_options_panel, [.05 .6 .91 component_height], fogbank_input_options, 'k', 'w', .6, 'normal', @os_fogbank_input_Callback);
  function os_fogbank_input_Callback(varargin)
    temp = get(os_fogbank_input_dropdown, 'value');
    if temp == 1
      % grayscale img selected
      use_distance_transform_in_fogbank_flag = false;
    else
      % distance transform selected
      use_distance_transform_in_fogbank_flag = true;
    end
  end


label(os_options_panel, [.05 .53 .65 component_height], 'Fogbank Direction:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
os_fogbank_direction_dropdown = popupmenu(os_options_panel, [.56 .535 .4 component_height], fog_bank_directions, 'k', 'w', .6, 'normal', @os_fogbank_direction_Callback);
  function os_fogbank_direction_Callback(varargin)
    temp = get(os_fogbank_direction_dropdown, 'value');
    fogbank_direction = fog_bank_directions{temp};
  end


label(os_options_panel, [.05 .46 .65 component_height], 'Min Object Area:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
os_min_object_size_edit = editbox_check(os_options_panel, [.56 .465 .305 component_height], num2str(min_object_size), 'center', 'k', 'w', .6, 'normal', @os_min_object_size_Callback);
label(os_options_panel, [.88 .465 .1 component_height], 'px', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
  function bool = os_min_object_size_Callback(varargin)
    bool = false;
    temp = str2double(get(os_min_object_size_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Min Object Size');
      return;
    end
    min_object_size = temp;
    bool = true;
  end



push_button(os_options_panel, [.1 .38 .78 1.2*component_height], 'Update Preview', 'center', 'k', dark_gray, .5, 'sans serif', 'bold', 'on', {@os_update_image});




label(os_options_panel, [.05 .3 .95 component_height], 'ColorMap:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
OS_Options_colormap_dropdown = popupmenu(os_options_panel, [.05 .26 .91 component_height], colormap_options, 'k', 'w', .6, 'normal', @os_colormap_Callback);
  function os_colormap_Callback(varargin)
    temp = get(OS_Options_colormap_dropdown, 'value');
    os_selected_colormap_opt = colormap_options(temp);
    os_selected_colormap_opt = os_selected_colormap_opt{1};
    os_update_display();
    
  end


os_Display_labeled_text_checkbox = checkbox(os_options_panel, [.53 .31 .45 component_height], 'Show Labels', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@os_Display_labeled_text_checkbox_Callback});
  function os_Display_labeled_text_checkbox_Callback(varargin)
    os_display_labeled_text = logical(get(os_Display_labeled_text_checkbox, 'value'));
    os_update_display();
  end


os_contour_checkbox = checkbox(os_options_panel, [.05 .2 .91 component_height], 'Display Contour', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@os_contour_Callback});
set(os_contour_checkbox, 'value',os_display_contour);
  function os_contour_Callback(varargin)
    os_display_contour = get(os_contour_checkbox,'value');
    os_update_display();
  end


os_raw_image_checkbox = checkbox(os_options_panel, [.05 .15 .65 component_height], 'Display Raw Image', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@os_raw_image_Callback});
set(os_raw_image_checkbox, 'value', os_display_raw_image);
  function os_raw_image_Callback(varargin)
    os_display_raw_image = get(os_raw_image_checkbox, 'value');
    os_update_display();
  end

Adjust_contrast_raw_image_checkbox2 = checkbox(os_options_panel, [.05 .1 .65 component_height], 'Adjust Contrast', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@os_Adjust_contrast_raw_image_Callback});
  function os_Adjust_contrast_raw_image_Callback(varargin)
    os_adjust_contrast_display_raw_image = get(Adjust_contrast_raw_image_checkbox2, 'value');
    os_update_display();
  end

save_pb = push_button(os_options_panel, [.1 .01 .78 1.2*component_height], 'Save Images', 'center', 'k', dark_gray, .5, 'sans serif', 'bold', 'on', {@save_images_GUI_callback});


% Save images popup GUI
% -------------------------------------------------------------------------------------
  function save_images_GUI_callback(varargin)
    % Create figure, if found return, this prevents opening multiples of the same figure
    % Create figure in case not found
    save_figure_name = 'Save Images';
    open_save_fig_handle = findobj('type','figure','name',save_figure_name);
    
    if ~isempty(open_save_fig_handle)
      save_fig = findobj('type','figure','name',save_figure_name);
      figure(save_fig)
    else
      save_fig = figure(...
        'units', 'pixels',...
        'Position', [ (MaxMonitorX-gui_width*0.3)/2 - offset, (MaxMonitorY-gui_height*0.5)/2 + offset, gui_width*0.3, gui_height*0.5 ], ...
        'Name',save_figure_name,...
        'NumberTitle','off',...
        'Menubar','none',...
        'Toolbar','none',...
        'Resize', 'on');
    end
    
    save_image_format_opts = {'Tiff','PNG','JPG'};
    save_image_format = save_image_format_opts{1};
    save_common_name = ''; % 'segmented_';
    save_range = 'All';
    
    type_format_opts = {'Binary Mask', 'Labeled Mask', 'As Shown in Preview'};
    type_format = type_format_opts{2};
    
    
    
    content_panel = sub_panel(save_fig, [0 0 1 1], '', 'lefttop', green_blue, lt_gray, 0.1, 'serif');
    
    label(content_panel, [.03 .86 .2 .09], 'Format:', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
    format_edit_dropdown = popupmenu(content_panel, [.27 .87 .7 .09], save_image_format_opts, 'k', 'w', .6, 'normal', {@format_callback});
    label(content_panel, [.27 .78 .7 .09], 'Binary mask saved as Tiff only', 'left', 'k', lt_gray, .45, 'sans serif', 'normal');
    set(format_edit_dropdown, 'value',1);
    
    function format_callback(varargin)
      temp = get(format_edit_dropdown, 'value');
      save_image_format = save_image_format_opts{temp};
    end
    
    label(content_panel, [.03 .68 .2 .09], 'Prefix:', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
    save_common_name_edit = editbox(content_panel, [.27 .69 .7 .09], save_common_name, 'left', 'k', 'w', .6, 'normal');
    label(content_panel, [.27 .6 .7 .09], 'Leave blank to use input file names', 'left', 'k', lt_gray, .45, 'sans serif', 'normal');
    
    label(content_panel, [.03 .50 .2 .09], 'Range:', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
    save_range_edit = editbox(content_panel, [.27 .51 .7 .09], save_range, 'left', 'k', 'w', .6, 'normal');
    label(content_panel, [.27 .42 .7 .09], 'i.e. - All or subset 1,2,3:7,12', 'left', 'k', lt_gray, .45, 'sans serif', 'normal');
    
    label(content_panel, [.03 .32 .2 .09], 'Type:', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
    type_edit_dropdown = popupmenu(content_panel, [.27 .33 .7 .09], type_format_opts, 'k', 'w', .6, 'normal', {@type_callback});
    set(type_edit_dropdown, 'value', 2);
    
    function type_callback(varargin)
      temp1 = get(type_edit_dropdown, 'value');
      type_format = type_format_opts{temp1};
    end
    
    
    push_button(content_panel, [.01 .01 .49 .09], 'Save', 'center', 'k', 'default', 0.5, 'sans serif', 'bold', 'on', {@save_callback});
    push_button(content_panel, [.5 .01 .49 .09], 'Cancel', 'center', 'k', 'default', 0.5, 'sans serif', 'bold', 'on', {@cancel_save_callback});
    
    function save_callback(varargin)
      save_common_name = get(save_common_name_edit, 'String');
      save_range = get(save_range_edit, 'String');
      
      save_images(save_image_format, save_common_name, save_range, type_format);
      if ishandle(save_fig), close(save_fig); end
    end
    
    
    function cancel_save_callback(varargin)
      if ishandle(save_fig), close(save_fig); end
    end
    
    
  end


% Format = tif, png, or jpg
% Name = common name of images
% Range = All or 1,2,3:7,9
% Type = Binary mask or As shown in Preview

  function save_images(format, name, range, type, varargin)
    % directory
    sdir = uigetdir(raw_images_path,'Select Saved Path');
    if sdir ~= 0
      try
        h = msgbox('Working...');
        nb_frames_temp = nb_frames;
        
        save_images_path = validate_filepath(sdir);
        
        print_to_command(['Saving Images to: ' save_images_path]);
        
        formatted_format = '';
        switch(format)
          case 'PNG'
            formatted_format = '.png';
          case 'JPG'
            formatted_format = '.jpg';
          otherwise
            formatted_format = '.tif';
        end
        
        if(strcmp(range, 'All'))
          range = '0';
        end
        
        frames_to_save = str2num(range); %#ok<ST2NM>
        % truncate frames_to_save
        frames_to_save( frames_to_save > nb_frames_temp) = [];
        if ~isempty(frames_to_save) && any(frames_to_save > 0)
          nb_frames_temp = numel(frames_to_save);
        else
          frames_to_save = 1:nb_frames_temp;
          nb_frames_temp = numel(frames_to_save);
        end
        
        
        % write the metadata to log file to save the parameters used
        fh = fopen([save_images_path 'parameters.log'],'w');
        fprintf(fh,'Fogbank Run on %s\n\n', datestr(clock));
        
        fprintf(fh,'Foreground Segmentation Parameters\n');
        if fg_import_masks
          % if the foreground mask was loaded from disk
          fprintf(fh,'Foreground Mask Path: %s\n',fg_mask_path);
          fprintf(fh,'Foreground Common Name: %s\n',fg_common_name);
        else
          % if the foreground mask was segmented in the GUI
          fprintf(fh,'Min Cell Area: %d\n',fg_min_object_size);
          fprintf(fh,'Fill Holes Smaller Than: %d\n',fg_min_hole_size);
          fprintf(fh,'Fill Holes Larger Than: %d\n',fg_max_hole_size);
          fprintf(fh, 'Keep Holes with Operator: %s\n',fill_holes_options{get(fg_hole_fill_pop, 'value')});
          fprintf(fh,'Fill Holes with percentile intensity less than: %d\n',fg_hole_min_perct_intensity);
          fprintf(fh,'Fill Holes with percentile intensity larger than: %d\n',fg_hole_max_perct_intensity);
          fprintf(fh,'Morphological Operation: %s with radius %d\n',fg_morph_operation, fg_strel_disk_radius);
          fprintf(fh,'Greedy: %d\n',fg_greedy_slider_num);
        end
        
        if os_display_use_border
          fprintf(fh,'\nBorder Mask Generation\n');
          fprintf(fh,'Percentile Threshold: %s %d\n', border_threshold_operator_modifier, border_threshold_value);
          fprintf(fh,'Thin Mask: %d\n',border_thin_mask_flag);
          fprintf(fh,'Operate on Gradient: %d\n',border_operate_on_gradient_flag);
          fprintf(fh,'Break Holes: %d\n',border_break_holes_flag);
        end
        if os_display_use_seed
          fprintf(fh,'\nSeed Mask Generation\n');
          fprintf(fh,'Percentile Threshold: %d %s pixel %s %d\n', seed_threshold_valueL, seed_threshold_operatorL, seed_threshold_operatorR, seed_threshold_valueR);
          fprintf(fh,'Object Size Range: %d to %d\n',seed_min_object_size, seed_max_object_size);
          fprintf(fh,'Morphological Operation: %s with radius %d\n',seed_morph_operation, seed_strel_disk_radius);
          fprintf(fh,'Circularity Threshold: %d\n',seed_circularity_threshold);
          fprintf(fh,'Cluster Distance: %d\n',seed_cluster_dist);
          fprintf(fh,'Use Border Mask: %d\n',seed_use_border);
          fprintf(fh,'Operate on Gradient: %d\n',seed_operate_on_gradient_flag);
        end
        if os_display_use_mitotic
          fprintf(fh,'\nMitotic Mask Generation\n');
          fprintf(fh,'Operating on Image %s\n',mitotic_grayscale_modifier);
          fprintf(fh,'whose %s\n',mitotic_threshold_modifier);
          fprintf(fh,'values %s %d\n',mitotic_threshold_operator, mitotic_threshold_value);
          fprintf(fh,'Morphological Operations: %s with radius %d\n',mitotic_morph_operation, mitotic_strel_disk_radius);
          fprintf(fh,'Fogbank Direction: %s\n',mitotic_fogbank_direction);
          fprintf(fh,'Min Object Area: %d\n',mitotic_min_object_size);
          fprintf(fh,'Min Seed Area: %d\n',mitotic_min_peak_size);
        end
        fprintf(fh,'\nObject Separation\n');
        if ~os_display_use_seed
          fprintf(fh,'Min Seed Size: %d\n',min_peak_size);
        end
        fprintf(fh,'Apply Fogbank On: %s\n',fogbank_input_options{get(os_fogbank_input_dropdown, 'value')});
        fprintf(fh,'Fogbank Direction: %s\n',fogbank_direction);
        fprintf(fh,'Min Object Area: %d\n',min_object_size);
        fclose(fh);
        
        
        print_update(1, 1, nb_frames_temp);
        for i = 1:nb_frames_temp
          
          print_update(2,i,frames_to_save(nb_frames_temp));
          
          [segmented_image, nb_obj] = fogbank_given_image(frames_to_save(i));
          
          if isempty(img) || isempty(segmented_image)
            return;
          end
          
          if isempty(name)
            output_filename = raw_image_files(frames_to_save(i)).name;
          else
            output_filename = [name raw_image_files(frames_to_save(i)).name];
          end
          
          % change the output image format to the requested
          [~,fn,~] = fileparts(output_filename);
          output_filename = [fn formatted_format];
          
          switch type
            case 'Binary Mask'
              imwrite(uint16(logical(segmented_image)), [save_images_path filesep output_filename]);
            case 'Labeled Mask'
              imwrite(uint16(segmented_image), [save_images_path filesep output_filename]);
            otherwise % 'As Shown in Preview'
              imwrite(get_Superimpose_Image(), [save_images_path filesep output_filename]);
          end
        end
        
        if ishandle(h), close(h); end
        
      catch err
        if ishandle(h), close(h); end
        if (strcmp(err.identifier,'validate_filepath:notFoundInPath')) || ...
            (strcmp(err.identifier,'validate_filepath:argChk'))
          errordlg('Invalid directory selected');
          return;
        else
          rethrow(err);
        end
      end
    end
    
  end


num_objects_label = [];
  function initOsImagePanel(varargin)
    
    % Create Slider for img display
    image_slider_edit = uicontrol('style','slider',...
      'Parent',os_display_panel,...
      'unit','normalized',...
      'Min',1,'Max',nb_frames,'Value',current_frame_nb, ...
      'position',[.01 0.01 0.6 0.05],...
      'SliderStep', [1, 1]/max((nb_frames - 1),1), ...  % Map SliderStep to whole number, Actual step = SliderStep * (Max slider value - Min slider value)
      'callback',{@imgSliderCallback});
    
    % Edit: Cell Numbers to show
    goto_user_frame_edit = uicontrol('style','Edit',...
      'Parent',os_display_panel,...
      'unit','normalized',...
      'position',[.63 0.01 0.1 0.05],...
      'HorizontalAlignment','center',...
      'String',num2str(current_frame_nb),...
      'FontUnits', 'normalized',...
      'fontsize',.5,...
      'fontweight','normal',...
      'backgroundcolor', 'w',...
      'callback',{@gotoFrameCallback});
    
    % # of frames label
    uicontrol('style','text',...
      'Parent',os_display_panel,...
      'unit','normalized',...
      'position',[.74 .005 .09 .05],...
      'HorizontalAlignment','left',...
      'String',['of ' num2str(nb_frames)],...
      'FontUnits', 'normalized',...
      'fontsize',.6,...
      'backgroundcolor', lt_gray,...
      'fontweight','normal');
    
    num_objects_label = label(os_display_panel, [.85 .005 .14 .05], [num2str(nb_obj) ' objects'], 'center', 'k', lt_gray, .6, 'sans serif', 'normal');
    
    function imgSliderCallback(varargin)
      current_frame_nb = ceil(get(image_slider_edit, 'value'));
      set(goto_user_frame_edit, 'String', num2str(current_frame_nb));
      
      destroyMasks();
      img = loadCurrentImage();
      computeFgMask();
      os_update_image();
    end
    
    function gotoFrameCallback(varargin)
      new_frame_nb = str2double(get(goto_user_frame_edit, 'String'));
      if isnan(new_frame_nb)
        errordlg('Invalid frame, please input a valid number.');
        set(goto_user_frame_edit, 'String', num2str(current_frame_nb));
        return;
      end
      
      % constrain the new frame number to the existing frame numbers
      new_frame_nb = min(new_frame_nb, nb_frames);
      new_frame_nb = max(1, new_frame_nb);
      
      current_frame_nb = new_frame_nb;
      set(goto_user_frame_edit, 'string', num2str(current_frame_nb));
      set(image_slider_edit, 'value', current_frame_nb);
      
      destroyMasks();
      img = loadCurrentImage();
      computeFgMask();
      os_update_image();
    end
    
    img = loadCurrentImage();
    os_update_image();
    set(save_pb,'enable','on');
    
    
  end



os_axis = axes('Parent', os_display_panel, 'Units','normalized','Position', [.001 .1 .999 .90]);
axis off; axis image;


  function os_update_image(varargin)
    if ~OS_Options_validate(), return, end
    
    h = msgbox('Working...');
    
    startTime = clock;
    
    set(os_display_panel, 'Title', ['Image: <' raw_image_files(current_frame_nb).name '>']);
    [segmented_image, nb_obj] = fogbank_given_image(current_frame_nb);
    
    print_to_command(['Fogbank segmentation took: ' num2str(etime(clock, startTime))]);
    
    if isempty(img) || isempty(segmented_image)
      return;
    end
    
    delete(get(os_axis, 'Children'));
    imshow(get_Superimpose_Image(), 'Parent', os_axis);
    %         set(os_axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
    
    set(num_objects_label, 'String', [num2str(nb_obj) ' objects']);
    
    if ishandle(h), close(h); end
    
  end


  function os_update_display(varargin)
    
    if isempty(img) || isempty(segmented_image)
      return;
    end
    
    delete(get(os_axis, 'Children'));
    imshow(get_Superimpose_Image(), 'Parent', os_axis);
    
    % show labels
    if os_display_labeled_text
      hold on;
      
      [~, os_text_location] = find_edges_labeled(segmented_image, nb_obj);
      for i = 1:nb_obj
        cell_number = segmented_image(os_text_location(i,2), os_text_location(i,1));
        
        text(os_text_location(i,1), os_text_location(i,2), num2str(cell_number), 'fontsize', 8, ...
          'FontWeight', 'bold', 'Margin', .1, 'color', 'k', 'BackgroundColor', 'w', 'parent', os_axis)
      end
      
      hold off;
    end
    
    %         set(os_axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
  end

  function bool = OS_Options_validate()
    bool = false;
    if ~os_min_peak_size_Callback(); return; end
    if ~os_min_object_size_Callback(); return; end
    bool = true;
  end




%-----------------------------------------------------------------------------------------
% Mask Panels
h_tabpanel(4) = uipanel('Units', 'normalized','Parent', hctfig, 'Visible', 'off', 'Backgroundcolor', lt_gray, 'BorderWidth',0, 'Position', [0,0,1,1]); % border mask
h_tabpanel(5) = uipanel('Units', 'normalized','Parent', hctfig, 'Visible', 'off', 'Backgroundcolor', lt_gray, 'BorderWidth',0, 'Position', [0,0,1,1]); % mitotic mask
h_tabpanel(6) = uipanel('Units', 'normalized','Parent', hctfig, 'Visible', 'off', 'Backgroundcolor', lt_gray, 'BorderWidth',0, 'Position', [0,0,1,1]); % seed mask
h_tabpanel(7) = uipanel('Units', 'normalized','Parent', hctfig, 'Visible', 'off', 'Backgroundcolor', lt_gray, 'BorderWidth',0, 'Position', [0,0,1,1]); % seed load mask

bg_title_panel_position = [0.0, 0.95, 1,.05];
options_panel_position = [.72, .02, .27, .925];
display_panel_position = [.01, .02, .7, .925];


%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
% Border Mask Panel
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
border_threshold_value = 85;
border_threshold_operator_modifier = threshold_operator_modifiers{1};
border_display_contour = false;
border_thin_mask_flag = true;
border_operate_on_gradient_flag = false;
border_colormap = colormap_options{1};
border_break_holes_flag = false;
border_temp_mask = [];

bd_countour_color_selected_opt = contour_color_options{1};

  function os_Border_Mask_Callback(varargin)
    set(h_tabpanel(3), 'Visible', 'off');
    set(h_tabpanel(4), 'Visible', 'on');
    
    update_bd_image();
  end

%-----------------------------------------------------------------------------------------
% Border Mask Content Panel

bd_content_panel = sub_panel(h_tabpanel(4), [0 0 1 1], '', 'lefttop', green_blue, lt_gray, 0.05, 'serif');
set(bd_content_panel, 'borderwidth', 0);

title_panel = sub_panel(bd_content_panel, bg_title_panel_position, '', 'lefttop', green_blue, dark_gray, 0.05, 'serif');
label(title_panel, [0 0 1 1], 'Border Mask Generation', 'center', 'k', dark_gray, .8, 'sans serif', 'normal');
set(title_panel, 'borderwidth', 0);


bd_options_panel = sub_panel(bd_content_panel, options_panel_position, 'Options', 'lefttop', green_blue, lt_gray, 0.05, 'serif');
bd_display_panel = sub_panel(bd_content_panel, display_panel_position, ['Image: <' '>'], 'lefttop', green_blue, lt_gray, 0.05, 'serif');



push_button(bd_options_panel, [.88 .96 .1 component_height], '?', 'center', 'k', 'default', .6, 'sans serif', 'bold', 'on', {@bd_help_callback});

  function bd_help_callback(varargin)
    pathstr = which('wiki.html');
    web([pathstr '#use-border-mask']);
  end



% Percentile Threshold Label
y = .9;
label(bd_options_panel, [.05 y .95 component_height], 'Percentile Threshold', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');

% Percentile Threshold Modifier dropdown {'>', '<='}
label(bd_options_panel, [.05 y-.04 .53 component_height], 'Foreground = Pixels', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
Percentile_threshold_operator_modifier_dropdown = popupmenu(bd_options_panel, [.59 y-.035 .15 component_height], threshold_operator_modifiers, 'k', 'w', .6, 'normal', @Percentile_threshold_operator_modifier_Callback);
  function Percentile_threshold_operator_modifier_Callback(varargin)
    temp = get(Percentile_threshold_operator_modifier_dropdown, 'value');
    border_threshold_operator_modifier = threshold_operator_modifiers{temp};
  end

% Percentile Threshold Edit Box
Border_Options_threshold_value_edit = editbox_check(bd_options_panel, [.75 y-.035 .2 component_height], num2str(border_threshold_value), 'right', 'k', 'w', .6, 'normal', @Border_Options_threshold_value_Callback);
  function Border_Options_threshold_value_Callback(varargin)
    temp = str2double(get(Border_Options_threshold_value_edit, 'String'));
    temp = max(0,temp);
    temp = min(temp, 100);
    border_threshold_value = temp;
    set(Border_Options_threshold_value_edit, 'String', num2str(border_threshold_value));
  end

% Thin mask check box
Border_Options_thin_mask_checkbox = checkbox(bd_options_panel, [.05 .75 .95 component_height], 'Thin Mask', 'left', 'k', lt_gray, .55, 'sans serif', 'normal', {@Border_Options_thin_mask_Callback});
set(Border_Options_thin_mask_checkbox ,'value', border_thin_mask_flag);
  function Border_Options_thin_mask_Callback(varargin)
    border_thin_mask_flag = get(Border_Options_thin_mask_checkbox, 'value');
  end

Border_Options_gradient_checkbox = checkbox(bd_options_panel, [.05 .69 .95 component_height], 'Operate on Gradient', 'left', 'k', lt_gray, .55, 'sans serif', 'normal', {@Border_Options_gradient_Callback});
set(Border_Options_gradient_checkbox ,'value', border_operate_on_gradient_flag);
  function Border_Options_gradient_Callback(varargin)
    border_operate_on_gradient_flag = get(Border_Options_gradient_checkbox, 'value');
  end


Border_Options_break_holes_checkbox = checkbox(bd_options_panel, [.05 .63 .95 component_height], 'Break Holes', 'left', 'k', lt_gray, .55, 'sans serif', 'normal', {@Border_Options_break_holes_Callback});
set(Border_Options_break_holes_checkbox ,'value', border_break_holes_flag);
  function Border_Options_break_holes_Callback(varargin)
    border_break_holes_flag = get(Border_Options_break_holes_checkbox, 'value');
  end



push_button(bd_options_panel, [.1 .45 .78 1.2*component_height], 'Update Border Mask', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'on', {@update_bd_image});




label(bd_options_panel, [.05 .33 .95 component_height], 'ColorMap:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
bd_Options_colormap_dropdown = popupmenu(bd_options_panel, [.05 .29 .91 component_height], colormap_options, 'k', 'w', .6, 'normal', @Border_Display_colormap_Callback);

  function Border_Display_colormap_Callback(varargin)
    temp = get(bd_Options_colormap_dropdown, 'value');
    border_colormap = colormap_options{temp};
    update_bd_display();
  end


% Display Contour checkbox
Border_Options_display_contour_checkbox = checkbox(bd_options_panel, [.05 .20 .61 component_height], 'Display Contour', 'left', 'k', lt_gray, .55, 'sans serif', 'normal', {@Border_Options_display_contour_Callback});
set(Border_Options_display_contour_checkbox ,'value', border_display_contour);
  function Border_Options_display_contour_Callback(varargin)
    border_display_contour = get(Border_Options_display_contour_checkbox, 'value');
    update_bd_display();
  end

bd_contour_color_dropdown = popupmenu(bd_options_panel, [.659 .20 .3 component_height], contour_color_options, 'k', 'w', .6, 'normal', @contour_color_callback2);
  function contour_color_callback2(varargin)
    temp1 = get(bd_contour_color_dropdown, 'value');
    bd_countour_color_selected_opt = contour_color_options{temp1};
    update_bd_display();
  end

bd_adjust_contrast = 0;
Border_adjust_contrast_checkbox = checkbox(bd_options_panel, [.05 .13 .61 component_height], 'Adjust Contrast', 'left', 'k', lt_gray, .55, 'sans serif', 'normal', {@Border_adjust_contrast_Callback});
  function Border_adjust_contrast_Callback(varargin)
    bd_adjust_contrast = get(Border_adjust_contrast_checkbox, 'value');
    update_bd_display();
  end

push_button(bd_options_panel, [.01 .01 .49 component_height], 'Apply', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'on', {@bd_apply_mask});
  function bd_apply_mask(varargin)
    border_mask = [];
    border_mask = border_temp_mask;
    border_temp_mask = [];
    
    set(h_tabpanel(3), 'Visible', 'on');
    set(h_tabpanel(4), 'Visible', 'off');
    
    % Update Object Separation Image
    os_update_image();
    
  end

push_button(bd_options_panel, [.5 .01 .49 component_height], 'Cancel', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'on', {@bd_cancel_mask});
  function bd_cancel_mask(varargin)
    border_temp_mask = [];
    set(h_tabpanel(3), 'Visible', 'on');
    set(h_tabpanel(4), 'Visible', 'off');
  end

% Setup the Display Image Axis
bd_display_Axis = axes('Parent', bd_display_panel, 'Units','normalized','Position', [.01, .01, .98, .98]);
axis off; axis image;



  function update_bd_image(varargin)
    h = msgbox('Working...');
    
    set(bd_display_panel, 'Title', ['Image: <' raw_image_files(current_frame_nb).name '>']);
    border_temp_mask = get_Border_Mask_Image();
    
    delete(get(bd_display_Axis, 'Children'));
    disp_I = superimpose_colormap_contour(img, border_temp_mask, colormap([border_colormap '(65000)']), bd_countour_color_selected_opt,1, border_display_contour, bd_adjust_contrast);
    imshow(disp_I, 'Parent', bd_display_Axis);
    %         set(bd_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
    
    if ishandle(h), close(h); end
    
  end


  function update_bd_display()
    delete(get(bd_display_Axis, 'Children'));
    disp_I = superimpose_colormap_contour(img, border_temp_mask, colormap([border_colormap '(65000)']), bd_countour_color_selected_opt,1, border_display_contour, bd_adjust_contrast);
    imshow(disp_I, 'Parent', bd_display_Axis);
    %         set(bd_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
  end




%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
% Mitotic Mask Panel
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
mitotic_grayscale_modifier = grayscale_modifiers{1};
mitotic_threshold_modifier = threshold_modifiers{2};
mitotic_threshold_value = 97;
mitotic_filter_radius = 1;
mitotic_min_object_size = 250;
mitotic_display_contour = false;
mitotic_threshold_operator = threshold_operator_modifiers{1};
mitotic_morph_operation = morphological_operations{1};
mitotic_strel_disk_radius = 8;
mitotic_min_peak_size = 120;
mitotic_fogbank_direction = fog_bank_directions{1};
mitotic_adjust_contrast = 0;
mitotic_circularity_threshold = 0.3;

mit_temp_mask = [];
mit_text_location = 0;

mit_display_labeled_text = false;
mit_selected_colormap_opt = colormap_options{1};
mit_countour_color_selected_opt = contour_color_options{1};

  function os_Mitotic_Mask_Callback(varargin)
    set(h_tabpanel(3), 'Visible', 'off');
    set(h_tabpanel(5), 'Visible', 'on');
    
    update_mitotic_image();
  end


%-----------------------------------------------------------------------------------------
% Mitotic Mask Content Panel
mit_content_panel = sub_panel(h_tabpanel(5), [0 0 1 1], '', 'lefttop', green_blue, lt_gray, 0.05, 'serif');
set(mit_content_panel, 'borderwidth', 0);

title_panel = sub_panel(mit_content_panel, bg_title_panel_position, '', 'lefttop', green_blue, dark_gray, 0.05, 'serif');
label(title_panel, [0 0 1 1], 'Mitotic Mask Generation', 'center', 'k', dark_gray, .8, 'sans serif', 'normal');
set(title_panel, 'borderwidth', 0);

mit_options_panel = sub_panel(mit_content_panel, options_panel_position, 'Options', 'lefttop', green_blue, lt_gray, 0.05, 'serif');
mit_display_panel = sub_panel(mit_content_panel, display_panel_position, ['Image: <' '>'], 'lefttop', green_blue, lt_gray, 0.05, 'serif');


push_button(mit_options_panel, [.88 .96 .1 component_height], '?', 'center', 'k', 'default', .6, 'sans serif', 'bold', 'on', {@mit_help_callback});

  function mit_help_callback(varargin)
    pathstr = which('wiki.html');
    web([pathstr '#use-mitotic-mask']);
  end



% display the label of the dropdown threshold method menu
y = .92;
label(mit_options_panel, [.01 y .25 component_height], 'Image (', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_grayscale_modifier_dropdown = popupmenu(mit_options_panel, [.27 y+.005 .4 component_height], grayscale_modifiers, 'k', 'w', .6, 'normal', @mitotic_Options_grayscale_modifier_Callback);
label(mit_options_panel, [.68 y .05 component_height], ')', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');

  function mitotic_Options_grayscale_modifier_Callback(varargin)
    temp = get(mitotic_Options_grayscale_modifier_dropdown, 'value');
    mitotic_grayscale_modifier = grayscale_modifiers{temp};
    if strcmpi(mitotic_grayscale_modifier, 'Std') || strcmpi(mitotic_grayscale_modifier, 'Entropy')
      set(mitotic_filter_radius_label, 'enable', 'on');
      set(mitotic_Options_filter_radius_edit, 'enable', 'on');
    else
      %                 set(mitotic_filter_radius_label, 'visible', 'off');
      %set(mitotic_Options_filter_radius_edit, 'visible', 'off');
      set(mitotic_filter_radius_label, 'enable', 'off');
      set(mitotic_Options_filter_radius_edit, 'enable', 'off');
    end
  end

% Get the filter radius
mitotic_filter_radius_label = label(mit_options_panel, [.01 y-.06 .48 component_height], 'filter radius:', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_filter_radius_edit = editbox_check(mit_options_panel, [.5 y-.055 .42 component_height], num2str(mitotic_filter_radius), 'right', 'k', 'w', .6, 'normal', @mitotic_Options_filter_radius_Callback);

set(mitotic_filter_radius_label, 'enable', 'off');
set(mitotic_Options_filter_radius_edit, 'enable', 'off');

  function bool = mitotic_Options_filter_radius_Callback(varargin)
    bool = false;
    temp = round(str2double(get(mitotic_Options_filter_radius_edit, 'string')));
    if temp <= 0
      errordlg('Invalid filter radius');
      return;
    end
    mitotic_filter_radius = temp;
    bool = true;
  end



label(mit_options_panel, [.05 y-.12 .43 component_height], 'whose', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_threshold_modifier_dropdown = popupmenu(mit_options_panel, [.5 y-.115 .42 component_height], threshold_modifiers, 'k', 'w', .6, 'normal', @mitotic_Options_threshold_modifier_Callback);
set(mitotic_Options_threshold_modifier_dropdown, 'value', 2);

  function mitotic_Options_threshold_modifier_Callback(varargin)
    temp = get(mitotic_Options_threshold_modifier_dropdown,'value');
    mitotic_threshold_modifier = threshold_modifiers{temp};
  end


label(mit_options_panel, [.05 y-.18 .43 component_height], 'values', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_threshold_operator_dropdown = popupmenu(mit_options_panel, [.5 y-.175 .2 component_height], threshold_operator_modifiers, 'k', 'w', .6, 'normal', @mitotic_Options_threshold_operator_Callback);

  function mitotic_Options_threshold_operator_Callback(varargin)
    temp = get(mitotic_Options_threshold_operator_dropdown, 'value');
    mitotic_threshold_operator = threshold_operator_modifiers{temp};
  end


mitotic_Options_threshold_value_edit = editbox_check(mit_options_panel, [.72 y-.175 .2 component_height], num2str(mitotic_threshold_value), 'right', 'k', 'w', .6, 'normal', @mitotic_Options_threshold_value_Callback);
  function mitotic_Options_threshold_value_Callback(varargin)
    temp = str2double(get(mitotic_Options_threshold_value_edit, 'String'));
    temp = max(0,temp);
    if strfind(lower(regexprep(mitotic_threshold_modifier, '\W', '')), 'percentile');
      temp = min(temp, 100);
    end
    mitotic_threshold_value = temp;
    set(mitotic_Options_threshold_value_edit, 'String', num2str(mitotic_threshold_value));
  end


y = .66;
label(mit_options_panel, [.05 y .95 component_height], 'Morphological Operation:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_morph_dropdown = popupmenu(mit_options_panel, [.05 y-.035 .38 component_height], morphological_operations, 'k', 'w', .6, 'normal', @mitotic_Options_morph_Callback);
label(mit_options_panel, [.43 y-.04 .34 component_height], 'with radius:', 'center', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_strel_radius_edit = editbox_check(mit_options_panel, [.77 y-.035 .18 component_height], num2str(mitotic_strel_disk_radius), 'right', 'k', 'w', .6, 'normal', @mitotic_Options_strel_radius_Callback);

  function mitotic_Options_morph_Callback(varargin)
    temp = get(mitotic_Options_morph_dropdown, 'value');
    mitotic_morph_operation = morphological_operations{temp};
  end

  function bool = mitotic_Options_strel_radius_Callback(varargin)
    bool = false;
    temp = round(str2double(get(mitotic_Options_strel_radius_edit, 'string')));
    if temp <= 0
      errordlg('Invalid strel radius');
      return;
    end
    mitotic_strel_disk_radius = temp;
    bool = true;
  end


y = .53;
label(mit_options_panel, [.01 y .56 component_height], 'Fogbank Direction: ', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_fogbank_direction_dropdown = popupmenu(mit_options_panel, [.57 y+.005 .41 component_height], fog_bank_directions, 'k', 'w', .6, 'normal', @mitotic_Options_fogbank_direction_Callback);

  function mitotic_Options_fogbank_direction_Callback(varargin)
    temp = get(mitotic_Options_fogbank_direction_dropdown, 'value');
    mitotic_fogbank_direction = fog_bank_directions{temp};
  end


% get the min object size for the foreground
y = .47;
label(mit_options_panel, [.01 y .65 component_height], 'Min Object Area:', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_min_object_size_edit = editbox_check(mit_options_panel, [.68 y+.005 .2 component_height], num2str(mitotic_min_object_size), 'right', 'k', 'w', .6, 'normal', @mitotic_Options_min_object_size_Callback);
label(mit_options_panel, [.9 y .1 component_height], 'px', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');

  function bool = mitotic_Options_min_object_size_Callback(varargin)
    bool = false;
    temp = str2double(get(mitotic_Options_min_object_size_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Min Object Size');
      return;
    end
    mitotic_min_object_size = temp;
    bool = true;
  end


y = .41;
label(mit_options_panel, [.01 y .65 component_height], 'Min Seed Area:', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_min_peak_size_edit = editbox_check(mit_options_panel, [.68 y+.005 .2 component_height], num2str(mitotic_min_peak_size), 'right', 'k', 'w', .6, 'normal', @mitotic_Options_min_peak_size_Callback);
label(mit_options_panel, [.9 y .1 component_height], 'px', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');

  function bool = mitotic_Options_min_peak_size_Callback(varargin)
    bool = false;
    temp = str2double(get(mitotic_Options_min_peak_size_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Min Seed Size');
      return;
    end
    mitotic_min_peak_size = temp;
    bool = true;
  end


y = .35;
label(mit_options_panel, [.01 y .65 component_height], 'Circularity Threshold:', 'right', 'k', lt_gray, .6, 'sans serif', 'normal');
mitotic_Options_circ_thres_edit = editbox_check(mit_options_panel, [.68 y+.005 .2 component_height], num2str(mitotic_circularity_threshold), 'right', 'k', 'w', .6, 'normal', @mitotic_Options_circ_thres_Callback);

  function bool = mitotic_Options_circ_thres_Callback(varargin)
    bool = false;
    temp = str2double(get(mitotic_Options_circ_thres_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Circularity Threshold');
      return;
    end
    mitotic_circularity_threshold = temp;
    bool = true;
  end


push_button(mit_options_panel, [.1 .28 .78 1.2*component_height], 'Update Mitotic Mask', 'center', 'k', dark_gray, .5, 'sans serif', 'bold', 'on', {@update_mitotic_image});




label(mit_options_panel, [.05 .21 .95 component_height], 'ColorMap:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
mit_Options_colormap_dropdown = popupmenu(mit_options_panel, [.05 .17 .91 component_height], colormap_options, 'k', 'w', .6, 'normal', @mit_colormap_Callback);
  function mit_colormap_Callback(varargin)
    temp = get(mit_Options_colormap_dropdown, 'value');
    mit_selected_colormap_opt = colormap_options{temp};
    mit_update_display();
  end


mit_Display_labeled_text_checkbox = checkbox(mit_options_panel, [.53 .22 .45 component_height], 'Show Labels', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@mit_Display_labeled_text_checkbox_Callback});
  function mit_Display_labeled_text_checkbox_Callback(varargin)
    mit_display_labeled_text = logical(get(mit_Display_labeled_text_checkbox, 'value'));
    mit_update_display();
  end


mit_contour_checkbox = checkbox(mit_options_panel, [.05 .11 .91 component_height], 'Display Contour', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@mit_contour_Callback});
set(mit_contour_checkbox, 'value',mitotic_display_contour);
  function mit_contour_Callback(varargin)
    mitotic_display_contour = get(mit_contour_checkbox,'value');
    mit_update_display();
  end


mit_adjust_contrast_checkbox = checkbox(mit_options_panel, [.05 .06 .91 component_height], 'Adjust Contrast', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@mit_adjust_contrast_Callback});
  function mit_adjust_contrast_Callback(varargin)
    mitotic_adjust_contrast = get(mit_adjust_contrast_checkbox,'value');
    mit_update_display();
  end

% Mitotic Apply Push Button
push_button(mit_options_panel, [.01 .01 .49 component_height], 'Apply', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'on', {@mit_apply_mask});
  function mit_apply_mask(varargin)
    mitotic_mask = [];
    mitotic_mask = mit_temp_mask;
    mit_temp_mask = [];
    
    set(h_tabpanel(3), 'Visible', 'on');
    set(h_tabpanel(5), 'Visible', 'off');
    
    % Update Object Separation Image
    os_update_image();
    
  end

% Mitotic Cancel Push Button
push_button(mit_options_panel, [.5 .01 .49 component_height], 'Cancel', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'on', {@mit_cancel_mask});
  function mit_cancel_mask(varargin)
    mit_temp_mask = [];
    set(h_tabpanel(3), 'Visible', 'on');
    set(h_tabpanel(5), 'Visible', 'off');
  end





% ---------------------------------------------------------------------------------------
% setup the display panel for the foreground tab

  function bool = mitotic_Options_validate(varargin)
    bool = false;
    mitotic_Options_grayscale_modifier_Callback();
    mitotic_Options_threshold_modifier_Callback();
    mitotic_Options_threshold_value_Callback();
    mitotic_Options_morph_Callback();
    mitotic_Options_strel_radius_Callback();
    mitotic_Options_threshold_operator_Callback();
    mitotic_Options_fogbank_direction_Callback();
    if ~mitotic_Options_circ_thres_Callback(), return, end
    if ~mitotic_Options_min_peak_size_Callback(), return, end
    if ~mitotic_Options_filter_radius_Callback(), return, end
    if ~mitotic_Options_min_object_size_Callback(), return, end
    bool = true;
  end



mit_display_Axis = axes('Parent', mit_display_panel, 'Units','normalized','Position', [.01 .01 .98 .98]);
axis off; axis image;


  function update_mitotic_image(varargin)
    if ~mitotic_Options_validate(), return, end
    
    h = msgbox('Working...');
    
    set(mit_display_panel, 'Title', ['Image: <' raw_image_files(current_frame_nb).name '>']);
    mit_temp_mask = get_Mitotic_Mask_Image();
    
    delete(get(mit_display_Axis, 'Children'));
    disp_I = superimpose_colormap_contour(img, mit_temp_mask, colormap([mit_selected_colormap_opt, '(65000)']), mit_countour_color_selected_opt,1, mitotic_display_contour, mitotic_adjust_contrast);
    imshow(disp_I, 'Parent', mit_display_Axis);
    %         set(mit_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
    
    if ishandle(h), close(h); end
  end


  function mit_update_display(varargin)
    
    if isempty(img) || isempty(mit_temp_mask)
      return;
    end
    
    
    delete(get(mit_display_Axis, 'Children'));
    disp_I = superimpose_colormap_contour(img, mit_temp_mask, colormap([mit_selected_colormap_opt '(65000)']), mit_countour_color_selected_opt,1, mitotic_display_contour, mitotic_adjust_contrast);
    imshow(disp_I, 'Parent', mit_display_Axis);
    %         set(mit_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
    
    
    % show labels
    if mit_display_labeled_text
      hold on;
      
      nb_mit_obj = max(mit_temp_mask(:));
      [~, mit_text_location] = find_edges_labeled(mit_temp_mask, nb_mit_obj);
      for i = 1:nb_mit_obj
        cell_number = mit_temp_mask(mit_text_location(i,2), mit_text_location(i,1));
        
        text(mit_text_location(i,1), mit_text_location(i,2), num2str(cell_number), 'fontsize', 8, ...
          'FontWeight', 'bold', 'Margin', .1, 'color', 'k', 'BackgroundColor', 'w', 'parent', mit_display_Axis)
      end
      
      hold off;
    end
    
    %         set(mit_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
  end


%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
% Seed Mask Panel
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
seed_clustering_distance_metrics = {'Geodesic Distance','Euclidean Distance'};
seed_min_object_size = 15;
seed_max_object_size = 120;
seed_display_contour = false;
seed_threshold_operatorL = seed_threshold_operator_modifiers{1};
seed_threshold_operatorR = seed_threshold_operator_modifiers{1};
seed_threshold_valueL = 3;
seed_threshold_valueR = 10;

seed_use_border = true;
seed_cluster_dist = 25;
seed_circularity_threshold = 0;
seed_strel_disk_radius = 2;
seed_morph_operation = morphological_operations{1};
seed_operate_on_gradient_flag = false;
seed_adjust_contrast = 0;

seed_display_labeled_text = false;
seed_selected_colormap_opt = colormap_options{1};
seed_temp_mask = [];

seed_countour_color_selected_opt = contour_color_options{1};

  function os_Seed_Mask_Callback(varargin)
    set(h_tabpanel(3), 'Visible', 'off');
    set(h_tabpanel(6), 'Visible', 'on');
    
    Seed_Display_update_image();
    
  end

%-----------------------------------------------------------------------------------------
% Seed Mask Content Panel
seed_content_panel = sub_panel(h_tabpanel(6), [0 0 1 1], '', 'lefttop', green_blue, lt_gray, 0.05, 'serif');
set(seed_content_panel, 'borderwidth', 0);

title_panel = sub_panel(seed_content_panel, bg_title_panel_position, '', 'lefttop', green_blue, dark_gray, 0.05, 'serif');
label(title_panel, [0 0 1 1], 'Seed Mask Generation', 'center', 'k', dark_gray, .8, 'sans serif', 'normal');
set(title_panel, 'borderwidth', 0);

seed_options_panel = sub_panel(seed_content_panel, options_panel_position, 'Options', 'lefttop', green_blue, lt_gray, 0.05, 'serif');
seed_display_panel = sub_panel(seed_content_panel, display_panel_position, ['Image: <' '>'], 'lefttop', green_blue, lt_gray, 0.05, 'serif');



push_button(seed_options_panel, [.88 .96 .1 component_height], '?', 'center', 'k', 'default', .6, 'sans serif', 'bold', 'on', {@seed_help_callback});

  function seed_help_callback(varargin)
    pathstr = which('wiki.html');
    web([pathstr '#use-seed-mask']);
  end



Seed_Options_gradient_checkbox = checkbox(seed_options_panel, [.05 .95 .75 component_height], 'Operate on Gradient', 'left', 'k', lt_gray, .55, 'sans serif', 'normal', {@Seed_Options_gradient_Callback});
set(Seed_Options_gradient_checkbox ,'value', seed_operate_on_gradient_flag);
  function Seed_Options_gradient_Callback(varargin)
    seed_operate_on_gradient_flag = get(Seed_Options_gradient_checkbox, 'value');
  end


% Percentile Threshold Label
y = .88;
label(seed_options_panel, [.05 y .95 component_height], 'Percentile Threshold', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
seed_threshold_valueL_edit = editbox_check(seed_options_panel, [.05 y-.04 .2 component_height], num2str(seed_threshold_valueL), 'right', 'k', 'w', .6, 'normal', @Threshold_value_Callback);
seed_Percentile_threshold_operator_modifier_dropdownL = popupmenu(seed_options_panel, [.25 y-.04 .15 component_height], seed_threshold_operator_modifiers, 'k', 'w', .6, 'normal', @seed_Percentile_threshold_operator_modifier_Callback);
set(seed_Percentile_threshold_operator_modifier_dropdownL, 'value',1);
label(seed_options_panel, [.4 y-.04 .2 component_height], 'pixel', 'center', 'k', lt_gray, .6, 'sans serif', 'normal');
seed_Percentile_threshold_operator_modifier_dropdownR = popupmenu(seed_options_panel, [.6 y-.04 .15 component_height], seed_threshold_operator_modifiers, 'k', 'w', .6, 'normal', @seed_Percentile_threshold_operator_modifier_Callback);
set(seed_Percentile_threshold_operator_modifier_dropdownR, 'value',1);
seed_threshold_valueR_edit = editbox_check(seed_options_panel, [.75 y-.04 .2 component_height], num2str(seed_threshold_valueR), 'right', 'k', 'w', .6, 'normal', @Threshold_value_Callback);


  function seed_Percentile_threshold_operator_modifier_Callback(varargin)
    temp = get(seed_Percentile_threshold_operator_modifier_dropdownL, 'value');
    seed_threshold_operatorL = seed_threshold_operator_modifiers{temp};
    
    temp = get(seed_Percentile_threshold_operator_modifier_dropdownR, 'value');
    seed_threshold_operatorR = seed_threshold_operator_modifiers{temp};
  end
seed_Percentile_threshold_operator_modifier_Callback();

  function bool = Threshold_value_Callback(varargin)
    bool = false;
    temp = str2double(get(seed_threshold_valueL_edit, 'String'));
    if isnan(temp)
      errordlg('Invalid Threshold');
      return;
    end
    temp = max(0,temp);
    temp = min(temp, 100);
    seed_threshold_valueL = temp;
    set(seed_threshold_valueL_edit, 'String', num2str(seed_threshold_valueL));
    
    temp = str2double(get(seed_threshold_valueR_edit, 'String'));
    if isnan(temp)
      errordlg('Invalid Threshold');
      return;
    end
    temp = max(0,temp);
    temp = min(temp, 100);
    seed_threshold_valueR = temp;
    set(seed_threshold_valueR_edit, 'String', num2str(seed_threshold_valueR));
    
    bool = true;
  end

y = .77;
label(seed_options_panel, [.05 y .8 component_height], 'Object Size Range (px):', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
Seed_Options_min_object_size_edit = editbox_check(seed_options_panel, [.05 y-.04 .4 component_height], num2str(seed_min_object_size), 'right', 'k', 'w', .6, 'normal', @Min_object_size_Callback);
label(seed_options_panel, [.48 y-.04 .06 component_height], 'to', 'center', 'k', lt_gray, .6, 'sans serif', 'normal');
Seed_Options_max_object_size_edit = editbox_check(seed_options_panel, [.56 y-.04 .4 component_height], num2str(seed_max_object_size), 'right', 'k', 'w', .6, 'normal', @Max_object_size_Callback);

  function bool = Min_object_size_Callback(varargin)
    bool = false;
    temp = str2double(get(Seed_Options_min_object_size_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Min Object Size');
      return;
    end
    seed_min_object_size = temp;
    bool = true;
  end
  function bool = Max_object_size_Callback(varargin)
    bool = false;
    temp = str2double(get(Seed_Options_max_object_size_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Max Object Size');
      return;
    end
    seed_max_object_size = temp;
    bool = true;
  end

y = .63;
label(seed_options_panel, [.05 y .95 component_height], 'Morphological Operation:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
seed_Options_morph_dropdown = popupmenu(seed_options_panel, [.05 y-.035 .38 component_height], morphological_operations, 'k', 'w', .6, 'normal', @seed_Options_morph_Callback);
label(seed_options_panel, [.43 y-.04 .34 component_height], 'with radius:', 'center', 'k', lt_gray, .6, 'sans serif', 'normal');
seed_Options_strel_radius_edit = editbox_check(seed_options_panel, [.77 y-.035 .18 component_height], num2str(seed_strel_disk_radius), 'right', 'k', 'w', .6, 'normal', @seed_Options_strel_radius_Callback);

%         set(seed_Options_morph_dropdown, 'value',seed_strel_disk_radius);
  function seed_Options_morph_Callback(varargin)
    temp = get(seed_Options_morph_dropdown, 'value');
    seed_morph_operation = morphological_operations{temp};
  end

  function bool = seed_Options_strel_radius_Callback(varargin)
    bool = false;
    temp = round(str2double(get(seed_Options_strel_radius_edit, 'string')));
    if temp <= 0
      errordlg('Invalid strel radius');
      return;
    end
    seed_strel_disk_radius = temp;
    bool = true;
  end



y = .5;
label(seed_options_panel, [.05 y .68 component_height], 'Circularity Threshold:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
Seed_Options_circularity_edit = editbox_check(seed_options_panel, [.75 y+.005 .215 component_height], num2str(seed_circularity_threshold), 'right', 'k', 'w', .6, 'normal', @Circularity_Callback);
  function bool = Circularity_Callback(varargin)
    bool = false;
    temp = str2double(get(Seed_Options_circularity_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Circularity Threshold');
      return;
    end
    seed_circularity_threshold = temp;
    bool = true;
  end


y = .42;
label(seed_options_panel, [.05 y .6 component_height], 'Cluster Seeds Using:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
seed_Options_cluster_dropdown = popupmenu(seed_options_panel, [.05 y-.035 .62 component_height], seed_clustering_distance_metrics, 'k', 'w', .6, 'normal', @seed_Options_cluster_Callback);
  function seed_Options_cluster_Callback(varargin)
    temp = get(seed_Options_cluster_dropdown,'value');
    if temp == 1
      seed_use_border = true;
    else
      seed_use_border = false;
    end
  end

label(seed_options_panel, [.67 y-.04 .08 component_height], '<', 'center', 'k', lt_gray, .6, 'sans serif', 'normal');
Seed_Options_cluster_dist_edit = editbox_check(seed_options_panel, [.75 y-.035 .215 component_height], num2str(seed_cluster_dist), 'right', 'k', 'w', .6, 'normal', @Cluster_disk_Callback);
  function bool = Cluster_disk_Callback(varargin)
    bool = false;
    temp = str2double(get(Seed_Options_cluster_dist_edit, 'String'));
    if isnan(temp) || temp < 0
      errordlg('Invalid Cluster Distance');
      return;
    end
    seed_cluster_dist = temp;
    bool = true;
  end


  function bool = Seed_Options_validate(varargin)
    bool = false;
    seed_Options_cluster_Callback();
    if ~Cluster_disk_Callback(), return, end;
    if ~Circularity_Callback(), return, end;
    if ~Min_object_size_Callback(), return, end;
    if ~Max_object_size_Callback(), return, end;
    if ~Threshold_value_Callback(), return, end;
    bool = true;
  end








% Update Button
push_button(seed_options_panel, [.1 .28 .78 1.2*component_height], 'Update Seed Mask', 'center', 'k', dark_gray, .5, 'sans serif', 'bold', 'on', {@Seed_Display_update_image});



label(seed_options_panel, [.05 .2 .95 component_height], 'ColorMap:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
seed_Options_colormap_dropdown = popupmenu(seed_options_panel, [.05 .16 .91 component_height], colormap_options, 'k', 'w', .6, 'normal', @seed_colormap_Callback);
  function seed_colormap_Callback(varargin)
    temp = get(seed_Options_colormap_dropdown, 'value');
    seed_selected_colormap_opt = colormap_options{temp};
    seed_update_display();
  end


seed_Display_labeled_text_checkbox = checkbox(seed_options_panel, [.53 .21 .45 component_height], 'Show Labels', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@seed_Display_labeled_text_checkbox_Callback});
  function seed_Display_labeled_text_checkbox_Callback(varargin)
    seed_display_labeled_text = logical(get(seed_Display_labeled_text_checkbox, 'value'));
    seed_update_display();
  end


seed_contour_checkbox = checkbox(seed_options_panel, [.05 .11 .91 component_height], 'Display Contour', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@seed_contour_Callback});
set(seed_contour_checkbox, 'value',mitotic_display_contour);
  function seed_contour_Callback(varargin)
    seed_display_contour = get(seed_contour_checkbox,'value');
    seed_update_display();
  end


seed_adjust_contrast_checkbox = checkbox(seed_options_panel, [.05 .06 .91 component_height], 'Adjust Contrast', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@seed_adjust_contrast_Callback});
  function seed_adjust_contrast_Callback(varargin)
    seed_adjust_contrast = get(seed_adjust_contrast_checkbox,'value');
    seed_update_display();
  end


% Seed Apply Push Button
push_button(seed_options_panel, [.01 .01 .49 component_height], 'Apply', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'on', {@seed_apply_mask});
  function seed_apply_mask(varargin)
    seed_mask = [];
    seed_mask = seed_temp_mask;
    seed_temp_mask = [];
    use_load_seed_mask = false;
    
    set(h_tabpanel(3), 'Visible', 'on');
    set(h_tabpanel(6), 'Visible', 'off');
    
    % Update Object Separation Image
    os_update_image();
    
  end

% Seed Cancel Push Button
push_button(seed_options_panel, [.5 .01 .49 component_height], 'Cancel', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'on', {@seed_cancel_mask});
  function seed_cancel_mask(varargin)
    seed_temp_mask = [];
    set(h_tabpanel(3), 'Visible', 'on');
    set(h_tabpanel(6), 'Visible', 'off');
  end


% Setup the Display Image Axis
seed_display_Axis = axes('Parent', seed_display_panel, 'Units','normalized','Position', [.01 .01 .98 .98]);
axis off; axis image;


  function Seed_Display_update_image(varargin)
    if ~Seed_Options_validate(), return, end
    
    h = msgbox('Working...');
    set(seed_display_panel, 'Title', ['Image: <' raw_image_files(current_frame_nb).name '>']);
    
    % get a current copy of the seed mask img
    seed_temp_mask = get_Seed_Mask_Image(false);
    
    img1 = img;
    if seed_use_border && exist('border_mask', 'var') && ~isempty(border_mask)
      if get(Percentile_threshold_operator_modifier_dropdown, 'value') == 1
        img1(border_mask) = min(img1(:));
      else
        img1(border_mask) = max(img1(:));
      end
    end
    
    % display the img
    delete(get(seed_display_Axis, 'Children'));
    disp_I = superimpose_colormap_contour(img1, seed_temp_mask, colormap([seed_selected_colormap_opt '(65000)']), seed_countour_color_selected_opt,1, seed_display_contour, seed_adjust_contrast);
    imshow(disp_I, 'Parent', seed_display_Axis);
    %         set(seed_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
    if ishandle(h), close(h); end
    
  end

%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
% Seed Mask Load Panel
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------

use_load_seed_mask = false;
seed_temp_mask = [];

  function os_Seed_Load_Mask_Callback(varargin)
    set(h_tabpanel(3), 'Visible', 'off');
    set(h_tabpanel(7), 'Visible', 'on');
  end

%-----------------------------------------------------------------------------------------
% Seed Mask Content Panel
seed_load_content_panel = sub_panel(h_tabpanel(7), [0 0 1 1], '', 'lefttop', green_blue, lt_gray, 0.05, 'serif');
set(seed_load_content_panel, 'borderwidth', 0);

title_panel = sub_panel(seed_load_content_panel, bg_title_panel_position, '', 'lefttop', green_blue, dark_gray, 0.05, 'serif');
label(title_panel, [0 0 1 1], 'Import Seed Mask', 'center', 'k', dark_gray, .8, 'sans serif', 'normal');
set(title_panel, 'borderwidth', 0);

seed_load_options_panel = sub_panel(seed_load_content_panel, options_panel_position, 'Options', 'lefttop', green_blue, lt_gray, 0.05, 'serif');
seed_load_display_panel = sub_panel(seed_load_content_panel, display_panel_position, ['Image: <' '>'], 'lefttop', green_blue, lt_gray, 0.05, 'serif');



push_button(seed_load_options_panel, [.88 .96 .1 component_height], '?', 'center', 'k', 'default', .6, 'sans serif', 'bold', 'on', {@seed_load_help_callback});
  function seed_load_help_callback(varargin)
    pathstr = which('wiki.html');
    web([pathstr '#use-seed-mask']);
  end



label(seed_load_options_panel, [.01 .9 .99 component_height], 'Seed Mask Image(s) Path:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
seed_input_dir_editbox = editbox(seed_load_options_panel, [.01 .84 .98 component_height], load_seed_mask_path, 'left', 'k', 'w', .6, 'normal');
push_button(seed_load_options_panel, [.5 .78 .485 component_height], 'Browse', 'center', 'k', 'default', 0.5, 'sans serif', 'bold', 'on',  {@choose_seed_images_callback} );

label(seed_load_options_panel, [.01 .68 .95 component_height], 'Seed Common Name:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
seed_common_name_editbox = editbox(seed_load_options_panel, [.01 .62 .98 component_height], load_seed_mask_common_name, 'left', 'k', 'w', .6, 'normal');

  function choose_seed_images_callback(varargin)
    % get directory
    sdir = uigetdir(pwd,'Select Image(s)');
    if sdir ~= 0
      try
        load_seed_mask_path = validate_filepath(sdir);
      catch err
        if (strcmp(err.identifier,'validate_filepath:notFoundInPath')) || ...
            (strcmp(err.identifier,'validate_filepath:argChk'))
          errordlg('Invalid directory selected');
          return;
        else
          rethrow(err);
        end
      end
      set(seed_input_dir_editbox, 'String', load_seed_mask_path);
    end
  end


% Update Button
push_button(seed_load_options_panel, [.1 .28 .78 1.2*component_height], 'Update Seed Mask', 'center', 'k', dark_gray, .5, 'sans serif', 'bold', 'on', {@Seed_Load_Display_update_image});



label(seed_load_options_panel, [.05 .2 .95 component_height], 'ColorMap:', 'left', 'k', lt_gray, .6, 'sans serif', 'normal');
seed_load_Options_colormap_dropdown = popupmenu(seed_load_options_panel, [.05 .16 .91 component_height], colormap_options, 'k', 'w', .6, 'normal', @seed_load_colormap_Callback);
  function seed_load_colormap_Callback(varargin)
    temp = get(seed_load_Options_colormap_dropdown, 'value');
    seed_selected_colormap_opt = colormap_options{temp};
    seed_load_update_display();
  end


seed_load_Display_labeled_text_checkbox = checkbox(seed_load_options_panel, [.53 .21 .45 component_height], 'Show Labels', 'center', 'k', lt_gray, .6, 'sans serif', 'normal', {@seed_load_Display_labeled_text_checkbox_Callback});
set(seed_load_Display_labeled_text_checkbox,'value',seed_display_labeled_text);
  function seed_load_Display_labeled_text_checkbox_Callback(varargin)
    seed_display_labeled_text = logical(get(seed_load_Display_labeled_text_checkbox, 'value'));
    seed_load_update_display();
  end


seed_load_contour_checkbox = checkbox(seed_load_options_panel, [.05 .11 .91 component_height], 'Display Contour', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@seed_load_contour_Callback});
set(seed_load_contour_checkbox, 'value',seed_display_contour);
  function seed_load_contour_Callback(varargin)
    seed_display_contour = get(seed_load_contour_checkbox,'value');
    seed_load_update_display();
  end


seed_load_adjust_contrast_checkbox = checkbox(seed_load_options_panel, [.05 .06 .91 component_height], 'Adjust Contrast', 'center', 'k', lt_gray, .55, 'sans serif', 'normal', {@seed_load_adjust_contrast_Callback});
set(seed_load_adjust_contrast_checkbox, 'value', seed_adjust_contrast);
  function seed_load_adjust_contrast_Callback(varargin)
    seed_adjust_contrast = get(seed_load_adjust_contrast_checkbox,'value');
    seed_load_update_display();
  end


% Seed Apply Push Button
push_button(seed_load_options_panel, [.01 .01 .49 component_height], 'Apply', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'on', {@seed_load_apply_mask});
  function seed_load_apply_mask(varargin)
    
    seed_mask = [];
    seed_mask = seed_temp_mask;
    seed_temp_mask = [];
    
    load_seed_mask_path = get(seed_input_dir_editbox, 'String');
    if load_seed_mask_path(end) ~= filesep
      load_seed_mask_path = [load_seed_mask_path filesep];
    end
    
    load_seed_mask_common_name = get(seed_common_name_editbox, 'String');
    seed_img_files = dir([load_seed_mask_path '*' load_seed_mask_common_name '*.tif']);
    nb_seed_frames = length(seed_img_files);
    if nb_seed_frames ~= nb_frames
      errordlg('Chosen seed image folder doesn''t the same number of .tif images as the images being segmented.');
      return;
    end
    
    use_load_seed_mask = true;
    
    set(h_tabpanel(3), 'Visible', 'on');
    set(h_tabpanel(7), 'Visible', 'off');
    
    % Update Object Separation Image
    os_update_image();
    
  end

% Seed Cancel Push Button
push_button(seed_load_options_panel, [.5 .01 .49 component_height], 'Cancel', 'center', 'k', lt_gray, .5, 'sans serif', 'bold', 'on', {@seed_load_cancel_mask});
  function seed_load_cancel_mask(varargin)
    
    seed_img_files = [];
    
    seed_temp_mask = [];
    set(h_tabpanel(3), 'Visible', 'on');
    set(h_tabpanel(7), 'Visible', 'off');
  end


% Setup the Display Image Axis
seed_load_display_Axis = axes('Parent', seed_load_display_panel, 'Units','normalized','Position', [.01 .01 .98 .98]);
axis off; axis image;


  function Seed_Load_Display_update_image(varargin)
    
    load_seed_mask_path = get(seed_input_dir_editbox, 'String');
    if load_seed_mask_path(end) ~= filesep
      load_seed_mask_path = [load_seed_mask_path filesep];
    end
    
    load_seed_mask_common_name = get(seed_common_name_editbox, 'String');
    
    % validate that the number of images matches
    seed_img_files = dir([load_seed_mask_path '*' load_seed_mask_common_name '*.tif']);
    nb_seed_frames = length(seed_img_files);
    if nb_seed_frames == 1
      stats = imfinfo([load_seed_mask_path seed_img_files(current_frame_nb).name]);
      if numel(stats) > 1
        nb_seed_frames = numel(stats);
        seed_img_files = repmat(seed_img_files, nb_fg_frames, 1);
      end
    end
    
    
    if nb_seed_frames ~= nb_frames
      errordlg('Chosen seed image folder doesn''t the same number of .tif images as the images being segmented.');
      return;
    end
    
    
    
    set(seed_load_display_panel, 'Title', ['Image: <' seed_img_files(current_frame_nb).name '>']);
    
    % get a current copy of the seed mask img
    seed_temp_mask = get_Seed_Mask_Image(true);
    
    % display the img
    delete(get(seed_load_display_Axis, 'Children'));
    disp_I = superimpose_colormap_contour(img, seed_temp_mask, colormap([seed_selected_colormap_opt '(65000)']), seed_countour_color_selected_opt,1, seed_display_contour, seed_adjust_contrast);
    imshow(disp_I, 'Parent', seed_load_display_Axis);
    %         set(seed_load_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
    
  end



  function BW = get_Border_Mask_Image()
    
    if os_display_use_border
      if border_operate_on_gradient_flag
        img_filter = 'gradient';
      else
        img_filter = 'none';
      end
      
      BW = generate_border_mask(img, img_filter, border_threshold_value, border_threshold_operator_modifier, border_break_holes_flag, border_thin_mask_flag, foreground_mask);
    else
      BW = [];
    end
    
  end


  function BW = get_Seed_Mask_Image(load_img_flag)
    
    if os_display_use_seed
      gen_seed_image_flag = false;
      if exist('load_img_flag','var')
        if load_img_flag
          gen_seed_image_flag = false;
        else
          gen_seed_image_flag = true;
        end
      else
        if use_load_seed_mask
          gen_seed_image_flag = false;
        else
          gen_seed_image_flag = true;
        end
        
      end
      
      if ~gen_seed_image_flag
        
        if numel(imfinfo([load_seed_mask_path seed_img_files(current_frame_nb).name])) > 1
          BW = imread([load_seed_mask_path seed_img_files(current_frame_nb).name], 'Index', current_frame_nb);
        else
          BW = imread([load_seed_mask_path seed_img_files(current_frame_nb).name]);
        end
        BW = double(BW);
        
        if size(BW,1) ~= size(img,1) || size(BW,2) ~= size(img,2)
          errordlg('Loaded Seed image doesn''t match the image dimensions of the image being segmented.');
          return;
        end
        
        % if BW is a binary image, relabel it into connected component objects
        u = unique(BW);
        if numel(u) <= 2
          BW = bwlabel(BW);
        end
        
      else
        if seed_operate_on_gradient_flag
          img_filter = 'gradient';
        else
          img_filter = 'none';
        end
        
        % swap the direction of the left operator to reflect the face that its: <thres> <operator> <pixelvalue>
        % instead of <pixelvalue> <operator> <thres>
        switch seed_threshold_operatorL
          case '<'
            tempL = '>=';
          case '<='
            tempL = '>';
          case '>'
            tempL = '<=';
          case '>='
            tempL = '<';
          otherwise
            error('Invalid Threhsold Operator');
        end
        
        if seed_use_border
          BW = generate_seed_mask(img, img_filter, seed_threshold_valueL, tempL, seed_threshold_valueR, seed_threshold_operatorR, seed_min_object_size, seed_max_object_size, seed_circularity_threshold, seed_cluster_dist, foreground_mask, border_mask);
        else
          BW = generate_seed_mask(img, img_filter, seed_threshold_valueL, tempL, seed_threshold_valueR, seed_threshold_operatorR, seed_min_object_size, seed_max_object_size, seed_circularity_threshold, seed_cluster_dist, foreground_mask);
        end
        
        % perform any required morphological cleanup of the img
        seed_morph_operation = lower(regexprep(seed_morph_operation, '\W', ''));
        if seed_use_border
          temp = ~foreground_mask;
          temp(border_mask) = 1;
          BW = morphOp(img, BW, seed_morph_operation, seed_strel_disk_radius, temp);
        else
          BW = morphOp(img, BW, seed_morph_operation, seed_strel_disk_radius);
        end
      end
    else
      BW = [];
    end
  end

  function BW = get_Mitotic_Mask_Image()
    
    if os_display_use_mitotic
      I1 = generate_image_to_threshold(img, mitotic_grayscale_modifier, mitotic_filter_radius);
      [BW, ~] = threshold_image(I1, mitotic_threshold_modifier,mitotic_threshold_operator, mitotic_threshold_value);
      BW = logical(BW);
      %             if strcmpi(mitotic_threshold_operator, threshold_operator_modifiers{2})
      %                 BW = ~BW;
      %             end
      
      BW = fill_holes(BW, [], mitotic_min_object_size*2);
      
      mitotic_morph_operation = lower(regexprep(mitotic_morph_operation, '\W', ''));
      BW = morphOp(img, BW, mitotic_morph_operation, mitotic_strel_disk_radius);
      
      BW = bwareaopen(BW, mitotic_min_object_size+1);
      
      % fog bank the images
      temp = regexprep(mitotic_fogbank_direction, '\W', '');
      if strcmpi(temp, 'minmax')
        fogbank_dir = 1;
      else
        fogbank_dir = 0;
      end
      
      temp = logical(BW);
      temp = imerode(temp, strel('disk',ceil(mitotic_strel_disk_radius/2)));
      % fog bank mitotic cell apart
      [BW, ~] = fog_bank_perctile_geodist(I1, logical(BW), temp, mitotic_min_peak_size, mitotic_min_object_size, fogbank_dir, 10);
      BW = filter_by_circularity(BW, mitotic_circularity_threshold);
      
    else
      BW = [];
    end
    
  end


% get the fogbank input img (distance transform or grayscale or other)
  function I1 = get_Fogbank_Input_Image()
    
    temp = get(os_fogbank_input_dropdown, 'value');
    type_str = fogbank_input_options{temp};
    type_str = strrep(lower(type_str), ' ','');
    
    I1 = [];
    if strcmpi(type_str, 'distancetransformfromseeds')
      if os_display_use_seed
        % distance transform from the seeds
        if os_display_use_border
          I1 = bwdistgeodesic(~border_mask, seed_mask>0, 'quasi-euclidean');
        else
          I1 = bwdist(seed_mask>0, 'euclidean');
        end
      else
        errordlg('Cannot use Distance Transform from Seeds without enabling the seed mask');
        return;
      end
    end
    if strcmpi(type_str, 'distancetransformfrombackground')
      % distance transform from the background
      if os_display_use_border
        temp = foreground_mask;
        temp(~border_mask) = 0;
        I1 = bwdist(temp, 'euclidean');
      else
        I1 = bwdist(~foreground_mask, 'euclidean');
      end
    end
    if strcmpi(type_str, 'gradient')
      I1 = imgradient(img);
    end
    
    
    if ~isempty(I1)
      I1(~foreground_mask) = 0;
      I1(isnan(I1)) = max(I1(:));
    end
    if isempty(I1)
      I1 = double(img);
    end
    I1(isinf(I1)) = max(I1(~isinf(I1)));
  end




  function [segmented_image, nb_obj] = fogbank_given_image(img_nb)
    
    img = loadCurrentImage(img_nb);
    
    foreground_mask = get_Foreground_Mask(img_nb);
    
    % get a copy of the border mask
    border_mask = get_Border_Mask_Image();
    % get a copy of the seed mask
    seed_mask = get_Seed_Mask_Image();
    % get a copy of the mitotic mask
    mitotic_mask = get_Mitotic_Mask_Image();
    
    % get the img fogbank will operate on
    I1 = get_Fogbank_Input_Image();
    
    temp_border_mask = border_mask;
    if ~os_display_use_border || isempty(border_mask)
      temp_border_mask = false(size(foreground_mask));
    end
    
    % fog bank the images
    temp = regexprep(fogbank_direction, '\W', '');
    if strcmpi(temp, 'minmax')
      fogbank_dir = 1;
    else
      fogbank_dir = 0;
    end
    
    % TODO change this to alter the percentile binning
    prctile_bin = 5;
    %         prctile_bin = 1;
    
    % apply the seeds to I1
    if os_display_use_seed && ~isempty(seed_mask)
      if fogbank_dir % min to max
        I1(seed_mask>0) = min(I1(seed_mask>0));
      else % max to min
        I1(seed_mask>0) = max(I1(seed_mask>0));
      end
      
      %             temp_border_mask = logical(foreground_mask);
      %             if os_display_use_border
      %                 temp_border_mask(border_mask>0) = 0;
      %             end
      %             I1 = I1/max(I1(:));
      %             I1 = 1 - I1;
      %             I1(~foreground_mask) = 0;
      % %             [segmented_image, ~] = fog_bank_g(I1, temp_border_mask, min_object_size, 250, 1);
      %             segmented_image = fog_bank_g_seed_mask2(I1, temp_border_mask, seed_mask);
      %             segmented_image = assign_nearest_connected_label(segmented_image, foreground_mask);
      %
      [segmented_image, ~] = fog_bank_perctile_geodist_seed(I1, logical(foreground_mask), ~temp_border_mask, seed_mask, min_object_size, fogbank_dir, prctile_bin);
      
      % if any foreground region was not found by a seed add it back in to prevent loosing any area
      temp = bwlabel(foreground_mask);
      temp(segmented_image>0) = 0;
      mv = max(temp(:));
      if mv ~= 0
        temp = bwlabel(bwareaopen(temp,min_object_size));
        temp = cast(temp, class(segmented_image));
        highest_cell_nb = max(segmented_image(:));
        temp(temp>0) = temp(temp>0) + highest_cell_nb;
        % copy in the missing objects
        segmented_image(temp>0) = temp(temp>0);
      end
    else
      %             temp_mask = logical(foreground_mask);
      %             temp_mask(temp_border_mask) = 0;
      %             I1 = I1/max(I1(:));
      %             I1 = 1 - I1;
      %             I1(~foreground_mask) = 0;
      %             [segmented_image, ~] = fog_bank_g(I1, temp_mask, min_object_size, min_peak_size, prctile_bin);
      %             segmented_image = assign_nearest_connected_label(segmented_image, foreground_mask);
      
      [segmented_image, ~] = fog_bank_perctile_geodist(I1, logical(foreground_mask), ~temp_border_mask, min_peak_size, min_object_size, fogbank_dir, prctile_bin);
    end
    
    if os_display_use_mitotic && ~isempty(mitotic_mask)
      mitotic_mask = relabel_image(mitotic_mask);
      temp = mitotic_mask>0;
      mitotic_mask(temp) = mitotic_mask(temp) + max(segmented_image(:));
      
      segmented_image(temp) = mitotic_mask(temp);
      
      [segmented_image, nb_obj] = relabel_image(segmented_image);
      segmented_image = check_body_connectivity(segmented_image, nb_obj);
    end
    
    nb_obj = max(segmented_image(:));
    
    
  end



  function result_super_img = get_Superimpose_Image()
    if os_display_raw_image
      result_super_img = superimpose_colormap_contour(img, segmented_image, colormap([os_selected_colormap_opt '(65000)']), os_selected_colormap_opt, 1, os_display_contour, os_adjust_contrast_display_raw_image);
    else
      result_super_img = superimpose_colormap_contour(zeros(size(img)), segmented_image, colormap([os_selected_colormap_opt '(65000)']), os_selected_colormap_opt, 1, os_display_contour, os_adjust_contrast_display_raw_image);
    end
  end


  function seed_load_update_display(varargin)
    
    if isempty(img) || isempty(seed_temp_mask)
      return;
    end
    
    
    delete(get(seed_load_display_Axis, 'Children'));
    disp_I = superimpose_colormap_contour(img, seed_temp_mask, colormap([seed_selected_colormap_opt '(65000)']), seed_countour_color_selected_opt,1, seed_display_contour, seed_adjust_contrast);
    imshow(disp_I, 'Parent', seed_load_display_Axis);
    %         set(seed_load_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
    
    % show labels
    if seed_display_labeled_text
      hold on;
      
      nb_seed_obj = max(seed_temp_mask(:));
      [~, seed_text_location] = find_edges_labeled(seed_temp_mask, nb_seed_obj);
      for i = 1:nb_seed_obj
        cell_number = seed_temp_mask(seed_text_location(i,2), seed_text_location(i,1));
        
        text(seed_text_location(i,1), seed_text_location(i,2), num2str(cell_number), 'fontsize', 8, ...
          'FontWeight', 'bold', 'Margin', .1, 'color', 'k', 'BackgroundColor', 'w', 'parent', seed_load_display_Axis)
      end
      
      hold off;
    end
    
    %         set(seed_load_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
  end



  function seed_update_display(varargin)
    
    if isempty(img) || isempty(seed_temp_mask)
      return;
    end
    
    
    delete(get(seed_display_Axis, 'Children'));
    
    img1 = img;
    if seed_use_border && exist('border_mask', 'var') && ~isempty(border_mask)
      if get(Percentile_threshold_operator_modifier_dropdown, 'value') == 1
        img1(border_mask) = min(img1(:));
      else
        img1(border_mask) = max(img1(:));
      end
    end
    
    
    disp_I = superimpose_colormap_contour(img1, seed_temp_mask, colormap([seed_selected_colormap_opt '(65000)']), seed_countour_color_selected_opt,1, seed_display_contour, seed_adjust_contrast);
    imshow(disp_I, 'Parent', seed_display_Axis);
    %         set(seed_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
    
    % show labels
    if seed_display_labeled_text
      hold on;
      
      nb_seed_obj = max(seed_temp_mask(:));
      [~, seed_text_location] = find_edges_labeled(seed_temp_mask, nb_seed_obj);
      for i = 1:nb_seed_obj
        cell_number = seed_temp_mask(seed_text_location(i,2), seed_text_location(i,1));
        
        text(seed_text_location(i,1), seed_text_location(i,2), num2str(cell_number), 'fontsize', 8, ...
          'FontWeight', 'bold', 'Margin', .1, 'color', 'k', 'BackgroundColor', 'w', 'parent', seed_display_Axis)
      end
      
      hold off;
    end
    
    %         set(seed_display_Axis,'nextplot','replacechildren'); % maintains zoom when clicking through slider
  end



% used when the img is changed via the slider or goto input and when new images are loaded
  function destroyMasks(varargin)
    border_mask = [];
    mitotic_mask = [];
    seed_mask = [];
  end


end %%%%%%%%%%%%%%%%%% End FogBank GUI %%%%%%%%%%%%%%%%%%




















