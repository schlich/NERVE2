% Simple center-out task
% Target appears at the center of the screen (0,0). Starting cursor
% position is randomized. To randomize target initial position, set
% centerOut = 0. Note: Tested on a 1680x1050 display. Screen coordinates in
% pixels are transformed and normalized to OpenGL coordinates (which is
% sort of arbitrary because various settings affect the effective 
% dimensions--aspect ratio, viewing angle, and other things). With the
% current settings, x=(0,1680) and y=(0,1050) converts to roughly
% (-3.3,+3.3) horizontal and (-2,+2) vertical OpenGL coordinates. If the
% display is clipped, try modifying the inputs to gluPerspective(viewing
% angle in degrees in the vertical direction, 1/aspect ratio, near, far
% clip planes). 062618

%% Initial stuff
sca; close all; clearvars;

centerRad=2; effCenterRad=0.1*centerRad;
cursorRad=2; effCursorRad=0.1*cursorRad;

% Joystick connected. Set to 0 if using mouse for testing.
useJoy = 1;
if useJoy
    joy = JoyInit(1);
end
debugTest = 1; % For human debugging/testing setup

enableDepth = 1; % Enable OpenGL depth testing

velGain = 1; % This is the gain for cursor velocity that will appear and can 
% be modified with the GUI.
velGainCorrection = 2; % velGain*velGainCorrection determines the cursor
% speed. The joystick range is (-1,1) in both directions (x,y). This scalar
% is reserved for future use and should only be accessible internally.
% Testing needs to be done to match the default cursor speed with the
% old NERVE system. Ask Dan what the default cursor speed was or should be
% (in pixels/second or visual angle/second). For now, this value is not
% final but good enough visually. 
velEffective = velGain * velGainCorrection;
velGainMouse = 0.75; % if using mouse for testing

KbName('UnifyKeynames');
RestrictKeysForKbCheck(KbName('ESCAPE'));

PsychDefaultSetup(2);
InitializeMatlabOpenGL();

%% Default colors
    cursorColor					= [0.8,	0.4,	0.1,	1]; %orange red
	cursorRewardColor			= [0.9,	0.9,	0.9,	1]; %gray
	cursorCorrectColor			= [0.7,	1.0,	0.2,	1]; %green
	cursorWrongColor			= [0.1,	0.1,	0.1,	1]; %black
	centerColor					= [0.0,	0.8,	0.8,	1]; %cyan
	ringColor					= [0.0,	0.8,	0.8,	1]; %cyan
	ringWrongColor				= [1.0,	0.0,	0.0,	1]; %red
	ringCorrectColor			= [0.7,	1.0,	0.2,	1]; %green
%     red = [158,78,43,256]/256;
    blueVec = [64,49,82,256]/256;
    blue = num2cell(blueVec);
    
%% Open Psychtoolbox window
flipHz = 60; % Screen refresh rate
flipPeriod = 1/flipHz; % in seconds
screenid = max(Screen('Screens')); % Choose monitor with highest ID number
[win, winRect] = PsychImaging('OpenWindow', screenid, blueVec);
ar = winRect(4)/winRect(3); % screen aspect ratio
vp = glGetFloatv(GL.VIEWPORT); % viewport/screen dimension in pixels

%% Main loop
% Trial sequence
% |Trial start|----------|Correct/Timeout/Reset|----|End/Clear|

for i=1:5
centerOut = 0; % Set to true for center out task. Target appears at (0,0).
timeOut = 4; % Time (s) from trial start to reset
ts = GetSecs;
resetTime = 1; % Time in seconds from correct/timeout to end
resetFrameNum = resetTime * flipHz; % Total number of frames from reset to end of trial

%% Init Trial
iter = 1; % Tracks frame number for testing
firstFrame = 1; %startTrial=0; endTrialInit=0;
endTrial = 0;
correct = 0;
resetTrial = 0; % true if correct or trial times out. Initiates end of trial.
resetFrame = 0; % Counts number of frames from reset to last frame.

cursorMat = eye(4); % Initialize cursor position matrix
targetMat = eye(4); % Initialize target position matrix

