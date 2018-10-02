function DoTrial(app)
%DoTrial Center-out or random target task
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
% Added invertion for Logitech joystick. Now require WinInit and WinClose. 071218
% Converted SimpleTask to DoTrial (for app) 071618
    % Added target/cursor radius field
    % Fixed velGain for joystick, mouse
    % Remove trial loop and keyboard ESC
    % Moved close joy to WinClose
   % Enable halt 071918
   % Added targetType option 072518
    % need to fix torus collision
    % need to fix target initial position
   % Rerandomize cursor if collide with target at 1st frame 072618
    % cursor display limits
    % collision function

%% Initial stuff
global dat AGL GL GLU;
gx = 0; gy = 0;
white = WhiteIndex(app.win2);
InitializeMatlabOpenGL();
targetRad = app.TargetSizeEditField.Value;
cursorRad = app.CursorSizeEditField.Value;
gazeRad = app.GazeSizeEditField.Value;
effTargetRad=0.1*targetRad;
effCursorRad=0.1*cursorRad;
effGazeRad=7*gazeRad;
mouseInsteadOfGaze = app.SimulationCheckBox.Value;
targetType = 'sphere';
app.trialNum = 1;
app.TrialNumEditField.Value = app.trialNum;
app.loopTask = 1;
while app.loopTask


%velGain = 1; % This is the gain for cursor velocity that will appear and can 
% be modified with the GUI.
%velGainCorrection = 2; % velGain*velGainCorrection determines the cursor
% speed. The joystick range is (-1,1) in both directions (x,y). This scalar
% is reserved for future use and should only be accessible internally.
% Testing needs to be done to match the default cursor speed with the
% old NERVE system. Ask Dan what the default cursor speed was or should be
% (in pixels/second or visual angle/second). For now, this value is not
% final but good enough visually. 
%velEffective = velGain * velGainCorrection;
%velGainMouse = 0.75; % if using mouse for testing

if strcmp(app.DeviceDropDown.Value, 'Joystick')
    % Using Joystick
    useJoy = 1;
    joy = app.joy;
    velGain = app.VelocityEditField.Value;
    velGainCorrection = 2;
else
    % Mouse
    useJoy = 0;
    velGain = app.VelocityEditField_2.Value;
    velGainCorrection = 1; %0.75;
end
velEffective = velGain * velGainCorrection;

% For human debugging/testing setup (in the main lab computers)
debugTest = 0;
% if app.TestingLogitechCheckBox.Value
%     debugTest = 1;
% end

% Cursor limits (in normalized coordinates)
xLimNorm = 3; % 3.3
yLimNorm = 1.75; % 2

createFile = 0;
edfFile=app.EyelinkEDFEditField.Value;

try
if app.EyelinkCheckBox.Value
    eye_used = -1;
    if (Eyelink('Initialize') ~= 0)
        error('could not initialize connection to Eyelink')
    end
    el = EyelinkInitDefaults(app.win);
    status = Eyelink('command','link_sample_data = LEFT,RIGHT,GAZE,AREA,GAZERES,HREF,PUPIL,STATUS,INPUT');
    if status ~= 0
        error('openfile error, status: ',status)
    end
    status = Eyelink('startrecording');
    if status ~= 0
        error('startrecording error, status: ',status)
    end
    WaitSecs(0.1);
    status = Eyelink('message','SYNCTIME');
    if status ~=0
        error('message error, status: ',status)
    end
end
enableDepth = 1; % Enable OpenGL depth testing

%% Default colors
    cursorColor					= [0.8,	0.4,	0.1,	1]; %orange red
	cursorRewardColor			= [0.9,	0.9,	0.9,	1]; %gray
	cursorCorrectColor			= [0.7,	1.0,	0.2,	1]; %green
	cursorWrongColor			= [0.1,	0.1,	0.1,	1]; %black
	centerColor					= [0.0,	0.8,	0.8,	1]; %cyan
	ringColor					= [0.0,	0.8,	0.8,	1]; %cyan
	ringWrongColor				= [1.0,	0.0,	0.0,	1]; %red
	ringCorrectColor			= [0.7,	1.0,	0.2,	1]; %green
    gazeColor                   = [0,   0,      0       1]; %white?
