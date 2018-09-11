function collisionDetected = CheckCollision(targetX, targetY, cursorX, cursorY, targetRad, cursorRad, targetType)
%CheckCollision Check collision between cursor and target.
%   Sphere-sphere collision detection.
if nargin < 7
    targetType = 'sphere';
end
if ~strcmp(targetType, 'sphere')
    error('Only sphere-sphere collision is enabled.');
end

d = sqrt((cursorX-targetX)^2 + (cursorY-targetY)^2); % distance(cursor,target)

collisionDetected = (d < (cursorRad + targetRad));

% if d < (cursorRad + targetRad)
%     collisionDetected = 1;
% else
%     collisionDetected = 0;
% end

end

