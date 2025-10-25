import Toybox.Activity;
import Toybox.Position;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;

const DESIRED_SCALE_PIXEL_WIDTH as Float = 100.0f;
const DESIRED_ELEV_SCALE_PIXEL_WIDTH as Float = 50.0f;
// note sure why this has anything to do with DESIRED_SCALE_PIXEL_WIDTH, should just be whatever tile layer 0 equates to for the screen size
const MIN_SCALE as Float = DESIRED_SCALE_PIXEL_WIDTH / 1000000000.0f;

class BreadcrumbRenderer {
    // todo put into ui class
    var _clearRouteProgress as Number = 0;
    var _startCacheTilesProgress as Number = 0;
    var _enableMapProgress as Number = 0;
    var _disableMapProgress as Number = 0;
    var settings as Settings;
    var _cachedValues as CachedValues;
    var _crosshair as BitmapResource;
    var _nosmoking as BitmapResource;
    var _leftArrow as BitmapResource;
    var _rightArrow as BitmapResource;
    var _upArrow as BitmapResource;
    var _downArrow as BitmapResource;

    // units in mm (float/int) to label
    var SCALE_NAMES as Dictionary<Number, String> =
        ({
            1000 => "1m",
            5000 => "5m",
            10000 => "10m",
            20000 => "20m",
            30000 => "30m",
            40000 => "40m",
            50000 => "50m",
            100000 => "100m",
            250000 => "250m",
            500000 => "500m",
            1000000 => "1km",
            2000000 => "2km",
            3000000 => "3km",
            4000000 => "4km",
            5000000 => "5km",
            10000000 => "10km",
            20000000 => "20km",
            30000000 => "30km",
            40000000 => "40km",
            50000000 => "50km",
            100000000 => "100km",
            500000000 => "500km",
            1000000000 => "1000km",
            2000000000 => "2000km",
        }) as Dictionary<Number, String>;

    // yep the key of the array is in mm (they will never know, it will be our little secret)
    var SCALE_NAMES_IMPERIAL as Dictionary<Number, String> =
        ({
            1524 => "5ft",
            3048 => "10ft",
            7620 => "25ft",
            15240 => "50ft",
            30480 => "100ft",
            76200 => "250ft",
            152400 => "500ft",
            304800 => "1000ft",
            804672 => "0.5mi",
            1609344 => "1mi",
            3218688 => "2mi",
            8046720 => "5mi",
            16093440 => "10mi",
            32186880 => "20mi",
            80467200 => "50mi",
            160934400 => "100mi",
            804672000 => "500mi",
            1609344000 => "1000mi",
        }) as Dictionary<Number, String>;

    // we want much smaller elevation changes to be seen
    // so elevation scales are in mm, not meters
    var ELEVATION_SCALE_NAMES as Dictionary<Number, String> =
        ({
            // some rediculously small values for level ground (highly unlikely in the wild, but common on simulator)
            1 => "1mm",
            2 => "2mm",
            5 => "5mm",
            10 => "1cm",
            25 => "2.5cm",
            50 => "5cm",
            100 => "10cm",
            250 => "25cm",
            500 => "50cm",
            1000 => "1m",
            5000 => "5m",
            10000 => "10m",
            20000 => "20m",
            30000 => "30m",
            40000 => "40m",
            50000 => "50m",
            100000 => "100m",
            250000 => "250m",
            500000 => "500m",
        }) as Dictionary<Number, String>;

    // key is in mm
    var ELEVATION_SCALE_NAMES_IMPERIAL as Dictionary<Number, String> =
        ({
            25 => "1in",
            51 => "2in",
            127 => "5in",
            254 => "10in",
            305 => "1ft",
            1524 => "5ft",
            3048 => "10ft",
            6096 => "20ft",
            15240 => "50ft",
            30480 => "100ft",
            76200 => "250ft",
            152400 => "500ft",
            304800 => "1000ft",
        }) as Dictionary<Number, String>;

    // benchmark same track loaded (just render track no activity running) using
    // average time over 1min of benchmark
    // (just route means we always have a heap of points, and a small track does not bring the average down)
    // 13307us or 17718us - renderTrack manual code (rotateCos, rotateSin)
    // 15681us or 17338us or 11996us - renderTrack manual code (rotateCos, rotateSin)  - use local variables might be faster lookup?
    // 11162us or 18114us - rotateCos, rotateSin and hard code 180 as xhalf/yhalf
    // 22297us - renderTrack Graphics.AffineTransform

    function initialize(settings as Settings, cachedValues as CachedValues) {
        self.settings = settings;
        _cachedValues = cachedValues;
        _crosshair = WatchUi.loadResource(Rez.Drawables.Crosshair) as WatchUi.BitmapResource;
        _nosmoking = WatchUi.loadResource(Rez.Drawables.NoSmoking) as WatchUi.BitmapResource;
        _leftArrow = WatchUi.loadResource(Rez.Drawables.LeftArrow) as WatchUi.BitmapResource;
        _rightArrow = WatchUi.loadResource(Rez.Drawables.RightArrow) as WatchUi.BitmapResource;
        _upArrow = WatchUi.loadResource(Rez.Drawables.UpArrow) as WatchUi.BitmapResource;
        _downArrow = WatchUi.loadResource(Rez.Drawables.DownArrow) as WatchUi.BitmapResource;
    }

    function getScaleSizeGeneric(
        scale as Float,
        desiredWidth as Float,
        scaleNames as Dictionary<Number, String>
    ) as [Float, Number] {
        // get the closest without going over
        // keys loads them in random order, we want the smallest first
        var keys = scaleNames.keys();
        keys.sort(null);
        var foundDistanceKey = keys[0];
        var foundPixelWidth = 0f;
        for (var i = 0; i < keys.size(); ++i) {
            var distanceKey = keys[i] as Number;
            var testPixelWidth = (distanceKey.toFloat() / 1000) * scale;
            if (testPixelWidth > desiredWidth) {
                break;
            }

            foundPixelWidth = testPixelWidth;
            foundDistanceKey = distanceKey;
        }

        return [foundPixelWidth, foundDistanceKey];
    }