%     red = [158,78,43,256]/256;
    blueVec = [64,49,82,256]/256;
    blue = num2cell(blueVec);
    
%% Psychtoolbox window settings
flipHz = 60; % Screen refresh rate
flipPeriod = 1/flipHz; % in seconds
ar = app.winRect(4)/app.winRect(3); % screen aspect ratio
vp = glGetFloatv(GL.VIEWPORT); % viewport/screen dimension in pixels

%% Main loop
% Trial sequence
% |Trial start|----------|Correct/Timeout/Reset|----|End/Clear|

if strcmp(app.taskName, 'XY')
    centerOut = 0; % Set to true for center out task. Target appears at (0,0).
else
    centerOut = 1;
end

timeOut = app.DurationEditField.Value; % Time (s) from trial start to reset
tStart = GetSecs;
resetTime = app.ResetEditField.Value; % Time in seconds from correct/timeout to end
resetFrameNum = resetTime * flipHz; % Total number of frames from reset to end of trial

%% Init Trial
iter = 1; % Tracks frame number for testing
firstFrame = 1; %startTrial=0; endTrialInit=0;
endTrial = 0;
correct = 0;
resetTrial = 0; % true if correct or trial times out. Initiates end of trial.
resetFrame = 0; % Counts number of frames from reset to last frame.

joyRecord = []; % raw joystick
dispRecord = []; % joystick converted to displacement
curPosRecord = []; % norm cursor position
gazeRecord = [];
%targetPos = []; % norm target position if not center-out

cursorMat = eye(4); % Initialize cursor position matrix
targetMat = eye(4); % Initialize target position matrix

