function WinClose(app)
%WINCLOSE Closes window.
%   WinClose closes all Psychtoolbox screens.
sca;
% Add joystick close
%% Close joystick device. Move this to WinClose!
if nargin > 0
    close(app.joy);
end
end