    function renderCurrentScale(dc as Dc) as Void {
        var scaleNames = settings.distanceImperialUnits ? SCALE_NAMES_IMPERIAL : SCALE_NAMES;
        var scaleData = getScaleSizeGeneric(
            _cachedValues.currentScale,
            DESIRED_SCALE_PIXEL_WIDTH,
            scaleNames
        );
        var pixelWidth = scaleData[0];
        var distanceM = scaleData[1];
        if (pixelWidth == 0f) {
            return;
        }

        var foundName = scaleNames[distanceM];

        var y = _cachedValues.physicalScreenHeight - 25;
        dc.setColor(settings.normalModeColour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(4);
        dc.drawLine(
            _cachedValues.xHalfPhysical - pixelWidth / 2.0f,
            y,
            _cachedValues.xHalfPhysical + pixelWidth / 2.0f,
            y
        );
        dc.drawText(
            _cachedValues.xHalfPhysical,
            y - 30,
            Graphics.FONT_XTINY,
            foundName,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    (:noUnbufferedRotations)
    function renderLineFromLastPointToRoute(
        dc as Dc,
        lastPoint as RectangularPoint,
        offTrackPoint as RectangularPoint,
        colour as Number
    ) as Void {}

    // points should already be scaled
    (:unbufferedRotations)
    function renderLineFromLastPointToRoute(
        dc as Dc,
        lastPoint as RectangularPoint,
        offTrackPoint as RectangularPoint,
        colour as Number
    ) as Void {
        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very confusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        var lastPointUnrotatedX = lastPoint.x - centerPosition.x;
        var lastPointUnrotatedY = lastPoint.y - centerPosition.y;
        var lastPointRotatedX =
            rotateAroundScreenXOffsetFactoredIn +
            rotateCos * lastPointUnrotatedX -
            rotateSin * lastPointUnrotatedY;
        var lastPointRotatedY =
            rotateAroundScreenYOffsetFactoredIn -
            (rotateSin * lastPointUnrotatedX + rotateCos * lastPointUnrotatedY);

        var offTrackPointUnrotatedX = offTrackPoint.x - centerPosition.x;
        var offTrackPointUnrotatedY = offTrackPoint.y - centerPosition.y;
        var offTrackPointRotatedX =
            rotateAroundScreenXOffsetFactoredIn +
            rotateCos * offTrackPointUnrotatedX -
            rotateSin * offTrackPointUnrotatedY;
        var offTrackPointRotatedY =
            rotateAroundScreenYOffsetFactoredIn -
            (rotateSin * offTrackPointUnrotatedX + rotateCos * offTrackPointUnrotatedY);

        dc.setPenWidth(4);
        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.drawLine(
            lastPointRotatedX,
            lastPointRotatedY,
            offTrackPointRotatedX,
            offTrackPointRotatedY
        );
    }

    function renderLineFromLastPointToRouteUnrotated(
        dc as Dc,
        lastPoint as RectangularPoint,
        offTrackPoint as RectangularPoint,
        colour as Number
    ) as Void {
        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very confusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        var lastPointUnrotatedX =
            rotateAroundScreenXOffsetFactoredIn + (lastPoint.x - centerPosition.x);
        var lastPointUnrotatedY =
            rotateAroundScreenYOffsetFactoredIn - (lastPoint.y - centerPosition.y);

        var offTrackPointUnrotatedX =
            rotateAroundScreenXOffsetFactoredIn + (offTrackPoint.x - centerPosition.x);
        var offTrackPointUnrotatedY =
            rotateAroundScreenYOffsetFactoredIn - (offTrackPoint.y - centerPosition.y);

        dc.setPenWidth(4);
        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.drawLine(
            lastPointUnrotatedX,
            lastPointUnrotatedY,
            offTrackPointUnrotatedX,
            offTrackPointUnrotatedY
        );
    }

    // last location should already be scaled
    function renderUser(dc as Dc, usersLastLocation as RectangularPoint) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster
        var rotateAroundScreenX = _cachedValues.rotateAroundScreenX; // local lookup faster
        var rotateAroundScreenY = _cachedValues.rotateAroundScreenY; // local lookup faster

        var userPosUnrotatedX = usersLastLocation.x - centerPosition.x;
        var userPosUnrotatedY = usersLastLocation.y - centerPosition.y;

        var userPosRotatedX = rotateAroundScreenX + userPosUnrotatedX;
        var userPosRotatedY = rotateAroundScreenY - userPosUnrotatedY;
        if (
            settings.renderMode == RENDER_MODE_BUFFERED_ROTATING ||
            settings.renderMode == RENDER_MODE_UNBUFFERED_ROTATING
        ) {
            userPosRotatedX =
                rotateAroundScreenX + rotateCos * userPosUnrotatedX - rotateSin * userPosUnrotatedY;
            userPosRotatedY =
                rotateAroundScreenY -
                (rotateSin * userPosUnrotatedX + rotateCos * userPosUnrotatedY);
        }

        var triangleSizeY = 10;
        var triangleSizeX = 4;
        var triangleTopX = userPosRotatedX;
        var triangleTopY = userPosRotatedY - triangleSizeY;

        var triangleLeftX = triangleTopX - triangleSizeX;
        var triangleLeftY = userPosRotatedY + triangleSizeY;

        var triangleRightX = triangleTopX + triangleSizeX;
        var triangleRightY = triangleLeftY;

        var triangleCenterX = userPosRotatedX;
        var triangleCenterY = userPosRotatedY;

        if (
            settings.renderMode != RENDER_MODE_BUFFERED_ROTATING &&
            settings.renderMode != RENDER_MODE_UNBUFFERED_ROTATING
        ) {
            // todo: load user arrow from bitmap and draw rotated instead
            // we normally rotate the track, but we now need to rotate the user
            var triangleTopXRot =
                triangleCenterX +
                rotateCos * (triangleTopX - triangleCenterX) -
                rotateSin * (triangleTopY - triangleCenterY);
            // yes + and not -, we are in pixel coordinates, the rest are in latitude which is negative at the bottom of the page
            triangleTopY =
                triangleCenterY +
                (rotateSin * (triangleTopX - triangleCenterX) +
                    rotateCos * (triangleTopY - triangleCenterY));
            triangleTopX = triangleTopXRot;

            var triangleLeftXRot =
                triangleCenterX +
                rotateCos * (triangleLeftX - triangleCenterX) -
                rotateSin * (triangleLeftY - triangleCenterY);
            // yes + and not -, we are in pixel coordinates, the rest are in latitude which is negative at the bottom of the page
            triangleLeftY =
                triangleCenterY +
                (rotateSin * (triangleLeftX - triangleCenterX) +
                    rotateCos * (triangleLeftY - triangleCenterY));
            triangleLeftX = triangleLeftXRot;

            var triangleRightXRot =
                triangleCenterX +
                rotateCos * (triangleRightX - triangleCenterX) -
                rotateSin * (triangleRightY - triangleCenterY);
            // yes + and not -, we are in pixel coordinates, the rest are in latitude which is negative at the bottom of the page
            triangleRightY =
                triangleCenterY +
                (rotateSin * (triangleRightX - triangleCenterX) +
                    rotateCos * (triangleRightY - triangleCenterY));
            triangleRightX = triangleRightXRot;
        }

        dc.setColor(settings.userColour, Graphics.COLOR_BLACK);
        dc.setPenWidth(6);
        dc.drawLine(triangleTopX, triangleTopY, triangleRightX, triangleRightY);
        dc.drawLine(triangleRightX, triangleRightY, triangleLeftX, triangleLeftY);
        dc.drawLine(triangleLeftX, triangleLeftY, triangleTopX, triangleTopY);
    }

    function renderTrackUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType,
        drawEndMarker as Boolean
    ) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very cofusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;

        // note: size is using the overload of points array (the reduced pointarray size)
        // but we draw from the raw points
        if (size >= ARRAY_POINT_SIZE * 2) {
            var firstXScaledAtCenter = coordinatesRaw[0] - centerPosition.x;
            var firstYScaledAtCenter = coordinatesRaw[1] - centerPosition.y;
            var firstX = rotateAroundScreenXOffsetFactoredIn + firstXScaledAtCenter;
            var firstY = rotateAroundScreenYOffsetFactoredIn - firstYScaledAtCenter;
            var lastX = firstX;
            var lastY = firstY;

            for (var i = ARRAY_POINT_SIZE; i < size; i += ARRAY_POINT_SIZE) {
                var nextX =
                    rotateAroundScreenXOffsetFactoredIn + (coordinatesRaw[i] - centerPosition.x);
                var nextY =
                    rotateAroundScreenYOffsetFactoredIn -
                    (coordinatesRaw[i + 1] - centerPosition.y);

                dc.drawLine(lastX, lastY, nextX, nextY);

                lastX = nextX;
                lastY = nextY;
            }

            renderStartAndEnd(dc, firstX, firstY, lastX, lastY, drawEndMarker);
        }
    }

