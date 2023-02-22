function varargout = braintumor_GUI(varargin)
% BRAINTUMOR_GUI MATLAB code for braintumor_GUI.fig
%      BRAINTUMOR_GUI, by itself, creates a new BRAINTUMOR_GUI or raises the existing
%      singleton*.
%
%      H = BRAINTUMOR_GUI returns the handle to a new BRAINTUMOR_GUI or the handle to
%      the existing singleton*.
%
%      BRAINTUMOR_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BRAINTUMOR_GUI.M with the given input arguments.
%
%      BRAINTUMOR_GUI('Property','Value',...) creates a new BRAINTUMOR_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before braintumor_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to braintumor_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help braintumor_GUI

% Last Modified by GUIDE v2.5 03-Feb-2023 21:53:17

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @braintumor_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @braintumor_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before braintumor_GUI is made visible.
function braintumor_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to braintumor_GUI (see VARARGIN)

% Choose default command line output for braintumor_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes braintumor_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = braintumor_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in INPUT_IMAGE.
function INPUT_IMAGE_Callback(hObject, eventdata, handles)
% hObject    handle to INPUT_IMAGE (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s str
[I,path]=uigetfile('.dcm',"select a FILE");
str=strcat(path,I);
s=dicomread(str);
axes(handles.axes1);
imshow(s);
title('Patient''s Brain','FontSize',20);


% --- Executes on button press in DETECT_TUMOR.
function DETECT_TUMOR_Callback(hObject, eventdata, handles)
% hObject    handle to DETECT_TUMOR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s tumor sout inp
 num_iter = 10;
    delta_t = 1/7;  % integration constant
    kappa = 15;     % gradient modulus threshold that controls the conduction.
    option = 2;     % conduction coefficient functions
    inp = anisotrophic(s,num_iter,delta_t,kappa,option);
    inp = uint8(inp);
    
inp=imresize(inp,[256,256]);
if size(inp,3)>1
    inp=rgb2gray(inp);
end

sout=imresize(inp,[256,256]);
t0=60;
th=t0+((max(inp(:))+min(inp(:)))./2);       %thresholding formula
total_px=0;
white_px=0;
for i=1:1:size(inp,1)
    for j=1:1:size(inp,2)
        if inp(i,j)>th
            total_px=total_px+1;
            white_px=white_px+1;
            sout(i,j)=1; %white
        else
            total_px=total_px+1;
            sout(i,j)=0; %black
        end
    end
end


label=bwlabel(sout);        % basically finds the 8-connected components of a binary image
stats=regionprops(logical(sout),'Solidity','Area'); %returns measurements for the set of properties for each 8-connected component
                                                                  %in the binary image, BW

density=[stats.Solidity];
area=[stats.Area];
high_dense_area=density>0.6;            %solidity higher than 60% than other parts of brain
max_area=max(area(high_dense_area));
tumor_label=find(area==max_area);
tumor=ismember(label,tumor_label);  %The ismember function is useful for creating a binary image containing only objects or regions 
                                    %that meet certain criteria.

if max_area>100
   axes(handles.axes2);
   imshow(tumor);
   k = msgbox('Tumor FOUND!!','status');
   title('Tumor Alone','FontSize',20);
else
    h = msgbox('No Tumor is found!!','status');
    return;
end


% --- Executes on button press in TUMOR_ALONE.
function TUMOR_ALONE_Callback(hObject, eventdata, handles)



%% Getting Tumor Outline - image filling, eroding
% erosion the walls by a few pixels
%It works by object expansion, hole filling and finally adding all the disjoint objects
global tumor tumorOutline
dilationAmount = 5;
rad = floor(dilationAmount);
[r,c] = size(tumor);
filledImage = imfill(tumor, 'holes');
for i=1:r
   for j=1:c
       x1=i-rad;
       x2=i+rad;
       y1=j-rad;
       y2=j+rad;
       if x1<1
           x1=1;
       end
       if x2>r
           x2=r;
       end
       if y1<1
           y1=1;
       end
       if y2>c
           y2=c;
       end
       erodedImage(i,j) = min(min(filledImage(x1:x2,y1:y2)));
   end
end


%% subtracting eroded image from original BW image
tumorOutline=tumor;
tumorOutline(erodedImage)=0;
axes(handles.axes3);
imshow(tumorOutline);
title('Tumor Outline','FontSize',20);



% --- Executes on button press in DETECTED_TUMOR.
function DETECTED_TUMOR_Callback(hObject, eventdata, handles)
% hObject    handle to DETECTED_TUMOR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%% Inserting the outline in filtered image in green colour
%(:, :, 1) represents the Red colour plane of the RGB image
%I(:, :, 2) represents the Green colour plane of the RGB image
%I(:, :, 3) represents the Blue colour plane of the RGB image
global inp tumorOutline
rgb = inp(:,:,[1 1 1]);
red = rgb(:,:,1);
red(tumorOutline)=0;
green = rgb(:,:,2);
green(tumorOutline)=255;
blue = rgb(:,:,3);
blue(tumorOutline)=0;
tumorOutlineInserted(:,:,1) = red; 
tumorOutlineInserted(:,:,2) = green; 
tumorOutlineInserted(:,:,3) = blue; 
axes(handles.axes4);
imshow(tumorOutlineInserted);
title('Detected Tumor','FontSize',20);


% --------------------------------------------------------------------


% --------------------------------------------------------------------
function AUTHOR_Callback(hObject, eventdata, handles)
% hObject    handle to AUTHOR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function Untitled_5_Callback(hObject, eventdata, handles)
% hObject    handle to Untitled_5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