while ~endTrial
    if ~resetTrial
        tCurr = GetSecs;
        if ((tCurr - tStart) >= timeOut) || correct
            resetTrial = 1;
            if ~correct
                tEnd = tCurr;
            end
        end
    end
    if useJoy
        v = round(read(joy), 1); % read joystick input
        if debugTest
            v(2) = -v(2); % correct Logitech joystick inversion
        end
    else
        % Mouse input for testing only. If joystick is not available.
        if IsWin
        [mx,my] = GetMouse(2);
        elseif IsLinux
            [mx,my] = GetMouse;
        end
        sx = mx/840-1;
        sy = 1-my/525;
        v = [sx,sy];
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
    
    %calculate target translation values (openGL coords)
    transX = rand*4-2;
    transY = rand*4-2;
    transXcurs = rand*2*yLimNorm-yLimNorm;
    transYcurs = rand*2*yLimNorm-yLimNorm;
    
    % Setup OpenGL rendering. Most of the commands that follow are OpenGL
    % functions.
    Screen('BeginOpenGL', app.win);
    
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
            glTranslatef(transX, transY, 0); % Randomize target position
            targetMat = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4);
            [tx, ty] = GetCurPos(targetMat); % Get target position
        end
        glLoadMatrixf(targetMat); % Load target position
    else
        tx = 0; ty = 0; % Target position at screen center (0,0)
    end
    switch targetType
        case 'sphere'
            glutSolidSphere(effTargetRad, 100, 100); % Draw target sphere
        case 'torus'
            glutSolidTorus(.2, 1, 360, 60); % Draw target torus
    end
    targetPosTest = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4); % Check target position (for testing)

    %% Cursor
    %glMatrixMode(GL.MODELVIEW);
    glLoadIdentity;
    gluLookAt(0,0,5,0,0,0,0,1,0);
    %glLoadMatrixf(cursorMat);

    %gluLookAt(0,0,10,0,0,0,0,1,0);
    glMaterialfv(GL.FRONT_AND_BACK,GL.AMBIENT_AND_DIFFUSE, currCursorColor);
    if firstFrame
        randCursor = 1;
        %glTranslatef(rand*4-2, rand*4-2, 0);
        %while loop ensures cursor is not placed initialized same as target
        while randCursor
            preCursor = [transXcurs, transYcurs];
            %glTranslatef(rand*4-2, rand*4-2, 0); % Randomize cursor position
            %glTranslatef(rand*yLimNorm, rand*yLimNorm, 0); % Randomize cursor position
                %glTranslatef(2, 0, 0);
                %gluLookAt(0,0,5,0,0,0,0,1,0);
            %cursorMat = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4);
            %[curx, cury] = GetCurPos(cursorMat);
            randCursor = CheckCollision(tx, ty, preCursor(1), preCursor(2), effTargetRad, effCursorRad, 'sphere');
        end
        glTranslatef(preCursor(1), preCursor(2), 0);
        cursorMat = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4);
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

    
    Screen('EndOpenGL', app.win); % Finish OpenGL rendering into PTB window
    Screen('DrawingFinished',app.win);
    
    %%
    Screen('BeginOpenGL', app.win2);
    
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
            glTranslatef(transX, transY, 0); % Randomize target position
            targetMat = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4);
            [tx, ty] = GetCurPos(targetMat); % Get target position
        end
        glLoadMatrixf(targetMat); % Load target position
    else
        tx = 0; ty = 0; % Target position at screen center (0,0)
    end
    switch targetType
        case 'sphere'
            glutSolidSphere(effTargetRad, 100, 100); % Draw target sphere
        case 'torus'
            glutSolidTorus(.2, 1, 360, 60); % Draw target torus
    end
    targetPosTest = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4); % Check target position (for testing)

    %% Cursor
    %glMatrixMode(GL.MODELVIEW);
    glLoadIdentity;
    gluLookAt(0,0,5,0,0,0,0,1,0);
    %glLoadMatrixf(cursorMat);

    %gluLookAt(0,0,10,0,0,0,0,1,0);
    glMaterialfv(GL.FRONT_AND_BACK,GL.AMBIENT_AND_DIFFUSE, currCursorColor);
    if firstFrame
        randCursor = 1;
        %glTranslatef(rand*4-2, rand*4-2, 0);
        while randCursor
            preCursor = [transXcurs, transYcurs];
            %glTranslatef(rand*4-2, rand*4-2, 0); % Randomize cursor position
            %glTranslatef(rand*yLimNorm, rand*yLimNorm, 0); % Randomize cursor position
                %glTranslatef(2, 0, 0);
                %gluLookAt(0,0,5,0,0,0,0,1,0);
            %cursorMat = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4);
            %[curx, cury] = GetCurPos(cursorMat);
            randCursor = CheckCollision(tx, ty, preCursor(1), preCursor(2), effTargetRad, effCursorRad, 'sphere');
        end
        glTranslatef(preCursor(1), preCursor(2), 0);
        cursorMat = reshape(glGetFloatv(GL.MODELVIEW_MATRIX),4,4);
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
    
    Screen('EndOpenGL', app.win2); % Finish OpenGL rendering into PTB window
    %% Gaze
    if app.EyelinkCheckBox.Value
        err = Eyelink('checkrecording');
        if err~=0
            error('checkrecording problem, status: ',err)
        end
        status = Eyelink('newfloatsampleavailable');
        if status>0
            if eye_used ~= -1
                evt = Eyelink('newestfloatsample');
                gx = evt.gx(eye_used+1);
                gy = evt.gy(eye_used+1);
                if (gx ~= el.MISSING_DATA && gy ~= el.MISSING_DATA && evt.pa(eye_used+1)>0 || mouseInsteadOfGaze)
                    if app.SimulationCheckBox.Value
                        [gx,gy] = GetMouse();
                    end
                    gazeRect = [gx-effGazeRad/2 gy-effGazeRad/2 gx+effGazeRad/2 gy+effGazeRad/2];
                    penSize=6;
                    Screen('FrameOval',app.win2,white,gazeRect,penSize,penSize);
                end
            else
               eye_used = Eyelink('eyeavailable');
               if eye_used==el.BINOCULAR
                    eye_used = el.RIGHT_EYE;
               elseif eye_used==-1
                   error('eyeavailble returned -1')
               end
            end
        else
            fprintf('no sample avail, status: %d\n',status)
        end
    end
    
    Screen('DrawingFinished',app.win2);
    
    %%
    tFlip = Screen('Flip', app.win,[],[],[],1); % Show rendered image at next vertical retrace
    if firstFrame
        tStart = tFlip; 
        %t1 = tStart; % !!!dummy. look for trials where t1=tStart=tEnd. randomization error
    end
    
    % Get cursor position. Check if out of bounds. If outside, stop at x,y
    % limits. Normalized limits: x=[-3.3,3.3]; y=[-2,2]. These limits were
    % tested with a 1680x1050 display. May need adjustment when using other
    % monitors in the lab, i.e., those with a different aspect ratio.
    % TEST MONKEY ROOM MONITORS!!!
    % curx = cursorMat(1, 4); cury = cursorMat(2, 4);
    [curx, cury] = GetCurPos(cursorMat);
    curx = bound(curx, -xLimNorm, xLimNorm);
    cury = bound(cury, -yLimNorm, yLimNorm);
    cursorMat(1, 4) = curx; cursorMat(2, 4) = cury;
    curPosRecord(end+1,:) = [curx, cury];
    gazeRecord(end+1,:) = [gx,gy];
    
    % Collision check
    if ~resetTrial
        collisionFlag = CheckCollision(tx, ty, curx, cury, effTargetRad, effCursorRad, 'sphere');
        if collisionFlag
            correct = 1;            
            tEnd = tFlip;
            Eyelink('Command','write_ioport 0x5 255');
            WaitSecs(app.RewardEditField.Value/1000);
            Eyelink('Command','write_ioport 0x5 0');
        end
    end
    
    joyRecord(end + 1, :) = v;
    dispRecord(end + 1, :) = cursorTranslate;
    
    iter = iter + 1; firstFrame = 0;
    if resetFrame == resetFrameNum
        endTrial = 1;
    end
    
