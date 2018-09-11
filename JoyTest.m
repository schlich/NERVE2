function JoyTest(joy)
% JoyTest(joy)
% 
% Quick joystick test. 'joy' is the joystick handle. A live plot will
% appear where you can test the joystick position. Move the joystick around.
% Check that the output is not drifting.

figure
h=animatedline;
ax=gca;
ax.XGrid='on';
ax.YGrid='on';

%xp=[]; % use this for logging if testing
%yp=[];
t=GetSecs;
while (GetSecs-t)<10
    %a=round(read(joy),2); % Is rounding necessary to prevent drift?
    a=read(joy);
    x=a(1); y=a(2);
    %xp(end+1)=x;
    %yp(end+1)=y;
    addpoints(h,x,y);
    drawnow
end