    (:noShowPoints)
    function renderTrackPointsUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        unsupported(dc, "show points");
    }

    (:showPoints)
    function renderTrackPointsUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very cofusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;

        for (var i = 0; i < size; i += ARRAY_POINT_SIZE) {
            var nextX = coordinatesRaw[i];
            var nextY = coordinatesRaw[i + 1];
            var x = rotateAroundScreenXOffsetFactoredIn + (nextX - centerPosition.x);
            var y = rotateAroundScreenYOffsetFactoredIn - (nextY - centerPosition.y);

            dc.fillCircle(x, y, 5);
            // if ((i / ARRAY_POINT_SIZE) < 20 && breadcrumb.storageIndex != TRACK_ID) {
            //     dc.drawText(
            //         x,
            //         y,
            //         Graphics.FONT_XTINY,
            //         "" + i / ARRAY_POINT_SIZE,
            //         Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            //     );
            // }
        }
    }

    (:showTurnAlertPoints)
    function getTurnAlertDistancePx() as Float {
        var currentSpeedPPS = 1f; // assume a slow walk if we cannot get the current speed
        var info = Activity.getActivityInfo();
        if (info != null && info.currentSpeed != null) {
            currentSpeedPPS = info.currentSpeed as Float;
        }

        // it's in meters before this point then switches to pixels per second
        if (_cachedValues.currentScale != 0f) {
            currentSpeedPPS *= _cachedValues.currentScale;
        }

        return turnAlertDistancePx(
            currentSpeedPPS,
            settings.turnAlertTimeS,
            settings.minTurnAlertDistanceM,
            _cachedValues.currentScale
        );
    }

    (:noShowTurnAlertPoints)
    function renderTrackDirectionPointsUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        unsupported(dc, "show turn points");
    }

    (:showTurnAlertPoints)
    function renderTrackDirectionPointsUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster
        var distance = getTurnAlertDistancePx();

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very confusing seeing the routes disappear when scrolling
            // and it makes sense to want to scroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        var size = breadcrumb.directions.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;
        var directionsRaw = breadcrumb.directions._internalArrayBuffer;

        for (var i = 0; i < size; ++i) {
            var directionRaw = directionsRaw[i];
            var coordsIndex = directionRaw & 0xffff;
            // blind trust that the phone app sent the correct data and we are not accessing out of bounds array access
            var pixelX = coordinatesRaw[coordsIndex * ARRAY_POINT_SIZE];
            var pixelY = coordinatesRaw[coordsIndex * ARRAY_POINT_SIZE + 1];
            var x = rotateAroundScreenXOffsetFactoredIn + (pixelX - centerPosition.x);
            var y = rotateAroundScreenYOffsetFactoredIn - (pixelY - centerPosition.y);

            dc.drawCircle(x, y, distance);
            // if the route comes back through the same intersection directions often overlap each other so this can be confusing
            if (i < settings.showDirectionPointTextUnderIndex) {
                var angle = ((directionRaw & 0xffff0000) >> 16) - 180;
                dc.drawText(
                    x,
                    y,
                    Graphics.FONT_XTINY,
                    "" + coordsIndex + "\n" + angle,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }
    }

    const CHEVRON_SPREAD_RADIANS = 0.75;
    const CHEVRON_ARM_LENGTH = 15;
    const CHEVRON_POINTS = 6; // the last point is not counted, as we only use it to get the line angle, number of cheverons = CHEVRON_POINTS - 1

    function drawCheveron(
        dc as Dc,
        lastX as Float,
        lastY as Float,
        nextX as Float,
        nextY as Float
    ) as Void {
        var dx = nextX - lastX;
        var dy = nextY - lastY;

        var segmentAngle = Math.atan2(dy, dx);

        // Calculate angles for the two arms (pointing backward from the tip)
        // Base direction for arms is opposite to segment direction
        var baseArmAngle = segmentAngle + Math.PI;

        var angleArm1 = baseArmAngle - CHEVRON_SPREAD_RADIANS;
        var angleArm2 = baseArmAngle + CHEVRON_SPREAD_RADIANS;

        // Calculate endpoints of the chevron arms
        var arm1EndX = lastX + CHEVRON_ARM_LENGTH * Math.cos(angleArm1);
        var arm1EndY = lastY + CHEVRON_ARM_LENGTH * Math.sin(angleArm1);

        var arm2EndX = lastX + CHEVRON_ARM_LENGTH * Math.cos(angleArm2);
        var arm2EndY = lastY + CHEVRON_ARM_LENGTH * Math.sin(angleArm2);

        // Draw the chevron
        dc.drawLine(lastX, lastY, arm1EndX, arm1EndY);
        dc.drawLine(lastX, lastY, arm2EndX, arm2EndY);
    }

    function renderTrackCheverons(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        var lastClosePointIndex = breadcrumb.lastClosePointIndex;
        if (lastClosePointIndex == null) {
            // we have never seen the track, cheverons only extend out from the users last point on the track
            // this means off track alerts must be enabled too
            return;
        }

        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very confusing seeing the routes disappear when scrolling
            // and it makes sense to want to scroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;

        var nextClosePointIndexRaw = lastClosePointIndex * ARRAY_POINT_SIZE + ARRAY_POINT_SIZE;
        if (nextClosePointIndexRaw < size - ARRAY_POINT_SIZE) {
            var firstXScaledAtCenter = coordinatesRaw[nextClosePointIndexRaw] - centerPosition.x;
            var firstYScaledAtCenter =
                coordinatesRaw[nextClosePointIndexRaw + 1] - centerPosition.y;
            var firstXRotated =
                rotateAroundScreenXOffsetFactoredIn +
                rotateCos * firstXScaledAtCenter -
                rotateSin * firstYScaledAtCenter;
            var firstYRotated =
                rotateAroundScreenYOffsetFactoredIn -
                (rotateSin * firstXScaledAtCenter + rotateCos * firstYScaledAtCenter);
            var lastXRotated = firstXRotated;
            var lastYRotated = firstYRotated;

            for (
                var i = nextClosePointIndexRaw + ARRAY_POINT_SIZE;
                i < size && i <= nextClosePointIndexRaw + CHEVRON_POINTS * ARRAY_POINT_SIZE;
                i += ARRAY_POINT_SIZE
            ) {
                var nextX = coordinatesRaw[i];
                var nextY = coordinatesRaw[i + 1];

                var nextXScaledAtCenter = nextX - centerPosition.x;
                var nextYScaledAtCenter = nextY - centerPosition.y;

                var nextXRotated =
                    rotateAroundScreenXOffsetFactoredIn +
                    rotateCos * nextXScaledAtCenter -
                    rotateSin * nextYScaledAtCenter;
                var nextYRotated =
                    rotateAroundScreenYOffsetFactoredIn -
                    (rotateSin * nextXScaledAtCenter + rotateCos * nextYScaledAtCenter);

                drawCheveron(dc, lastXRotated, lastYRotated, nextXRotated, nextYRotated);

                lastXRotated = nextXRotated;
                lastYRotated = nextYRotated;
            }
        }
    }

    // function name is to keep consistency with other methods, the chverons themselves will be rotated
    (:noUnbufferedRotations)
    function renderTrackCheveronsUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {}
    (:unbufferedRotations)
    function renderTrackCheveronsUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        var lastClosePointIndex = breadcrumb.lastClosePointIndex;
        if (lastClosePointIndex == null) {
            // we have never seen the track, cheverons only extend out from the users last point on the track
            // this means off track alerts must be enabled too
            return;
        }

        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very cofusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;

        var nextClosePointIndexRaw = lastClosePointIndex * ARRAY_POINT_SIZE + ARRAY_POINT_SIZE;
        if (nextClosePointIndexRaw < size - ARRAY_POINT_SIZE) {
            var lastX =
                rotateAroundScreenXOffsetFactoredIn +
                coordinatesRaw[nextClosePointIndexRaw] -
                centerPosition.x;
            var lastY =
                rotateAroundScreenYOffsetFactoredIn -
                coordinatesRaw[nextClosePointIndexRaw + 1] -
                centerPosition.y;

            for (
                var i = nextClosePointIndexRaw + ARRAY_POINT_SIZE;
                i < size && i <= nextClosePointIndexRaw + CHEVRON_POINTS * ARRAY_POINT_SIZE;
                i += ARRAY_POINT_SIZE
            ) {
                var nextX =
                    rotateAroundScreenXOffsetFactoredIn + (coordinatesRaw[i] - centerPosition.x);
                var nextY =
                    rotateAroundScreenYOffsetFactoredIn -
                    (coordinatesRaw[i + 1] - centerPosition.y);

                drawCheveron(dc, lastX, lastY, nextX, nextY);

                lastX = nextX;
                lastY = nextY;
            }
        }
    }

    (:noUnbufferedRotations)
    function renderTrackName(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {}

    (:unbufferedRotations)
    function renderTrackName(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster

        var xScaledAtCenter = breadcrumb.boundingBoxCenter.x - centerPosition.x;
        var yScaledAtCenter = breadcrumb.boundingBoxCenter.y - centerPosition.y;

        var x =
            rotateAroundScreenXOffsetFactoredIn +
            rotateCos * xScaledAtCenter -
            rotateSin * yScaledAtCenter;
        var y =
            rotateAroundScreenYOffsetFactoredIn -
            (rotateSin * xScaledAtCenter + rotateCos * yScaledAtCenter);
        dc.drawText(
            x,
            y,
            Graphics.FONT_XTINY,
            settings.routeName(breadcrumb.storageIndex),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    function renderTrackNameUnrotated(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        var xScaledAtCenter = breadcrumb.boundingBoxCenter.x - centerPosition.x;
        var yScaledAtCenter = breadcrumb.boundingBoxCenter.y - centerPosition.y;

        var x = rotateAroundScreenXOffsetFactoredIn + xScaledAtCenter;
        var y = rotateAroundScreenYOffsetFactoredIn - yScaledAtCenter;

        dc.drawText(
            x,
            y,
            Graphics.FONT_XTINY,
            settings.routeName(breadcrumb.storageIndex),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    (:noUnbufferedRotations)
    function renderTrack(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType,
        drawEndMarker as Boolean
    ) as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.clear();

        dc.drawText(
            xHalfPhysical,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            "RENDER MODE\nNOT SUPPORTED",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );
    }

    (:unbufferedRotations)
    function renderTrack(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType,
        drawEndMarker as Boolean
    ) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very cofusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);
        dc.setPenWidth(4);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;

        // note: size is using the overload of points array (the reduced pointarray size)
        // but we draw from the raw points
        if (size >= ARRAY_POINT_SIZE * 2) {
            var firstXScaledAtCenter = coordinatesRaw[0] - centerPosition.x;
            var firstYScaledAtCenter = coordinatesRaw[1] - centerPosition.y;
            var firstXRotated =
                rotateAroundScreenXOffsetFactoredIn +
                rotateCos * firstXScaledAtCenter -
                rotateSin * firstYScaledAtCenter;
            var firstYRotated =
                rotateAroundScreenYOffsetFactoredIn -
                (rotateSin * firstXScaledAtCenter + rotateCos * firstYScaledAtCenter);
            var lastXRotated = firstXRotated;
            var lastYRotated = firstYRotated;

            for (var i = ARRAY_POINT_SIZE; i < size; i += ARRAY_POINT_SIZE) {
                var nextX = coordinatesRaw[i];
                var nextY = coordinatesRaw[i + 1];

                var nextXScaledAtCenter = nextX - centerPosition.x;
                var nextYScaledAtCenter = nextY - centerPosition.y;

                var nextXRotated =
                    rotateAroundScreenXOffsetFactoredIn +
                    rotateCos * nextXScaledAtCenter -
                    rotateSin * nextYScaledAtCenter;
                var nextYRotated =
                    rotateAroundScreenYOffsetFactoredIn -
                    (rotateSin * nextXScaledAtCenter + rotateCos * nextYScaledAtCenter);

                dc.drawLine(lastXRotated, lastYRotated, nextXRotated, nextYRotated);

                lastXRotated = nextXRotated;
                lastYRotated = nextYRotated;
            }

            renderStartAndEnd(
                dc,
                firstXRotated,
                firstYRotated,
                lastXRotated,
                lastYRotated,
                drawEndMarker
            );
        }
    }

    (:noUnbufferedRotations)
    function renderTrackPoints(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {}

    (:unbufferedRotations,:noShowPoints)
    function renderTrackPoints(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        unsupported(dc, "show points");
    }

    (:unbufferedRotations,:showPoints)
    function renderTrackPoints(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very cofusing seeing the routes disappear when scrolling
            // and it makes sense to want to sroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_BLACK);

        var size = breadcrumb.coordinates.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;
        for (var i = 0; i < size; i += ARRAY_POINT_SIZE) {
            var nextX = coordinatesRaw[i];
            var nextY = coordinatesRaw[i + 1];

            var nextXScaledAtCenter = nextX - centerPosition.x;
            var nextYScaledAtCenter = nextY - centerPosition.y;

            var x =
                rotateAroundScreenXOffsetFactoredIn +
                rotateCos * nextXScaledAtCenter -
                rotateSin * nextYScaledAtCenter;
            var y =
                rotateAroundScreenYOffsetFactoredIn -
                (rotateSin * nextXScaledAtCenter + rotateCos * nextYScaledAtCenter);

            dc.fillCircle(x, y, 5);
        }
    }

    (:noUnbufferedRotations)
    function renderTrackDirectionPoints(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {}

    (:unbufferedRotations,:noShowTurnAlertPoints)
    function renderTrackDirectionPoints(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        unsupported(dc, "show turn points");
    }

    (:unbufferedRotations,:showTurnAlertPoints)
    function renderTrackDirectionPoints(
        dc as Dc,
        breadcrumb as BreadcrumbTrack,
        colour as Graphics.ColorType
    ) as Void {
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var rotateCos = _cachedValues.rotateCos; // local lookup faster
        var rotateSin = _cachedValues.rotateSin; // local lookup faster
        var rotateAroundScreenXOffsetFactoredIn = _cachedValues.rotateAroundScreenXOffsetFactoredIn; // local lookup faster
        var rotateAroundScreenYOffsetFactoredIn = _cachedValues.rotateAroundScreenYOffsetFactoredIn; // local lookup faster
        var distance = getTurnAlertDistancePx();

        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            // its very confusing seeing the routes disappear when scrolling
            // and it makes sense to want to scroll around the route too
            return;
        }

        dc.setColor(colour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);

        var size = breadcrumb.directions.size();
        var coordinatesRaw = breadcrumb.coordinates._internalArrayBuffer;
        var directionsRaw = breadcrumb.directions._internalArrayBuffer;

        for (var i = 0; i < size; ++i) {
            var directionRaw = directionsRaw[i];
            var coordsIndex = directionRaw & 0xffff;
            // blind trust that the phone app sent the correct data and we are not accessing out of bounds array access
            var nextX = coordinatesRaw[coordsIndex * ARRAY_POINT_SIZE];
            var nextY = coordinatesRaw[coordsIndex * ARRAY_POINT_SIZE + 1];

            var nextXScaledAtCenter = nextX - centerPosition.x;
            var nextYScaledAtCenter = nextY - centerPosition.y;

            var x =
                rotateAroundScreenXOffsetFactoredIn +
                rotateCos * nextXScaledAtCenter -
                rotateSin * nextYScaledAtCenter;
            var y =
                rotateAroundScreenYOffsetFactoredIn -
                (rotateSin * nextXScaledAtCenter + rotateCos * nextYScaledAtCenter);

            dc.drawCircle(x, y, distance);
            // if the route comes back through the same intersection directions often overlap each other so this can be confusing
            if (i < settings.showDirectionPointTextUnderIndex) {
                var angle = ((directionRaw & 0xffff0000) >> 16) - 180;
                dc.drawText(
                    x,
                    y,
                    Graphics.FONT_XTINY,
                    "" + coordsIndex + "\n" + angle,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
                );
            }
        }
    }

    function renderStartAndEnd(
        dc as Dc,
        firstX as Float,
        firstY as Float,
        lastX as Float,
        lastY as Float,
        drawEndMarker as Boolean
    ) as Void {
        // todo let user configure these, or render icons instead
        // could add a start play button and a finnish flag (not Finland's flag, the checkered kind)
        var squareSize = 10;
        var squareHalf = squareSize / 2;
        dc.setColor(Graphics.COLOR_GREEN, Graphics.COLOR_BLACK);
        dc.fillRectangle(firstX - squareHalf, firstY - squareHalf, squareSize, squareSize);
        if (drawEndMarker) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
            dc.fillRectangle(lastX - squareHalf, lastY - squareHalf, squareSize, squareSize);
        }
    }

    (:noStorage)
    function renderTileSeedUi(dc as Dc) as Boolean {
        // no point adding render message, its never supported
        return false;
    }
    (:storage)
    function renderTileSeedUi(dc as Dc) as Boolean {
        if (
            renderLeftStartConfirmation(
                dc,
                _startCacheTilesProgress,
                Rez.Strings.startTileCache1,
                Rez.Strings.startTileCache2,
                Rez.Strings.startTileCache3
            )
        ) {
            return true;
        }

        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        if (!_cachedValues.seeding()) {
            // not seeding, no ui
            return false;
        }

        var breadcrumbContext = getApp()._breadcrumbContext;
        dc.setColor(settings.uiColour, Graphics.COLOR_BLACK);
        dc.clear();

        var lineLength = 20;
        var halfLineLength = lineLength / 2;
        var lineFromEdge = 10;

        var seedingProgress = _cachedValues.seedingProgress();
        var overallProgress = seedingProgress[1];
        // --- Draw Circular Progress Bar ---
        var progressBarRadius =
            (dc.getWidth() < dc.getHeight() ? dc.getWidth() : dc.getHeight()) / 2 - 5;
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(10);
        dc.drawArc(
            xHalfPhysical,
            yHalfPhysical,
            progressBarRadius,
            Graphics.ARC_CLOCKWISE,
            90,
            90 - (360 * overallProgress).toNumber()
        );

        // Information text on top of progress bar
        dc.setColor(settings.uiColour, Graphics.COLOR_TRANSPARENT);
        var pagesStr = "\nPages: ";
        for (var i = 0; i < breadcrumbContext.tileCache._storageTileCache._pageSizes.size(); i++) {
            if (i != 0) {
                pagesStr += ", ";
            }
            pagesStr += breadcrumbContext.tileCache._storageTileCache._pageSizes[i];
        }
        var tileLayerStr =
            _cachedValues.seedingZ < 0
                ? "Finalising"
                : "Caching Tile Layer " + _cachedValues.seedingZ;
        dc.drawText(
            xHalfPhysical,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            tileLayerStr +
                "\n" +
                seedingProgress[0] +
                "\nPending Web: " +
                breadcrumbContext.webRequestHandler.pending.size() +
                " Running: " +
                breadcrumbContext.webRequestHandler._outstandingCount +
                "\n Storage: " +
                breadcrumbContext.tileCache._storageTileCache._totalTileCount +
                "/" +
                settings.storageTileCacheSize +
                pagesStr +
                "\nWeb Error: " +
                breadcrumbContext.webRequestHandler._errorCount +
                " Web Ok: " +
                breadcrumbContext.webRequestHandler._successCount +
                "\nMem: " +
                (System.getSystemStats().usedMemory / 1024f).format("%.1f") +
                "K f: " +
                (System.getSystemStats().freeMemory / 1024f).format("%.1f") +
                "K" +
                "\nLast Web Res: " +
                breadcrumbContext.webRequestHandler._lastResult,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        // cross at the top of the screen to cancel download
        // could just do this with an X? but that looks a bit weird
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(8);
        dc.drawLine(
            xHalfPhysical - halfLineLength,
            lineFromEdge,
            xHalfPhysical + halfLineLength,
            lineFromEdge + lineLength
        );
        dc.drawLine(
            xHalfPhysical - halfLineLength,
            lineFromEdge + lineLength,
            xHalfPhysical + halfLineLength,
            lineFromEdge
        );

        return true;
    }

    function renderMapEnable(dc as Dc) as Boolean {
        return renderLeftStartConfirmation(
            dc,
            _enableMapProgress,
            Rez.Strings.enableMaps1,
            Rez.Strings.enableMaps2,
            Rez.Strings.enableMaps3
        );
    }

    function renderMapDisable(dc as Dc) as Boolean {
        return renderLeftStartConfirmation(
            dc,
            _disableMapProgress,
            Rez.Strings.disableMaps1,
            Rez.Strings.disableMaps2,
            Rez.Strings.disableMaps3
        );
    }

    function renderYNUi(
        dc as Dc,
        text as ResourceId,
        leftText as String,
        rightText as String,
        leftColour as Number,
        rightColour as Number
    ) as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster
        var physicalScreenHeight = _cachedValues.physicalScreenHeight; // local lookup faster
        var physicalScreenWidth = _cachedValues.physicalScreenWidth; // local lookup faster
        var padding = xHalfPhysical / 2.0f;
        var topText = yHalfPhysical / 2.0f;

        dc.setColor(leftColour, leftColour);
        dc.fillRectangle(0, 0, xHalfPhysical, physicalScreenHeight);
        dc.setColor(rightColour, rightColour);
        dc.fillRectangle(xHalfPhysical, 0, xHalfPhysical, physicalScreenHeight);

        var textArea = new WatchUi.TextArea({
            :text => text,
            :color => settings.uiColour,
            :font => [Graphics.FONT_XTINY],
            :justification => Graphics.TEXT_JUSTIFY_CENTER,
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => topText,
            :width => physicalScreenWidth * 0.8f, // round devices cannot show text at top of screen
            :height => xHalfPhysical,
        });
        textArea.draw(dc);

        dc.setColor(settings.uiColour, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            xHalfPhysical - padding,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            leftText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
        dc.drawText(
            xHalfPhysical + padding,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            rightText,
            Graphics.TEXT_JUSTIFY_CENTER
        );
    }

    function renderLeftStartConfirmation(
        dc as Dc,
        variable as Number,
        text1 as ResourceId,
        text2 as ResourceId,
        text3 as ResourceId
    ) as Boolean {
        switch (variable) {
            case 0:
                break;
            case 1:
            case 3: {
                // press left to confirm, right cancels
                renderYNUi(
                    dc as Dc,
                    variable == 1 ? text1 : text3,
                    "Y",
                    "N",
                    Graphics.COLOR_GREEN,
                    Graphics.COLOR_RED
                );
                return true;
            }
            case 2: {
                // press left to confirm, right cancels
                renderYNUi(dc as Dc, text2, "N", "Y", Graphics.COLOR_RED, Graphics.COLOR_GREEN);
                return true;
            }
        }

        return false;
    }

    function renderClearTrackUi(dc as Dc) as Boolean {
        switch (_clearRouteProgress) {
            case 0:
                break;
            case 1:
            case 3: {
                // press right to confirm, left cancels
                renderYNUi(
                    dc as Dc,
                    _clearRouteProgress == 1 ? Rez.Strings.clearRoutes1 : Rez.Strings.clearRoutes3,
                    "N",
                    "Y",
                    Graphics.COLOR_RED,
                    Graphics.COLOR_GREEN
                );
                return true;
            }
            case 2: {
                // press left to confirm, right cancels
                renderYNUi(
                    dc as Dc,
                    Rez.Strings.clearRoutes2,
                    "Y",
                    "N",
                    Graphics.COLOR_GREEN,
                    Graphics.COLOR_RED
                );
                return true;
            }
        }

        return false;
    }

    (:noStorage)
    function renderTileCacheButton(dc as Dc) as Void {}
    (:storage)
    function renderTileCacheButton(dc as Dc) as Void {
        var physicalScreenWidth = _cachedValues.physicalScreenWidth; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        if (settings.storageMapTilesOnly || settings.cacheTilesInStorage) {
            // right of screen
            dc.drawText(
                physicalScreenWidth - halfHitboxSize,
                yHalfPhysical,
                Graphics.FONT_XTINY,
                "G",
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    (:noDrawHitBoxes)
    function drawHitBoxes(
        dc as Dc,
        physicalScreenWidth as Float,
        physicalScreenHeight as Float
    ) as Void {
        unsupported(dc, "draw hit boxes");
    }

    (:drawHitBoxes)
    function drawHitBoxes(
        dc as Dc,
        physicalScreenWidth as Float,
        physicalScreenHeight as Float
    ) as Void {
        dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawRectangle(
            clearRouteX - halfHitboxSize,
            clearRouteY - halfHitboxSize,
            hitboxSize,
            hitboxSize
        );
        dc.drawRectangle(
            modeSelectX - halfHitboxSize,
            modeSelectY - halfHitboxSize,
            hitboxSize,
            hitboxSize
        );
        dc.drawRectangle(
            returnToUserX - halfHitboxSize,
            returnToUserY - halfHitboxSize,
            hitboxSize,
            hitboxSize
        );
        dc.drawRectangle(
            mapEnabledX - halfHitboxSize,
            mapEnabledY - halfHitboxSize,
            hitboxSize,
            hitboxSize
        );

        // top bottom left right
        dc.setColor(Graphics.COLOR_BLUE, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(0, hitboxSize, physicalScreenWidth, hitboxSize);
        dc.drawLine(
            0,
            physicalScreenHeight - hitboxSize,
            physicalScreenWidth,
            physicalScreenHeight - hitboxSize
        );
        dc.drawLine(hitboxSize, 0, hitboxSize, physicalScreenHeight);
        dc.drawLine(
            physicalScreenWidth - hitboxSize,
            0,
            physicalScreenWidth - hitboxSize,
            physicalScreenHeight
        );
    }

    function renderUi(dc as Dc) as Void {
        var currentScale = _cachedValues.currentScale; // local lookup faster
        var centerPosition = _cachedValues.centerPosition; // local lookup faster
        var physicalScreenWidth = _cachedValues.physicalScreenWidth; // local lookup faster
        var physicalScreenHeight = _cachedValues.physicalScreenHeight; // local lookup faster
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        if (settings.drawHitBoxes) {
            drawHitBoxes(dc, physicalScreenWidth, physicalScreenHeight);
        }

        dc.setColor(settings.uiColour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        // current mode displayed
        var modeLetter = "T";
        switch (settings.mode) {
            case MODE_NORMAL:
                modeLetter = "T";
                break;
            case MODE_ELEVATION:
                modeLetter = "E";
                break;
            case MODE_MAP_MOVE:
                modeLetter = "M";
                break;
            case MODE_DEBUG:
                modeLetter = "D";
                break;
        }

        dc.drawText(
            modeSelectX,
            modeSelectY,
            Graphics.FONT_XTINY,
            modeLetter,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        if (settings.mode == MODE_DEBUG) {
            // mode button is the only thing to show
            return;
        }

        // clear routes
        dc.drawText(
            clearRouteX,
            clearRouteY,
            Graphics.FONT_XTINY,
            "C",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        if (settings.mode == MODE_ELEVATION) {
            return;
        }

        if (settings.mode != MODE_MAP_MOVE) {
            // do not allow disabling maps from mapmove mode
            var mapletter = "Y";
            if (!settings.mapEnabled) {
                mapletter = "N";
            }
            dc.drawText(
                mapEnabledX,
                mapEnabledY,
                Graphics.FONT_XTINY,
                mapletter,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }

        // make this a const
        var halfLineLength = 10;
        var lineFromEdge = 10;
        var scaleFromEdge = 75; // guestimate

        if (_cachedValues.fixedPosition != null || _cachedValues.scale != null) {
            try {
                dc.drawBitmap2(
                    returnToUserX - _crosshair.getWidth() / 2,
                    returnToUserY - _crosshair.getHeight() / 2,
                    _crosshair,
                    {
                        :tintColor => settings.uiColour,
                    }
                );
            } catch (e) {
                // not sure what this exception was see above
                var message = e.getErrorMessage();
                logE("failed drawBitmap2 (render ui): " + message);
                ++$.globalExceptionCounter;
                incNativeColourFormatErrorIfMessageMatches(message);
            }
        }

        if (settings.displayLatLong) {
            var fixedLatitude = settings.fixedLatitude;
            var fixedLongitude = settings.fixedLongitude;
            if (
                _cachedValues.fixedPosition != null &&
                fixedLatitude != null &&
                fixedLongitude != null
            ) {
                var txt = fixedLatitude.format("%.3f") + ", " + fixedLongitude.format("%.3f");
                dc.drawText(
                    xHalfPhysical,
                    physicalScreenHeight - scaleFromEdge,
                    Graphics.FONT_XTINY,
                    txt,
                    Graphics.TEXT_JUSTIFY_CENTER
                );
            } else if (currentScale != 0f) {
                var latLong = RectangularPoint.xyToLatLon(
                    centerPosition.x / currentScale,
                    centerPosition.y / currentScale
                );
                if (latLong != null) {
                    var txt = latLong[0].format("%.3f") + ", " + latLong[1].format("%.3f");
                    dc.drawText(
                        xHalfPhysical,
                        physicalScreenHeight - scaleFromEdge,
                        Graphics.FONT_XTINY,
                        txt,
                        Graphics.TEXT_JUSTIFY_CENTER
                    );
                }
            }
        }

        if (settings.mode == MODE_MAP_MOVE) {
            try {
                dc.drawBitmap2(0, yHalfPhysical - _leftArrow.getHeight() / 2, _leftArrow, {
                    :tintColor => settings.uiColour,
                });
                dc.drawBitmap2(
                    physicalScreenWidth - _rightArrow.getWidth(),
                    yHalfPhysical - _rightArrow.getHeight() / 2,
                    _rightArrow,
                    {
                        :tintColor => settings.uiColour,
                    }
                );
                dc.drawBitmap2(xHalfPhysical - _upArrow.getWidth() / 2, 0, _upArrow, {
                    :tintColor => settings.uiColour,
                });
                if (settings.getAttribution() == null || !settings.mapEnabled) {
                    dc.drawBitmap2(
                        xHalfPhysical - _downArrow.getWidth() / 2,
                        physicalScreenHeight - _downArrow.getHeight(),
                        _downArrow,
                        {
                            :tintColor => settings.uiColour,
                        }
                    );
                }
            } catch (e) {
                // not sure what this exception was see above
                var message = e.getErrorMessage();
                logE("failed drawBitmap2 (render ui 2): " + message);
                ++$.globalExceptionCounter;
                incNativeColourFormatErrorIfMessageMatches(message);
            }
            return;
        }

        // plus at the top of screen
        if (!_cachedValues.scaleCanInc) {
            dc.drawBitmap2(xHalfPhysical - _nosmoking.getWidth() / 2, 0, _nosmoking, {
                :tintColor => settings.uiColour,
            });
        } else {
            dc.drawLine(
                xHalfPhysical - halfLineLength,
                lineFromEdge,
                xHalfPhysical + halfLineLength,
                lineFromEdge
            );
            dc.drawLine(
                xHalfPhysical,
                lineFromEdge - halfLineLength,
                xHalfPhysical,
                lineFromEdge + halfLineLength
            );
        }

        if (settings.getAttribution() == null || !settings.mapEnabled) {
            // minus at the bottom
            if (!_cachedValues.scaleCanDec) {
                dc.drawBitmap2(
                    xHalfPhysical - _nosmoking.getWidth() / 2,
                    physicalScreenHeight - _nosmoking.getHeight() - 3, // small padding for physcial device clipping
                    _nosmoking,
                    {
                        :tintColor => settings.uiColour,
                    }
                );
            } else {
                dc.drawLine(
                    xHalfPhysical - halfLineLength,
                    physicalScreenHeight - lineFromEdge,
                    xHalfPhysical + halfLineLength,
                    physicalScreenHeight - lineFromEdge
                );
            }
        }

        // M - default, moving is zoomed view, stopped if full view
        // S - stopped is zoomed view, moving is entire view
        var fvText = "M";
        // dirty hack, should pass the bool in another way
        // ui should be its own class, as should states
        if (settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_STOPPED) {
            // zoom view
            fvText = "S";
        }
        if (settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_NEVER_ZOOM) {
            // zoom view
            fvText = "N";
        }
        if (settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_ALWAYS_ZOOM) {
            // zoom view
            fvText = "A";
        }
        if (settings.zoomAtPaceMode == ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK) {
            // zoom view
            fvText = "R";
        }
        dc.drawText(
            halfHitboxSize,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            fvText,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
        );

        if (settings.mapEnabled) {
            renderTileCacheButton(dc);
        }
    }

    function getScaleDecIncAmount(direction as Number) as Float {
        var scale = _cachedValues.scale;
        if (scale == null) {
            // wtf we never call this when its null
            return 0f;
        }

        if (settings.scaleRestrictedToTileLayers() && settings.mapEnabled) {
            var desiredScale = _cachedValues.nextTileLayerScale(direction);
            var toInc = desiredScale - scale;
            return toInc;
        }

        var scaleNames = settings.distanceImperialUnits ? SCALE_NAMES_IMPERIAL : SCALE_NAMES;
        var scaleData = getScaleSizeGeneric(
            _cachedValues.currentScale,
            DESIRED_SCALE_PIXEL_WIDTH,
            scaleNames
        );
        var iInc = direction;
        var currentDistanceM = scaleData[1];
        var keys = scaleNames.keys();
        keys.sort(null);
        for (var i = 0; i < keys.size(); ++i) {
            var distanceM = keys[i];
            if (currentDistanceM == distanceM) {
                var nextScaleIndex = i - iInc;
                if (nextScaleIndex >= keys.size()) {
                    nextScaleIndex = keys.size() - 1;
                }

                if (nextScaleIndex < 0) {
                    nextScaleIndex = 0;
                }

                // we want the result to be
                var nextDistanceM = keys[nextScaleIndex] / (1000f as Float);
                // -2 since we need some fudge factor to make sure we are very close to desired length, but not past it
                var desiredScale = (DESIRED_SCALE_PIXEL_WIDTH - 2) / nextDistanceM;
                var toInc = desiredScale - scale;
                return toInc;
            }
        }

        return direction * MIN_SCALE;
    }

    function incScale() as Void {
        if (settings.mode != MODE_NORMAL) {
            return;
        }

        if (_cachedValues.scale == null) {
            _cachedValues.setScale(_cachedValues.currentScale);
        }
        var scale = _cachedValues.scale;
        if (scale == null) {
            // wtf we just set it?
            return;
        }

        _cachedValues.setScale(scale + getScaleDecIncAmount(1));
        _cachedValues.scaleCanDec = true; // we can zoom out again
        _cachedValues.scaleCanInc = getScaleDecIncAmount(1) != 0f; // get the next inc amount so that it does not require one extra click
    }

    function decScale() as Void {
        if (settings.mode != MODE_NORMAL) {
            return;
        }

        if (_cachedValues.scale == null) {
            _cachedValues.setScale(_cachedValues.currentScale);
        }
        var scale = _cachedValues.scale;
        if (scale == null) {
            // wtf we just set it?
            return;
        }
        _cachedValues.setScale(scale + getScaleDecIncAmount(-1));
        _cachedValues.scaleCanInc = true; // we can zoom in again
        _cachedValues.scaleCanDec = getScaleDecIncAmount(-1) != 0f; // get the next dec amount so that it does not require one extra click

        // prevent negative values (dont think this ever gets hit, since we caluclate off of the predefined scales)
        if (scale <= 0f) {
            _cachedValues.setScale(MIN_SCALE);
            _cachedValues.scaleCanInc = true; // we can zoom in again
            _cachedValues.scaleCanDec = getScaleDecIncAmount(-1) != 0f; // get the next dec amount so that it does not require one extra click
        }
    }

    function handleClearRoute(x as Number, y as Number) as Boolean {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster

        if (
            settings.mode != MODE_NORMAL &&
            settings.mode != MODE_ELEVATION &&
            settings.mode != MODE_MAP_MOVE
        ) {
            return false; // debug and map move do not clear routes
        }

        if (exclusiveOpRunning(3)) {
            return false; // something else is running, do not handle touch events
        }

        switch (_clearRouteProgress) {
            case 0:
                // press top left to start clear route
                if (inHitbox(x, y, clearRouteX, clearRouteY, halfHitboxSize)) {
                    _clearRouteProgress = 1;
                    return true;
                }
                return false;
            case 1:
                // press right to confirm, left cancels
                if (x > xHalfPhysical) {
                    _clearRouteProgress = 2;
                    return true;
                }
                _clearRouteProgress = 0;
                return true;

            case 2:
                // press left to confirm, right cancels
                if (x < xHalfPhysical) {
                    _clearRouteProgress = 3;
                    return true;
                }
                _clearRouteProgress = 0;
                return true;
            case 3:
                // press right to confirm, left cancels
                if (x > xHalfPhysical) {
                    getApp()._breadcrumbContext.clearRoutes();
                }
                _clearRouteProgress = 0;
                return true;
        }

        return false;
    }

    function exclusiveOpRunning(current as Number) as Boolean {
        // _startCacheTilesProgress - 0
        // _enableMapProgress - 1
        // _disableMapProgress - 2
        // _clearRouteProgress - 3
        return (
            (_startCacheTilesProgress != 0 && current != 0) ||
            (_enableMapProgress != 0 && current != 1) ||
            (_disableMapProgress != 0 && current != 2) ||
            (_clearRouteProgress != 0 && current != 3)
        );
    }

    (:noStorage)
    function handleStartCacheRoute(x as Number, y as Number) as Boolean {
        return false;
    }
    (:storage)
    function handleStartCacheRoute(x as Number, y as Number) as Boolean {
        if (exclusiveOpRunning(0)) {
            return false; // something else is running, do not handle touch events
        }

        if (!settings.mapEnabled) {
            _startCacheTilesProgress = 0;
            return false; // maps are not enabled, we hide the start symbol in this case
        }
        var res = handleStartLeftYNUi(
            x,
            y,
            _cachedValues.physicalScreenWidth - halfHitboxSize, // right of screen
            _cachedValues.yHalfPhysical,
            _startCacheTilesProgress,
            _cachedValues.method(:startCacheCurrentMapArea)
        );
        _startCacheTilesProgress = res[1];
        return res[0];
    }

    function handleStartMapEnable(x as Number, y as Number) as Boolean {
        if (exclusiveOpRunning(1)) {
            return false; // something else is running, do not handle touch events
        }

        if (settings.mapEnabled) {
            _enableMapProgress = 0;
            return false; // already enabled
        }
        var res = handleStartLeftYNUi(
            x,
            y,
            mapEnabledX,
            mapEnabledY,
            _enableMapProgress,
            settings.method(:toggleMapEnabled)
        );
        _enableMapProgress = res[1];
        return res[0];
    }
    function handleStartMapDisable(x as Number, y as Number) as Boolean {
        if (exclusiveOpRunning(2)) {
            return false; // something else is running, do not handle touch events
        }
        if (!settings.mapEnabled) {
            _disableMapProgress = 0;
            return false; // already disabled
        }
        var res = handleStartLeftYNUi(
            x,
            y,
            mapEnabledX,
            mapEnabledY,
            _disableMapProgress,
            settings.method(:toggleMapEnabled)
        );
        _disableMapProgress = res[1];
        return res[0];
    }

    function handleStartLeftYNUi(
        x as Number,
        y as Number,
        hitboxX as Float,
        hitboxY as Float,
        variable as Number,
        method as Method
    ) as [Boolean, Number] {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster

        if (settings.mode != MODE_NORMAL) {
            return [false, variable]; // only normal mode can start y/n confirms atm
        }
        switch (variable) {
            case 0:
                // start location touched
                if (inHitbox(x, y, hitboxX, hitboxY, halfHitboxSize)) {
                    return [true, 1];
                }
                return [false, 0];
            case 1:
                // press left to confirm, right cancels
                if (x < xHalfPhysical) {
                    return [true, 2];
                }
                return [true, 0];

            case 2:
                // press right to confirm, left cancels
                if (x > xHalfPhysical) {
                    return [true, 3];
                }
                return [true, 0];
            case 3:
                // press left to confirm, right cancels
                if (x < xHalfPhysical) {
                    method.invoke();
                }
                return [true, 0];
        }

        return [false, variable];
    }

    function returnToUser() as Void {
        if (settings.mode != MODE_NORMAL && settings.mode != MODE_MAP_MOVE) {
            return;
        }
        _cachedValues.returnToUser();
    }

    // todo move most of these into a ui class
    // and all the elevation ones into elevation class, or cached values if they are
    // things set to -1 are set by setScreenSize()
    var _xElevationStart as Float = -1f; // think this needs to depend on dpi?
    var _xElevationEnd as Float = -1f;
    var _yElevationHeight as Float = -1f;
    var _halfYElevationHeight as Float = -1f;
    var yElevationTop as Float = -1f;
    var yElevationBottom as Float = -1f;
    var clearRouteX as Float = -1f;
    var clearRouteY as Float = -1f;
    var modeSelectX as Float = -1f;
    var modeSelectY as Float = -1f;
    var returnToUserX as Float = -1f;
    var returnToUserY as Float = -1f;
    var mapEnabledX as Float = -1f;
    var mapEnabledY as Float = -1f;
    var hitboxSize as Float = 60f;
    var halfHitboxSize as Float = hitboxSize / 2.0f;

    function setElevationAndUiData(xElevationStart as Float) as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster
        var physicalScreenWidth = _cachedValues.physicalScreenWidth; // local lookup faster

        _xElevationStart = xElevationStart;
        _xElevationEnd = physicalScreenWidth - _xElevationStart;
        var xElevationFromCenter = xHalfPhysical - _xElevationStart;
        _yElevationHeight =
            Math.sqrt(
                xHalfPhysical * xHalfPhysical - xElevationFromCenter * xElevationFromCenter
            ).toFloat() *
                2 -
            40;
        _halfYElevationHeight = _yElevationHeight / 2.0f;
        yElevationTop = yHalfPhysical - _halfYElevationHeight;
        yElevationBottom = yHalfPhysical + _halfYElevationHeight;

        setCornerPositions();
    }

    (:round)
    function setCornerPositions() as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        var offsetSize = Math.sqrt(
            ((yHalfPhysical - halfHitboxSize) * (yHalfPhysical - halfHitboxSize)) / 2
        ).toFloat();

        // top left
        clearRouteX = xHalfPhysical - offsetSize;
        clearRouteY = yHalfPhysical - offsetSize;

        // top right
        modeSelectX = xHalfPhysical + offsetSize;
        modeSelectY = yHalfPhysical - offsetSize;

        // bottom left
        returnToUserX = xHalfPhysical - offsetSize;
        returnToUserY = yHalfPhysical + offsetSize;

        // bottom right
        mapEnabledX = xHalfPhysical + offsetSize;
        mapEnabledY = yHalfPhysical + offsetSize;
    }

    (:rectangle)
    function setCornerPositions() as Void {
        var physicalScreenWidth = _cachedValues.physicalScreenWidth; // local lookup faster
        var physicalScreenHeight = _cachedValues.physicalScreenHeight; // local lookup faster

        // top left
        clearRouteX = halfHitboxSize;
        clearRouteY = halfHitboxSize;

        // top right
        modeSelectX = physicalScreenWidth - halfHitboxSize;
        modeSelectY = halfHitboxSize;

        // bottom left
        returnToUserX = halfHitboxSize;
        returnToUserY = physicalScreenHeight - halfHitboxSize;

        // bottom right
        mapEnabledX = physicalScreenWidth - halfHitboxSize;
        mapEnabledY = physicalScreenHeight - halfHitboxSize;
    }

    function renderElevationChart(
        dc as Dc,
        hScalePPM as Float,
        vScale as Float,
        startAt as Float,
        distancePixels as Float,
        elevationText as String
    ) as Void {
        var xHalfPhysical = _cachedValues.xHalfPhysical; // local lookup faster
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster
        var physicalScreenHeight = _cachedValues.physicalScreenHeight; // local lookup faster

        var hScaleNames = settings.distanceImperialUnits ? SCALE_NAMES_IMPERIAL : SCALE_NAMES;
        var vScaleNames = settings.elevationImperialUnits
            ? ELEVATION_SCALE_NAMES_IMPERIAL
            : ELEVATION_SCALE_NAMES;

        var hScaleData = getScaleSizeGeneric(hScalePPM, DESIRED_SCALE_PIXEL_WIDTH, hScaleNames);
        var hPixelWidth = hScaleData[0];
        var hDistanceM = hScaleData[1];
        var vScaleData = getScaleSizeGeneric(vScale, DESIRED_ELEV_SCALE_PIXEL_WIDTH, vScaleNames);
        var vPixelWidth = vScaleData[0];
        var vDistanceM = vScaleData[1];
        dc.setColor(settings.uiColour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        // vertical and horizontal lines for extreems
        dc.drawLine(_xElevationStart, yElevationTop, _xElevationStart, yElevationBottom);
        dc.drawLine(_xElevationStart, yHalfPhysical, _xElevationEnd, yHalfPhysical);
        // border (does not look great)
        // dc.drawRectangle(_xElevationStart, yHalfPhysical - _halfYElevationHeight, screenWidth - _xElevationStart * 2, _yElevationHeight);

        // horizontal lines vertical scale
        if (vPixelWidth != 0) {
            // do not want infinite for loop
            for (var i = 0; i < _halfYElevationHeight; i += vPixelWidth) {
                var yTop = yHalfPhysical - i;
                var yBottom = yHalfPhysical + i;
                dc.drawLine(_xElevationStart, yTop, _xElevationEnd, yTop);
                dc.drawLine(_xElevationStart, yBottom, _xElevationEnd, yBottom);
            }
        }

        // vertical lines horizontal scale
        if (hPixelWidth != 0) {
            // do not want infinite for loop
            for (var i = _xElevationStart; i < _xElevationEnd; i += hPixelWidth) {
                dc.drawLine(i, yElevationTop, i, yElevationBottom);
            }
        }

        var mToFt = 3.28084f;
        var elevationUnit = "m";
        var startAtDisplay = startAt;
        if (settings.elevationImperialUnits) {
            elevationUnit = "ft";
            startAtDisplay = startAt * mToFt;
        }

        dc.drawText(
            0,
            yHalfPhysical,
            Graphics.FONT_XTINY,
            startAtDisplay.format("%.0f"),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER
        );
        if (vScale != 0) {
            // prevent division by 0
            var topScaleM = startAt + _halfYElevationHeight / vScale;
            var topScaleDisplay = topScaleM;
            if (settings.elevationImperialUnits) {
                topScaleDisplay = topScaleM * mToFt;
            }
            var topText = topScaleDisplay.format("%.0f") + elevationUnit;
            var textDim = dc.getTextDimensions(topText, Graphics.FONT_XTINY);
            dc.drawText(
                _xElevationStart,
                yHalfPhysical - _halfYElevationHeight - textDim[1],
                Graphics.FONT_XTINY,
                topText,
                Graphics.TEXT_JUSTIFY_LEFT
            );
            var bottomScaleM = startAt - _halfYElevationHeight / vScale;
            var bottomScaleDisplay = bottomScaleM;
            if (settings.elevationImperialUnits) {
                bottomScaleDisplay = bottomScaleM * mToFt;
            }
            dc.drawText(
                _xElevationStart,
                yHalfPhysical + _halfYElevationHeight,
                Graphics.FONT_XTINY,
                bottomScaleDisplay.format("%.0f") + elevationUnit,
                Graphics.TEXT_JUSTIFY_LEFT
            );
        }

        dc.setColor(settings.elevationColour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3);

        if (hPixelWidth != 0) {
            // if statement makes sure that we can get a SCALE_NAMES[hDistanceM]
            var hFoundName = hScaleNames[hDistanceM];

            var y = physicalScreenHeight - 20;
            dc.drawLine(
                xHalfPhysical - hPixelWidth / 2.0f,
                y,
                xHalfPhysical + hPixelWidth / 2.0f,
                y
            );
            dc.drawText(
                xHalfPhysical,
                y - 30,
                Graphics.FONT_XTINY,
                hFoundName,
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }

        if (vPixelWidth != 0) {
            // if statement makes sure that we can get a ELEVATION_SCALE_NAMES[vDistanceM]
            var vFoundName = vScaleNames[vDistanceM];

            var x = xHalfPhysical + DESIRED_SCALE_PIXEL_WIDTH / 2.0f;
            var y = physicalScreenHeight - 20 - 5 - vPixelWidth / 2.0f;
            dc.drawLine(x, y - vPixelWidth / 2.0f, x, y + vPixelWidth / 2.0f);
            dc.drawText(x + 5, y - 15, Graphics.FONT_XTINY, vFoundName, Graphics.TEXT_JUSTIFY_LEFT);
            // var vectorFont = Graphics.getVectorFont(
            //   {
            //     // font face from https://developer.garmin.com/connect-iq/reference-guides/devices-reference/
            //     :face=>["VeraSans"],
            //     :size=>16,
            //     // :font=>Graphics.FONT_XTINY,
            //     // :scale=>1.0f
            //   }
            // );
            // dc.drawAngledText(0, yHalfPhysical, vectorFont, vFoundName, Graphics.TEXT_JUSTIFY_LEFT, 90);
            // dc.drawRadialText(0, yHalfPhysical, vectorFont, vFoundName, Graphics.TEXT_JUSTIFY_LEFT, 90, 0, Graphics.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE);
            // drawAngledText and drawRadialText not available :(
        }

        var distanceM = _cachedValues.elapsedDistanceM;
        var distText;
        if (settings.elevationImperialUnits) {
            var distanceMi = distanceM * 0.000621371f;
            var distanceFt = distanceM * 3.28084f;
            distText =
                distanceMi >= 0.1
                    ? distanceMi.format("%.1f") + "mi"
                    : distanceFt.toNumber().toString() + "ft";
        } else {
            var distanceKM = distanceM / 1000f;
            distText =
                distanceKM > 1
                    ? distanceKM.format("%.1f") + "km"
                    : distanceM.toNumber().toString() + "m";
        }
        var text = "dist: " + distText + "\n" + "elev: " + elevationText;
        dc.drawText(xHalfPhysical, 20, Graphics.FONT_XTINY, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function getElevationScale(
        track as BreadcrumbTrack,
        routes as Array<BreadcrumbTrack>
    ) as [Float, Float, Float, Float] {
        var maxDistanceScaled = 0f;
        var minElevation = FLOAT_MAX;
        var maxElevation = FLOAT_MIN;
        if (track.coordinates.pointSize() > 2) {
            maxDistanceScaled = maxF(maxDistanceScaled, track.distanceTotal);
            minElevation = minF(minElevation, track.elevationMin);
            maxElevation = maxF(maxElevation, track.elevationMax);
        }

        for (var i = 0; i < routes.size(); ++i) {
            var route = routes[i];
            if (!settings.routeEnabled(route.storageIndex)) {
                continue;
            }
            if (route.coordinates.pointSize() > 2) {
                maxDistanceScaled = maxF(maxDistanceScaled, route.distanceTotal);
                minElevation = minF(minElevation, route.elevationMin);
                maxElevation = maxF(maxElevation, route.elevationMax);
            }
        }

        // abs really only needed until we get the first point (then max should always be more than min)
        var elevationChange = abs(maxElevation - minElevation);
        var startAt = minElevation + elevationChange / 2;
        return getElevationScaleRaw(maxDistanceScaled, elevationChange, startAt);
    }

    function getElevationScaleOrderedRoutes(
        track as BreadcrumbTrack,
        routes as Array<BreadcrumbTrack>
    ) as [Float, Float, Float, Float] {
        var maxTrackDistanceScaled = 0f;
        var minElevation = FLOAT_MAX;
        var maxElevation = FLOAT_MIN;
        if (track.coordinates.pointSize() > 2) {
            maxTrackDistanceScaled = maxF(maxTrackDistanceScaled, track.distanceTotal);
            minElevation = minF(minElevation, track.elevationMin);
            maxElevation = maxF(maxElevation, track.elevationMax);
        }

        var allRouteDistanceScaled = 0f;
        for (var i = 0; i < routes.size(); ++i) {
            var route = routes[i];
            if (!settings.routeEnabled(route.storageIndex)) {
                continue;
            }
            if (route.coordinates.pointSize() > 2) {
                allRouteDistanceScaled += route.distanceTotal;
                minElevation = minF(minElevation, route.elevationMin);
                maxElevation = maxF(maxElevation, route.elevationMax);
            }
        }

        // track renders ontop of the routes, so we need to get the max distance of the routes or the track
        var maxDistanceScaled = maxF(allRouteDistanceScaled, maxTrackDistanceScaled);

        // abs really only needed until we get the first point (then max should always be more than min)
        var elevationChange = abs(maxElevation - minElevation);
        var startAt = minElevation + elevationChange / 2;
        return getElevationScaleRaw(maxDistanceScaled, elevationChange, startAt);
    }

    function getElevationScaleRaw(
        distanceScaled as Float,
        elevationChange as Float,
        startAt as Float
    ) as [Float, Float, Float, Float] {
        var distanceM = distanceScaled;
        var distanceScale = _cachedValues.currentScale;
        if (distanceScale != 0f) {
            distanceM = distanceScaled / distanceScale;
        }

        // clip to a a square (since we cannot see the edges of the circle)
        var totalXDistance = _cachedValues.physicalScreenWidth - 2 * _xElevationStart;
        var totalYDistance = _yElevationHeight;

        if (distanceScaled == 0 && elevationChange == 0) {
            return [0f, 0f, startAt, 0f]; // do not divide by 0
        }

        if (distanceScaled == 0) {
            return [0f, totalYDistance / elevationChange, startAt, 0f]; // do not divide by 0
        }

        if (elevationChange == 0) {
            return [totalXDistance / distanceScaled, 0f, startAt, totalXDistance / distanceM]; // do not divide by 0
        }

        var hScalePPM = totalXDistance / distanceM; // pixels per meter
        var hScale = totalXDistance / distanceScaled; // pixels per pixel - make track renderring faster (single multiply)
        var vScale = totalYDistance / elevationChange;

        return [hScale, vScale, startAt, hScalePPM];
    }

    function renderTrackElevation(
        dc as Dc,
        xElevationStart as Float,
        track as BreadcrumbTrack,
        colour as Graphics.ColorType,
        hScale as Float,
        vScale as Float,
        startAt as Float
    ) as Float {
        var yHalfPhysical = _cachedValues.yHalfPhysical; // local lookup faster

        var sizeRaw = track.coordinates.size();
        if (sizeRaw < ARRAY_POINT_SIZE * 2) {
            return xElevationStart; // not enough points for iteration
        }

        dc.setColor(colour, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);

        var coordinatesRaw = track.coordinates._internalArrayBuffer;
        var prevPointX = coordinatesRaw[0];
        var prevPointY = coordinatesRaw[1];
        var prevPointAlt = coordinatesRaw[2];
        var prevChartX = xElevationStart;
        var prevChartY = yHalfPhysical + (startAt - prevPointAlt) * vScale;
        for (var i = ARRAY_POINT_SIZE; i < sizeRaw; i += ARRAY_POINT_SIZE) {
            var currPointX = coordinatesRaw[i];
            var currPointY = coordinatesRaw[i + 1];
            var currPointAlt = coordinatesRaw[i + 2];

            var xDistance = distance(prevPointX, prevPointY, currPointX, currPointY);
            var yDistance = prevPointAlt - currPointAlt;

            var currChartX = prevChartX + xDistance * hScale;
            var currChartY = prevChartY + yDistance * vScale;

            dc.drawLine(prevChartX, prevChartY, currChartX, currChartY);

            prevPointX = currPointX;
            prevPointY = currPointY;
            prevPointAlt = currPointAlt;
            prevChartX = currChartX;
            prevChartY = currChartY;
        }

        return prevChartX;
    }
}