% Halt in the middle of trial.
    pause(0.0001);
    if ~app.loopTask
        return;
    end
end
tClear = Screen('Flip', app.win,[],[],[],1); % Clear screen for next trial
WaitSecs(0.1)

% Record data

sx = length(dat);

dat(sx+1).tStart = tStart;
dat(sx+1).tEnd = tEnd;
dat(sx+1).tClear = tClear;
dat(sx+1).correct = correct;
dat(sx+1).joyRecord = joyRecord;
dat(sx+1).dispRecord = dispRecord;
dat(sx+1).curPosRecord = curPosRecord;
dat(sx+1).gazeRecord = gazeRecord;
dat(sx+1).targetPos = [tx, ty];
dat(sx+1).trialNum = app.trialNum;
app.trialNum = app.trialNum + 1;
% cleanup(createFile,edfFile)

catch
    if app.EyelinkCheckBox.Value
        cleanup(createFile, edfFile)
    end
    Screen('CloseAll')
    ShowCursor;
    ers=lasterror;
    ers.stack.file
    ers.stack.name
    ers.stack.line
    rethrow(lasterror)
end

d = datestr(now);
save(d,'dat');

if app.ITIEditField.Value == 0
    pause(0.01); % pause task to give time to interrupt with stop
else
    pause(app.ITIEditField.Value);
end
app.TrialNumEditField.Value = app.trialNum;
end
end
function cleanup(createFile, edfFile)
    Eyelink('stoprecording');
    if createFile
        status=Eyelink('closefile');
        if status ~=0
            fprintf('closefile error, status: %d\n',status)
        end
        status=Eyelink('ReceiveFile',edfFile,pwd,1);
        if status~=0
            fprintf('problem: ReceiveFile status: %d\n', status);
        end
        if 2==exist(edfFile,'file')
            fprintf('Data file "%s" can be found in :%s"\n',edfFile,pwd )
        else
            disp('unknown where data file went')
        end
    end
    Eyelink('shutdown')
end