while ~endTrial
    if (GetSecs - ts) >= timeOut || correct
        resetTrial = 1;
    end
    if useJoy
        v = round(read(joy), 1); % read joystick input
        if debugTest
            v(2) = -v(2);
        end
    else
        % Mouse input for testing only. If joystick is not available.
        [mx,my] = GetMouse(2);
        sx = mx/840-1;
        sy = 1-my/525;
        v = [sx,sy]*velGainMouse;
        % end of mouse input
    end
    cursorTranslate = [v(1), v(2), 0] * velEffective * flipPeriod; % converts velocity to displacement
    
    % Set cursor and target colors
    if resetTrial
        resetFrame = resetFrame + 1;
        if correct
            currTargetColor = cursorCorrectColor;
            currCursorColor = cursorCorrectColor;
        else
            currTargetColor = cursorWrongColor;
            currCursorColor=cursorWrongColor;
        end
        if resetFrame > resetFrameNum/2
            if correct
                currCursorColor=cursorRewardColor;
            else
                currCursorColor=cursorWrongColor;
            end
        end
    else
        currTargetColor=centerColor;
        currCursorColor=cursorColor;
    end
    
    % Setup OpenGL rendering. Most of the commands that follow are OpenGL
    % functions.
    Screen('BeginOpenGL', win);
    
    glClearColor(blue{:}); % Set background color
    %glClear(GL.COLOR_BUFFER_BIT | GL.STENCIL_BUFFER_BIT | GL.DEPTH_BUFFER_BIT); 

    glEnable(GL.LIGHTING);
    glEnable(GL.LIGHT0); % choose type of lighting
    glClear; % Clear color and depth buffers
    if enableDepth
        glEnable(GL.DEPTH_TEST);
        glClear(GL.DEPTH_BUFFER_BIT);
    end
    %glEnable(GL.STENCIL_TEST); 

    % Set display window matrices
    % In particular, gluPerspective sets viewable area dimensions also
    % effective display size of objects) and normalizes screen coordinates.
    glMatrixMode(GL.PROJECTION);
    glLoadIdentity;
    gluPerspective(45,1/ar,0.1,100); % 45 degrees in the vertical direction, 1/aspect ratio, near, far clip planes
    glLightfv(GL.LIGHT0,GL.POSITION,[ 0 0 5 0 ]); % light position


    %% Target
    %glLightfv(GL.LIGHT0,GL.POSITION,[ 0 0 5 0 ]); %light position
    glMatrixMode(GL.MODELVIEW);
    glLoadIdentity;
    gluLookAt(0,0,5,0,0,0,0,1,0); % camera postition
    glMaterialfv(GL.FRONT_AND_BACK,GL.AMBIENT_AND_DIFFUSE, currTargetColor); % Set target color
    if ~centerOut
        if firstFrame            
            glTranslatef(rand*4-2, rand*4-2, 0); % Randomize target position
            targetMat = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4);
            [tx, ty] = GetCurPos(targetMat); % Get target position
        end
        glLoadMatrixf(targetMat); % Load target position
    else
        tx = 0; ty = 0; % Target position at screen center (0,0)
    end
    glutSolidSphere(effCenterRad, 100, 100); % Draw target sphere
    %glutSolidTorus(.2, 1, 360, 60); % Draw target torus
    targetPos = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4); % Check target position (for testing)

    %% Cursor
    %glMatrixMode(GL.MODELVIEW);
    glLoadIdentity;
    gluLookAt(0,0,5,0,0,0,0,1,0);
    %glLoadMatrixf(cursorMat);

    %gluLookAt(0,0,10,0,0,0,0,1,0);
    glMaterialfv(GL.FRONT_AND_BACK,GL.AMBIENT_AND_DIFFUSE, currCursorColor);
    if firstFrame
        glTranslatef(rand*4-2, rand*4-2, 0); % Randomize cursor position
        %glTranslatef(2, 0, 0);
        %gluLookAt(0,0,5,0,0,0,0,1,0);
        cursorMat=reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4);
        cursorMatInit=cursorMat; % testing
        %glLoadMatrixf(mnext);
    else
        cursorMat = cursorMat * PsychGetPositionYawMatrix(cursorTranslate,0);
        %reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4)
        %glLoadMatrixf(mnext);
        %glTranslatef(v(1)*velGain*velGainCorrection,v(2)*velGain*velGainCorrection,0);
    end
    %gluLookAt(0,0,5,0,0,0,0,1,0);
    glLoadMatrixf(cursorMat);
    glutSolidSphere(effCursorRad, 100, 100); % Draw cursor
    %mOld=reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4);
    %glMatrixTranslatefEXT(GL.MODELVIEW,v(1), v(2), 0);

    
    Screen('EndOpenGL', win); % Finish OpenGL rendering into PTB window
    Screen('Flip', win); % Show rendered image at next vertical retrace
    
    % Get cursor position. Check if out of bounds. If outside, stop at x,y
    % limits. Normalized limits: x=[-3.3,3.3]; y=[-2,2]. These limits were
    % tested with a 1680x1050 display. May need adjustment when using other
    % monitors in the lab, i.e., those with a different aspect ratio.
    % TEST MONKEY ROOM MONITORS!!!
    curx = cursorMat(1, 4); cury = cursorMat(2, 4);
    curx = bound(curx, -3.3, 3.3); cury = bound(cury, -2, 2);
    cursorMat(1, 4) = curx; cursorMat(2, 4) = cury;
    
    % Collision check
    if ~resetTrial
        d = sqrt((curx-tx)^2 + (cury-ty)^2); % distance(cursor,target)
        if d < (effCursorRad + effCenterRad)
            correct = 1;
        end
    end
    
    iter = iter + 1; firstFrame = 0;
    if resetFrame == resetFrameNum
        endTrial = 1;
    end
end
Screen('Flip', win);
end
%KbWait; while KbCheck; end
sca;
if useJoy
    close(joy);
end
