function joy = JoyInit(id)
% joy = JoyInit(id)
% 
% Creates a joystick object. Checks if a joystick is plugged in and 
% performs initial state test. If more than one joystick is present, 
% specify 'id' according to order they were plugged in.
%
% The lab uses APEM 9000 Series joysticks (exact model number may vary) 
% with 2 axes (x,y) and 0 buttons. However, the USB interface, JoyWarrior 
% A10-8, passes 3 axes and 8 buttons. So, when reading joystick state/values,
% ignore z-axis.
%
% Very Important:
% 1. These joysticks seem to have a varying offset as large as +/-0.009
% (even +/-0.01 at times). If the offset is unusally large even when the
% joystick is in the (0,0) position, consider unplugging/replugging,
% restarting Matlab, or replacing the joystick.
%
% 2. To read values, use val = read(joy), but ignore third element (z-axis).
% This gives values with 4 decimal places (ten-thousandths). Rounding to
% the nearest hundredth is recommended(?) (due to the offset described
% above). If you don't, you will get drifting output.
% Is this true? Rounding decreases resolution. Not rounding may introduce
% drift, which is bad if treating joystick state as velocity. But is either
% option really that bad? Need to do more testing with the actual task to
% see if rounding is necessary or if it even matters.
%
% Single axis can also be read using a = axis(joy, ax) with ax=1 or 2 for x or y.
% 
% Axis state reported is normalized. Values are within the interval [-1,1]
% (i.e., x/y axis min=-1, max=1).
%
% This requires Simulink 3D Animation toolbox. If the vrjoystick
% function is not found, check that you have this toolbox installed.

if nargin < 1
    id = 1;
end
try
    joy = vrjoystick(id); % creates a joystick object
catch ME
    throwAsCaller(ME);
end
a = read(joy); a = a(1:2); % reads the state of axes (ignore z-axis)

fprintf('Joystick found with id %u \n', id)
fprintf('Current x,y values = %.4f %.4f \n', a(1), a(2)) % check offset