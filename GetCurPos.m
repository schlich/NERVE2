function [curX,curY] = GetCurPos(cursorMatrix)
%GETCURPOS Returns x and y coordinates from the object's OpenGL modelview
%matrix.
%   Make sure the input is the correct matrix for the object. This is a
%   simple extraction and does not perform any checks.

curX = cursorMatrix(1,4);
curY = cursorMatrix(2,4);
end

