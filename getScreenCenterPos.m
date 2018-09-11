function [X,Y] = getScreenCenterPos(screenCoords)

    centercoords = [(screenCoords(3)-screenCoords(1))/2, ...
                    (screenCoords(4)-screenCoords(2))/2 ];
    X = centercoords(1);
    Y = centercoords(2);
end
    
                       