function [win1, winRect1, flipHz, flipPeriod, win2, winRect2] = WinInit(windowed)
%INITWIN Opens window before loading task
%   InitWin opens a fullscreen window on the display with the highest ID
%   number.

PsychDefaultSetup(2);
InitializeMatlabOpenGL();

targetHz = 60; % Screen refresh rate
%flipPeriod = 1/targetHz; % in seconds
screenid = 0; %max(Screen('Screens')); % Choose monitor with highest ID number

% if screenid < 2
%     error('Cannot run on a single display. Plug in a second monitor.')
% end

if windowed
    if isunix
        %rectCoord = [1681,1051, 2960, 2074];
        rectCoord1 = [1680,1050, 2960, 2100];
        rectCoord2 = [0,1050, 1280, 2074];
    else
        rectCoord = [20 20 768 480];
    end
else
    rectCoord = [];
end

blueVec = [64,49,82,256]/256;
[win1, winRect1] = PsychImaging('OpenWindow', screenid, blueVec, rectCoord1);
[win2, winRect2] = PsychImaging('OpenWindow', screenid, blueVec, rectCoord2);
currHz = Screen('NominalFrameRate',win1,[],60);
%flipHz = Screen('GetFlipInterval',win);
tol = 0.05 * targetHz;
if abs(currHz-targetHz) > tol
    error('Wrong refresh rate. Check display settings.')
    sca;
else
    flipHz = 60;
    flipPeriod = 1/flipHz;
end
ar = winRect1(4)/winRect1(3); % screen aspect ratio
end

