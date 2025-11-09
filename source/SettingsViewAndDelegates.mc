import Toybox.Activity;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Application;

typedef Renderable as interface {
    function rerender() as Void;
};

(:settingsView)
class SettingsStringPicker extends MyTextPickerDelegate {
    private var callback as (Method(value as String) as Void);
    public var parent as Renderable;
    function initialize(
        callback as (Method(value as String) as Void),
        parent as Renderable,
        picker as TextPickerView
    ) {
        MyTextPickerDelegate.initialize(me.method(:onTextEntered), picker);
        self.callback = callback;
        self.parent = parent;
    }

    function onTextEntered(text as Lang.String) as Lang.Boolean {
        logT("onTextEntered: " + text);

        callback.invoke(text);
        parent.rerender();

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    function onCancel() as Boolean {
        logT("canceled");
        return true;
    }
}

(:settingsView)
function startPicker(
    picker as SettingsFloatPicker or SettingsColourPicker or SettingsNumberPicker
) as Void {
    WatchUi.pushView(
        new $.NumberPickerView(picker),
        new $.NumberPickerDelegate(picker),
        WatchUi.SLIDE_IMMEDIATE
    );
}

function safeSetSubLabel(
    menu as WatchUi.Menu2,
    id as Object,
    value as String or ResourceId
) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    item.setSubLabel(value);
}

(:settingsView)
function safeSetLabel(menu as WatchUi.Menu2, id as Object, value as String or ResourceId) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    item.setLabel(value);
}

(:settingsView)
function safeSetToggle(menu as WatchUi.Menu2, id as Object, value as Boolean) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    if (item instanceof WatchUi.ToggleMenuItem) {
        item.setEnabled(value);
    }
}

// https://forums.garmin.com/developer/connect-iq/f/discussion/379406/vertically-center-icon-in-iconmenuitem-using-menu2#pifragment-1298=4
const iconMenuWidthPercent = 0.6;

(:settingsView)
class ColourIcon extends WatchUi.Drawable {
    var colour as Number;

    function initialize(colour as Number) {
        Drawable.initialize({});
        self.colour = colour;
    }

    function draw(dc as Graphics.Dc) {
        var iconWidthHeight;

        // Calculate Width Height of Icon based on drawing area
        if (dc.getHeight() > dc.getWidth()) {
            iconWidthHeight = iconMenuWidthPercent * dc.getHeight();
        } else {
            iconWidthHeight = iconMenuWidthPercent * dc.getWidth();
        }

        dc.setColor(colour, colour);
        dc.fillCircle(dc.getWidth() / 2, dc.getHeight() / 2, iconWidthHeight / 2f);
    }
}

(:settingsView)
function safeSetIcon(menu as WatchUi.Menu2, id as Object, value as WatchUi.Drawable) as Void {
    var itemIndex = menu.findItemById(id);
    if (itemIndex <= -1) {
        return;
    }

    var item = menu.getItem(itemIndex);
    if (item == null) {
        return;
    }

    // support was added for icons on menuitems in API Level 3.4.0 but IconMenuItem had it from API 3.0.0
    // MenuItem and IconMenuItem, they both support icons
    if (item has :setIcon) {
        item.setIcon(value);
    }
}

function getActivityTypeString(combinedValue as Number) as String or ResourceId {
    switch (combinedValue) {
        case 0: return Rez.Strings.ActGeneric;
        case 1000: return Rez.Strings.ActRun;
        case 1001: return Rez.Strings.ActRunTreadmill;
        case 1002: return Rez.Strings.ActRunStreet;
        case 1003: return Rez.Strings.ActRunTrail;
        case 1004: return Rez.Strings.ActRunTrack;
        case 1045: return Rez.Strings.ActRunIndoor;
        case 1058: return Rez.Strings.ActRunVirtual;
        case 1059: return Rez.Strings.ActRunObstacle;
        case 1067: return Rez.Strings.ActRunUltra;
        case 2000: return Rez.Strings.ActCycle;
        case 2005: return Rez.Strings.ActCycleSpin;
        case 2006: return Rez.Strings.ActCycleIndoor;
        case 2007: return Rez.Strings.ActCycleRoad;
        case 2008: return Rez.Strings.ActCycleMtn;
        case 2009: return Rez.Strings.ActCycleDownhill;
        case 2010: return Rez.Strings.ActCycleRecumbent;
        case 2011: return Rez.Strings.ActCycleCyclocross;
        case 2012: return Rez.Strings.ActCycleHand;
        case 2013: return Rez.Strings.ActCycleTrack;
        case 2029: return Rez.Strings.ActCycleBmx;
        case 2046: return Rez.Strings.ActCycleGravel;
        case 2048: return Rez.Strings.ActCycleCommute;
        case 2049: return Rez.Strings.ActCycleMixed;
        case 3000: return Rez.Strings.ActTransition;
        case 4000: return Rez.Strings.ActFitness;
        case 4014: return Rez.Strings.ActFitRow;
        case 4015: return Rez.Strings.ActFitElliptical;
        case 4016: return Rez.Strings.ActFitStair;
        case 4020: return Rez.Strings.ActFitStrength;
        case 4026: return Rez.Strings.ActFitCardio;
        case 4043: return Rez.Strings.ActFitYoga;
        case 4044: return Rez.Strings.ActFitPilates;
        case 4068: return Rez.Strings.ActFitIndoorClimb;
        case 4069: return Rez.Strings.ActFitBouldering;
        case 5000: return Rez.Strings.ActSwim;
        case 5017: return Rez.Strings.ActSwimLap;
        case 5018: return Rez.Strings.ActSwimOpen;
        case 6000: return Rez.Strings.ActBasketball;
        case 7000: return Rez.Strings.ActSoccer;
        case 8000: return Rez.Strings.ActTennis;
        case 9000: return Rez.Strings.ActFootballUS;
        case 10000: return Rez.Strings.ActTraining;
        case 11000: return Rez.Strings.ActWalk;
        case 11027: return Rez.Strings.ActWalkIndoor;
        case 11030: return Rez.Strings.ActWalkCasual;
        case 11031: return Rez.Strings.ActWalkSpeed;
        case 12000: return Rez.Strings.ActXcSki;
        case 12042: return Rez.Strings.ActXcSkiSkate;
        case 13000: return Rez.Strings.ActAlpineSki;
        case 13037: return Rez.Strings.ActAlpineSkiBack;
        case 13038: return Rez.Strings.ActAlpineSkiResort;
        case 14000: return Rez.Strings.ActSnowboard;
        case 14037: return Rez.Strings.ActSnowboardBack;
        case 14038: return Rez.Strings.ActSnowboardResort;
        case 15000: return Rez.Strings.ActRowing;
        case 16000: return Rez.Strings.ActMountaineering;
        case 17000: return Rez.Strings.ActHiking;
        case 18000: return Rez.Strings.ActMulti;
        case 18078: return Rez.Strings.ActMultiTri;
        case 18079: return Rez.Strings.ActMultiDu;
        case 18080: return Rez.Strings.ActMultiBrick;
        case 18081: return Rez.Strings.ActMultiSwimrun;
        case 18082: return Rez.Strings.ActMultiAdvRace;
        case 19000: return Rez.Strings.ActPaddling;
        case 20000: return Rez.Strings.ActFlying;
        case 20039: return Rez.Strings.ActFlyingDrone;
        case 21000: return Rez.Strings.ActEbike;
        case 21028: return Rez.Strings.ActEbikeFit;
        case 21047: return Rez.Strings.ActEbikeMtn;
        case 22000: return Rez.Strings.ActMotorcycle;
        case 22035: return Rez.Strings.ActMotorcycleAtv;
        case 22036: return Rez.Strings.ActMotorcycleMx;
        case 23000: return Rez.Strings.ActBoating;
        case 23032: return Rez.Strings.ActBoatingSail;
        case 24000: return Rez.Strings.ActDriving;
        case 25000: return Rez.Strings.ActGolf;
        case 26000: return Rez.Strings.ActHangGliding;
        case 27000: return Rez.Strings.ActHorseback;
        case 28000: return Rez.Strings.ActHunting;
        case 29000: return Rez.Strings.ActFishing;
        case 30000: return Rez.Strings.ActInlineSkate;
        case 31000: return Rez.Strings.ActRockClimb;
        case 31068: return Rez.Strings.ActRockClimbIndoor;
        case 31069: return Rez.Strings.ActRockClimbBoulder;
        case 32000: return Rez.Strings.ActSailing;
        case 32065: return Rez.Strings.ActSailingRace;
        case 33000: return Rez.Strings.ActIceSkate;
        case 33073: return Rez.Strings.ActIceSkateHockey;
        case 34000: return Rez.Strings.ActSkyDiving;
        case 34040: return Rez.Strings.ActSkyDivingWingsuit;
        case 35000: return Rez.Strings.ActSnowshoe;
        case 36000: return Rez.Strings.ActSnowmobile;
        case 37000: return Rez.Strings.ActSup;
        case 38000: return Rez.Strings.ActSurfing;
        case 39000: return Rez.Strings.ActWakeboard;
        case 40000: return Rez.Strings.ActWaterSki;
        case 41000: return Rez.Strings.ActKayak;
        case 41041: return Rez.Strings.ActKayakWhite;
        case 42000: return Rez.Strings.ActRafting;
        case 42041: return Rez.Strings.ActRaftingWhite;
        case 43000: return Rez.Strings.ActWindsurf;
        case 44000: return Rez.Strings.ActKitesurf;
        case 45000: return Rez.Strings.ActTactical;
        case 46000: return Rez.Strings.ActJumpmaster;
        case 47000: return Rez.Strings.ActBoxing;
        case 48000: return Rez.Strings.ActFloorClimb;
        case 49000: return Rez.Strings.ActBaseball;
        case 50000: return Rez.Strings.ActSoftballFast;
        case 51000: return Rez.Strings.ActSoftballSlow;
        case 56000: return Rez.Strings.ActShooting;
        case 57000: return Rez.Strings.ActAutoRacing;
        case 58000: return Rez.Strings.ActWinterSport;
        case 59000: return Rez.Strings.ActGrinding;
        case 60000: return Rez.Strings.ActHealthMon;
        case 61000: return Rez.Strings.ActMarine;
        case 62000: return Rez.Strings.ActHiit;
        case 62073: return Rez.Strings.ActHiitAmrap;
        case 62074: return Rez.Strings.ActHiitEmom;
        case 62075: return Rez.Strings.ActHiitTabata;
        case 63000: return Rez.Strings.ActGaming;
        case 63077: return Rez.Strings.ActGamingEsport;
        case 64000: return Rez.Strings.ActRacket;
        case 64084: return Rez.Strings.ActRacketPickle;
        case 64085: return Rez.Strings.ActRacketPadel;
        case 64094: return Rez.Strings.ActRacketSquash;
        case 64095: return Rez.Strings.ActRacketBadminton;
        case 64096: return Rez.Strings.ActRacketRacquetball;
        case 64097: return Rez.Strings.ActRacketTableTennis;
        case 65000: return Rez.Strings.ActWheelWalk;
        case 65086: return Rez.Strings.ActWheelWalkIndoor;
        case 66000: return Rez.Strings.ActWheelRun;
        case 66087: return Rez.Strings.ActWheelRunIndoor;
        case 67000: return Rez.Strings.ActMeditation;
        case 67062: return Rez.Strings.ActMeditationBreath;
        case 68000: return Rez.Strings.ActParaSport;
        case 69000: return Rez.Strings.ActDiscGolf;
        case 70000: return Rez.Strings.ActTeamSport;
        case 70092: return Rez.Strings.ActTeamUltimate;
        case 71000: return Rez.Strings.ActCricket;
        case 72000: return Rez.Strings.ActRugby;
        case 73000: return Rez.Strings.ActHockey;
        case 73090: return Rez.Strings.ActHockeyField;
        case 73091: return Rez.Strings.ActHockeyIce;
        case 74000: return Rez.Strings.ActLacrosse;
        case 75000: return Rez.Strings.ActVolleyball;
        case 76000: return Rez.Strings.ActTube;
        case 77000: return Rez.Strings.ActWakesurf;
    }

    // Fallback for any unknown value
    return Rez.Strings.ActGeneric;
}

// https://forums.garmin.com/developer/connect-iq/f/discussion/304179/programmatically-set-the-state-of-togglemenuitem
(:settingsView)
class SettingsMain extends Rez.Menus.SettingsMain {
    function initialize() {
        Rez.Menus.SettingsMain.initialize();
        rerender();
    }

    function rerender() as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var modeString = "";
        switch (settings.mode) {
            case MODE_NORMAL:
                modeString = Rez.Strings.trackRouteMode;
                break;
            case MODE_ELEVATION:
                modeString = Rez.Strings.elevationMode;
                break;
            case MODE_MAP_MOVE:
                modeString = Rez.Strings.mapMove;
                break;
            case MODE_DEBUG:
                modeString = Rez.Strings.debug;
                break;
        }
        safeSetSubLabel(me, :settingsMainMode, modeString);
        var uiModeString = "";
        switch (settings.uiMode) {
            case UI_MODE_SHOW_ALL:
                uiModeString = Rez.Strings.uiModeShowAll;
                break;
            case UI_MODE_HIDDEN:
                uiModeString = Rez.Strings.uiModeHidden;
                break;
            case UI_MODE_NONE:
                uiModeString = Rez.Strings.uiModeNone;
                break;
        }
        safeSetSubLabel(me, :settingsMainModeUiMode, uiModeString);
        var elevationModeString = "";
        switch (settings.elevationMode) {
            case ELEVATION_MODE_STACKED:
                elevationModeString = Rez.Strings.elevationModeStacked;
                break;
            case ELEVATION_MODE_ORDERED_ROUTES:
                elevationModeString = Rez.Strings.elevationModeOrderedRoutes;
                break;
        }
        safeSetSubLabel(me, :settingsMainModeElevationMode, elevationModeString);
        safeSetSubLabel(
            me,
            :settingsMainRecalculateIntervalS,
            settings.recalculateIntervalS.toString()
        );
        var renderModeString = "";
        switch (settings.renderMode) {
            case RENDER_MODE_BUFFERED_ROTATING:
                renderModeString = Rez.Strings.renderModeBufferedRotating;
                break;
            case RENDER_MODE_UNBUFFERED_ROTATING:
                renderModeString = Rez.Strings.renderModeUnbufferedRotating;
                break;
            case RENDER_MODE_BUFFERED_NO_ROTATION:
                renderModeString = Rez.Strings.renderModeBufferedNoRotating;
                break;
            case RENDER_MODE_UNBUFFERED_NO_ROTATION:
                renderModeString = Rez.Strings.renderModeNoBufferedNoRotating;
                break;
        }
        safeSetSubLabel(me, :settingsMainRenderMode, renderModeString);
        safeSetSubLabel(
            me,
            :settingsMainCenterUserOffsetY,
            settings.centerUserOffsetY.format("%.2f")
        );
        safeSetToggle(me, :settingsMainDisplayLatLong, settings.displayLatLong);
        safeSetSubLabel(me, :settingsMainMaxTrackPoints, settings.maxTrackPoints.toString());
        safeSetSubLabel(
            me,
            :settingsMainMapMoveScreenSize,
            settings.mapMoveScreenSize.format("%.2f")
        );
        safeSetSubLabel(
            me,
            :settingsMainActivityType,
            getActivityTypeString(settings.activityType())
        );
    }
}

(:noSettingsView)
class SettingsMain extends Rez.Menus.SettingsMain {
    function initialize() {
        Rez.Menus.SettingsMain.initialize();
        rerender();
    }

    function rerender() as Void {
        safeSetSubLabel(
            me,
            :settingsMainActivityType,
            getActivityTypeString(settings.activityType())
        );
    }
}

(:settingsView)
class SettingsZoomAtPace extends Rez.Menus.SettingsZoomAtPace {
    function initialize() {
        Rez.Menus.SettingsZoomAtPace.initialize();
        rerender();
    }

    function rerender() as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var modeString = "";
        switch (settings.zoomAtPaceMode) {
            case ZOOM_AT_PACE_MODE_PACE:
                modeString = Rez.Strings.zoomAtPaceModePace;
                break;
            case ZOOM_AT_PACE_MODE_STOPPED:
                modeString = Rez.Strings.zoomAtPaceModeStopped;
                break;
            case ZOOM_AT_PACE_MODE_NEVER_ZOOM:
                modeString = Rez.Strings.zoomAtPaceModeNever;
                break;
            case ZOOM_AT_PACE_MODE_ALWAYS_ZOOM:
                modeString = Rez.Strings.zoomAtPaceModeAlways;
                break;
            case ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK:
                modeString = Rez.Strings.zoomAtPaceModeRoutesWithoutTrack;
                break;
        }
        safeSetSubLabel(me, :settingsZoomAtPaceMode, modeString);
        safeSetSubLabel(
            me,
            :settingsZoomAtPaceUserMeters,
            settings.metersAroundUser.toString() + "m"
        );
        safeSetSubLabel(
            me,
            :settingsZoomAtPaceMPS,
            settings.zoomAtPaceSpeedMPS.format("%.2f") + "m/s"
        );
    }
}

(:settingsView)
class SettingsMap extends Rez.Menus.SettingsMap {
    function initialize() {
        Rez.Menus.SettingsMap.initialize();
        rerender();
    }

    function rerender() as Void {
        var settings = getApp()._breadcrumbContext.settings;
        safeSetToggle(me, :settingsMapEnabled, true);

        safeSetSubLabel(me, :settingsMapTileCacheSize, settings.tileCacheSize.toString());
        safeSetSubLabel(me, :settingsMapTileCachePadding, settings.tileCachePadding.toString());
        safeSetSubLabel(
            me,
            :settingsMapMaxPendingWebRequests,
            settings.maxPendingWebRequests.toString()
        );
        safeSetSubLabel(
            me,
            :settingsMapDisableMapsFailureCount,
            settings.disableMapsFailureCount.toString()
        );
        var fixedLatitude = settings.fixedLatitude;
        var latString = fixedLatitude == null ? "Disabled" : fixedLatitude.format("%.5f");
        safeSetSubLabel(me, :settingsMapFixedLatitude, latString);
        var fixedLongitude = settings.fixedLongitude;
        var longString = fixedLongitude == null ? "Disabled" : fixedLongitude.format("%.5f");
        safeSetSubLabel(me, :settingsMapFixedLongitude, longString);
        safeSetToggle(
            me,
            :settingsMapScaleRestrictedToTileLayers,
            settings.scaleRestrictedToTileLayers()
        );
        safeSetSubLabel(me, :settingsMapHttpErrorTileTTLS, settings.httpErrorTileTTLS.toString());
        safeSetSubLabel(me, :settingsMapErrorTileTTLS, settings.errorTileTTLS.toString());
        safeSetToggle(me, :settingsMapUseDrawBitmap, settings.useDrawBitmap);
        var packingFormatString = "";
        switch (settings.packingFormat) {
            case 0:
                packingFormatString = Rez.Strings.packingFormatDefault;
                break;
            case 1:
                packingFormatString = Rez.Strings.packingFormatYUV;
                break;
            case 2:
                packingFormatString = Rez.Strings.packingFormatPNG;
                break;
            case 3:
                packingFormatString = Rez.Strings.packingFormatJPG;
                break;
        }
        safeSetSubLabel(me, :settingsMapPackingFormat, packingFormatString);
    }
}

(:settingsView)
class SettingsTileServer extends Rez.Menus.SettingsTileServer {
    function initialize() {
        Rez.Menus.SettingsTileServer.initialize();
        rerender();
    }

    function rerender() as Void {
        var settings = getApp()._breadcrumbContext.settings;

        var mapChoiceString = "";
        switch (settings.mapChoice) {
            case 0:
                mapChoiceString = Rez.Strings.custom;
                break;
            case 1:
                mapChoiceString = Rez.Strings.companionApp;
                break;
            case 2:
                mapChoiceString = Rez.Strings.openTopoMap;
                break;
            case 3:
                mapChoiceString = Rez.Strings.esriWorldImagery;
                break;
            case 4:
                mapChoiceString = Rez.Strings.esriWorldStreetMap;
                break;
            case 5:
                mapChoiceString = Rez.Strings.esriWorldTopoMap;
                break;
            case 6:
                mapChoiceString = Rez.Strings.esriWorldTransportation;
                break;
            case 7:
                mapChoiceString = Rez.Strings.esriWorldDarkGrayBase;
                break;
            case 8:
                mapChoiceString = Rez.Strings.esriWorldHillshade;
                break;
            case 9:
                mapChoiceString = Rez.Strings.esriWorldHillshadeDark;
                break;
            case 10:
                mapChoiceString = Rez.Strings.esriWorldLightGrayBase;
                break;
            case 11:
                mapChoiceString = Rez.Strings.esriUSATopoMaps;
                break;
            case 12:
                mapChoiceString = Rez.Strings.esriWorldOceanBase;
                break;
            case 13:
                mapChoiceString = Rez.Strings.esriWorldShadedRelief;
                break;
            case 14:
                mapChoiceString = Rez.Strings.esriNatGeoWorldMap;
                break;
            case 15:
                mapChoiceString = Rez.Strings.esriWorldNavigationCharts;
                break;
            case 16:
                mapChoiceString = Rez.Strings.esriWorldPhysicalMap;
                break;
            case 17:
                mapChoiceString = Rez.Strings.openStreetMapcyclosm;
                break;
            case 18:
                mapChoiceString = Rez.Strings.stadiaAlidadeSmooth;
                break;
            case 19:
                mapChoiceString = Rez.Strings.stadiaAlidadeSmoothDark;
                break;
            case 20:
                mapChoiceString = Rez.Strings.stadiaOutdoors;
                break;
            case 21:
                mapChoiceString = Rez.Strings.stadiaStamenToner;
                break;
            case 22:
                mapChoiceString = Rez.Strings.stadiaStamenTonerLite;
                break;
            case 23:
                mapChoiceString = Rez.Strings.stadiaStamenTerrain;
                break;
            case 24:
                mapChoiceString = Rez.Strings.stadiaStamenWatercolor;
                break;
            case 25:
                mapChoiceString = Rez.Strings.stadiaOSMBright;
                break;
            case 26:
                mapChoiceString = Rez.Strings.cartoVoyager;
                break;
            case 27:
                mapChoiceString = Rez.Strings.cartoDarkMatter;
                break;
            case 28:
                mapChoiceString = Rez.Strings.cartoDarkLightAll;
                break;
            case 29:
                mapChoiceString = Rez.Strings.mapyBasic;
                break;
            case 30:
                mapChoiceString = Rez.Strings.mapyOutdoor;
                break;
            case 31:
                mapChoiceString = Rez.Strings.mapyWinter;
                break;
            case 32:
                mapChoiceString = Rez.Strings.mapyAerial;
                break;
        }
        safeSetSubLabel(me, :settingsMapChoice, mapChoiceString);
        safeSetSubLabel(me, :settingsTileUrl, settings.tileUrl);
        safeSetSubLabel(me, :settingsAuthToken, settings.authToken);
        safeSetSubLabel(me, :settingsMapTileSize, settings.tileSize.toString());
        safeSetSubLabel(me, :settingsMapFullTileSize, settings.fullTileSize.toString());
        safeSetSubLabel(me, :settingsMapScaledTileSize, settings.scaledTileSize.toString());
        safeSetSubLabel(me, :settingsMapTileLayerMax, settings.tileLayerMax.toString());
        safeSetSubLabel(me, :settingsMapTileLayerMin, settings.tileLayerMin.toString());
    }
}

(:settingsView)
class SettingsMapStorage extends Rez.Menus.SettingsMapStorage {
    function initialize() {
        Rez.Menus.SettingsMapStorage.initialize();
        rerender();
    }

    function rerender() as Void {
        var settings = getApp()._breadcrumbContext.settings;
        safeSetToggle(me, :settingsMapStorageCacheTilesInStorage, settings.cacheTilesInStorage);
        safeSetToggle(me, :settingsMapStorageStorageMapTilesOnly, settings.storageMapTilesOnly);
        safeSetSubLabel(
            me,
            :settingsMapStorageStorageTileCacheSize,
            settings.storageTileCacheSize.toString()
        );
        safeSetSubLabel(
            me,
            :settingsMapStorageStorageTileCachePageCount,
            settings.storageTileCachePageCount.toString()
        );
        safeSetToggle(
            me,
            :settingsMapStorageStorageSeedBoundingBox,
            settings.storageSeedBoundingBox
        );
        safeSetSubLabel(
            me,
            :settingsMapStorageStorageSeedRouteDistanceM,
            settings.storageSeedRouteDistanceM.format("%.2f")
        );
        var cacheSize =
            "" +
            getApp()._breadcrumbContext.tileCache._storageTileCache._totalTileCount +
            "/" +
            settings.storageTileCacheSize;
        safeSetSubLabel(me, :settingsMapStorageCacheCurrentArea, cacheSize);
    }
}

(:settingsView)
class SettingsMapDisabled extends Rez.Menus.SettingsMapDisabled {
    function initialize() {
        Rez.Menus.SettingsMapDisabled.initialize();
        rerender();
    }

    function rerender() as Void {
        safeSetToggle(me, :settingsMapEnabled, false);
    }
}

(:settingsView)
class SettingsAlerts extends Rez.Menus.SettingsAlerts {
    function initialize() {
        Rez.Menus.SettingsAlerts.initialize();
        rerender();
    }

    function rerender() as Void {
        var settings = getApp()._breadcrumbContext.settings;
        alertsCommon(me, settings);
        safeSetSubLabel(
            me,
            :settingsAlertsOffTrackAlertsMaxReportIntervalS,
            settings.offTrackAlertsMaxReportIntervalS.toString()
        );
    }
}

(:settingsView)
function alertsCommon(menu as WatchUi.Menu2, settings as Settings) as Void {
    safeSetSubLabel(
        menu,
        :settingsAlertsOffTrackDistanceM,
        settings.offTrackAlertsDistanceM.toString()
    );
    safeSetSubLabel(
        menu,
        :settingsAlertsOffTrackCheckIntervalS,
        settings.offTrackCheckIntervalS.toString()
    );
    safeSetToggle(menu, :settingsAlertsDrawLineToClosestPoint, settings.drawLineToClosestPoint);
    safeSetToggle(menu, :settingsAlertsDrawCheverons, settings.drawCheverons);
    safeSetToggle(menu, :settingsAlertsOffTrackWrongDirection, settings.offTrackWrongDirection);
    safeSetToggle(menu, :settingsAlertsEnabled, settings.enableOffTrackAlerts);
    safeSetSubLabel(menu, :settingsAlertsTurnAlertTimeS, settings.turnAlertTimeS.toString());
    safeSetSubLabel(
        menu,
        :settingsAlertsMinTurnAlertDistanceM,
        settings.minTurnAlertDistanceM.toString()
    );
    var alertTypeString = "";
    switch (settings.alertType) {
        case ALERT_TYPE_TOAST:
            alertTypeString = Rez.Strings.alertTypeToast;
            break;
        case 1 /*ALERT_TYPE_ALERT*/:
            alertTypeString = Rez.Strings.alertTypeImage; // we display it as an image instead of datafield alert
            break;
        case ALERT_TYPE_IMAGE:
            alertTypeString = Rez.Strings.alertTypeImage;
            break;
    }
    safeSetSubLabel(menu, :settingsAlertsAlertType, alertTypeString);
}

(:settingsView)
class SettingsAlertsDisabled extends Rez.Menus.SettingsAlertsDisabled {
    function initialize() {
        Rez.Menus.SettingsAlertsDisabled.initialize();
        rerender();
    }

    function rerender() as Void {
        var settings = getApp()._breadcrumbContext.settings;
        alertsCommon(me, settings);
    }
}

(:settingsView)
class SettingsColours extends Rez.Menus.SettingsColours {
    function initialize() {
        Rez.Menus.SettingsColours.initialize();
        rerender();
    }

    function rerender() as Void {
        var settings = getApp()._breadcrumbContext.settings;
        safeSetIcon(me, :settingsColoursTrackColour, new ColourIcon(settings.trackColour));
        safeSetIcon(
            me,
            :settingsColoursDefaultRouteColour,
            new ColourIcon(settings.defaultRouteColour)
        );
        safeSetIcon(me, :settingsColoursUserColour, new ColourIcon(settings.userColour));
        safeSetIcon(me, :settingsColoursElevationColour, new ColourIcon(settings.elevationColour));
        safeSetIcon(
            me,
            :settingsColoursNormalModeColour,
            new ColourIcon(settings.normalModeColour)
        );
        safeSetIcon(me, :settingsColoursUiColour, new ColourIcon(settings.uiColour));
        safeSetIcon(me, :settingsColoursDebugColour, new ColourIcon(settings.debugColour));
    }
}

(:settingsView)
class SettingsDebug extends Rez.Menus.SettingsDebug {
    function initialize() {
        Rez.Menus.SettingsDebug.initialize();
        rerender();
    }

    function rerender() as Void {
        var settings = getApp()._breadcrumbContext.settings;
        safeSetIcon(me, :settingsDebugTileErrorColour, new ColourIcon(settings.tileErrorColour));
        safeSetToggle(me, :settingsDebugShowPoints, settings.showPoints);
        safeSetToggle(me, :settingsDebugDrawLineToClosestTrack, settings.drawLineToClosestTrack);
        safeSetToggle(me, :settingsDebugShowTileBorders, settings.showTileBorders);
        safeSetToggle(me, :settingsDebugShowErrorTileMessages, settings.showErrorTileMessages);
        safeSetToggle(
            me,
            :settingsDebugIncludeDebugPageInOnScreenUi,
            settings.includeDebugPageInOnScreenUi
        );
        safeSetToggle(me, :settingsDebugDrawHitBoxes, settings.drawHitBoxes);
        safeSetToggle(me, :settingsDebugShowDirectionPoints, settings.showDirectionPoints);
        safeSetSubLabel(
            me,
            :settingsDebugShowDirectionPointTextUnderIndex,
            settings.showDirectionPointTextUnderIndex.toString()
        );
    }
}

(:settingsView)
class SettingsRoute extends Rez.Menus.SettingsRoute {
    var settings as Settings;
    var routeId as Number;
    var parent as SettingsRoutes;
    function initialize(settings as Settings, routeId as Number, parent as SettingsRoutes) {
        Rez.Menus.SettingsRoute.initialize();
        self.settings = settings;
        self.routeId = routeId;
        self.parent = parent;
        rerender();
    }

    function rerender() as Void {
        var name = settings.routeName(routeId);
        setTitle(name);
        safeSetSubLabel(me, :settingsRouteName, name);
        safeSetToggle(me, :settingsRouteEnabled, settings.routeEnabled(routeId));
        safeSetIcon(me, :settingsRouteColour, new ColourIcon(settings.routeColour(routeId)));
        safeSetToggle(me, :settingsRouteReversed, settings.routeReversed(routeId));
        parent.rerender();
    }

    function setName(value as String) as Void {
        settings.setRouteName(routeId, value);
    }

    function setEnabled(value as Boolean) as Void {
        settings.setRouteEnabled(routeId, value);
    }

    function setReversed(value as Boolean) as Void {
        settings.setRouteReversed(routeId, value);
    }

    function routeEnabled() as Boolean {
        return settings.routeEnabled(routeId);
    }

    function routeReversed() as Boolean {
        return settings.routeReversed(routeId);
    }

    function routeColour() as Number {
        return settings.routeColour(routeId);
    }

    function setColour(value as Number) as Void {
        settings.setRouteColour(routeId, value);
    }
}

(:settingsView)
class SettingsRoutes extends WatchUi.Menu2 {
    var settings as Settings;
    function initialize(settings as Settings) {
        WatchUi.Menu2.initialize({
            :title => Rez.Strings.routesTitle,
        });
        me.settings = settings;
        setup();
        rerender();
    }

    function setup() as Void {
        addItem(
            new ToggleMenuItem(
                Rez.Strings.routesEnabled,
                "", // sublabel
                :settingsRoutesEnabled,
                settings.routesEnabled,
                {}
            )
        );
        if (!settings.routesEnabled) {
            return;
        }

        addItem(
            new ToggleMenuItem(
                Rez.Strings.displayRouteNamesTitle,
                "", // sublabel
                :settingsDisplayRouteNames,
                settings.displayRouteNames,
                {}
            )
        );

        addItem(
            new MenuItem(
                Rez.Strings.routeMax,
                settings.routeMax().toString(),
                :settingsDisplayRouteMax,
                {}
            )
        );

        addItem(
            new MenuItem(
                Rez.Strings.clearRoutes,
                "", // sublabel
                :settingsRoutesClearAll,
                {}
            )
        );

        for (var i = 0; i < settings.routeMax(); ++i) {
            var routeIndex = settings.getRouteIndexById(i);
            if (routeIndex == null) {
                // do not show routes that are not in the settings array
                // but still show disabled routes that are in the array
                continue;
            }
            var routeName = settings.routeName(i);
            var enabledStr = settings.routeEnabled(i) ? "Enabled" : "Disabled";
            var reversedStr = settings.routeReversed(i) ? "Reversed" : "Forward";
            addItem(
                // do not be tempted to switch this to a menuitem (IconMenuItem is supported since API 3.0.0, MenuItem only supports icons from API 3.4.0)
                new IconMenuItem(
                    routeName.equals("") ? "<unlabeled>" : routeName,
                    enabledStr + " " + reversedStr,
                    i,
                    new ColourIcon(settings.routeColour(i)),
                    {
                        // only get left or right, no center :(
                        :alignment => MenuItem.MENU_ITEM_LABEL_ALIGN_LEFT,
                    }
                )
            );
        }
    }

    function rerender() as Void {
        safeSetToggle(me, :settingsRoutesEnabled, settings.routesEnabled);
        safeSetToggle(me, :settingsDisplayRouteNames, settings.displayRouteNames);
        safeSetSubLabel(me, :settingsDisplayRouteMax, settings.routeMax().toString());
        for (var i = 0; i < settings.routeMax(); ++i) {
            var routeName = settings.routeName(i);
            safeSetLabel(me, i, routeName.equals("") ? "<unlabeled>" : routeName);
            safeSetIcon(me, i, new ColourIcon(settings.routeColour(i)));
            safeSetSubLabel(me, i, settings.routeEnabled(i) ? "Enabled" : "Disabled");
        }
    }
}

(:settingsView)
class SettingsMainDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMain;
    function initialize(view as SettingsMain) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsMainActivityType) {
            WatchUi.pushView(
                new Rez.Menus.SettingsActivityType(),
                new SettingsActivityTypeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsMode(),
                new $.SettingsModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainModeUiMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsUiMode(),
                new $.SettingsUiModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainModeElevationMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsElevationMode(),
                new $.SettingsElevationModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainRecalculateIntervalS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setRecalculateIntervalS),
                    settings.recalculateIntervalS,
                    view
                )
            );
        } else if (itemId == :settingsMainRenderMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsRenderMode(),
                new $.SettingsRenderModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainCenterUserOffsetY) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setCenterUserOffsetY),
                    settings.centerUserOffsetY,
                    view
                )
            );
        } else if (itemId == :settingsMainDisplayLatLong) {
            settings.toggleDisplayLatLong();
            view.rerender();
        } else if (itemId == :settingsMainMaxTrackPoints) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMaxTrackPoints),
                    settings.maxTrackPoints,
                    view
                )
            );
        } else if (itemId == :settingsMainZoomAtPace) {
            var view = new $.SettingsZoomAtPace();
            WatchUi.pushView(view, new $.SettingsZoomAtPaceDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainRoutes) {
            var view = new $.SettingsRoutes(settings);
            WatchUi.pushView(
                view,
                new $.SettingsRoutesDelegate(view, settings),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainMap) {
            if (settings.mapEnabled) {
                var view = new SettingsMap();
                WatchUi.pushView(view, new $.SettingsMapDelegate(view), WatchUi.SLIDE_IMMEDIATE);
                return;
            }
            var disabledView = new SettingsMapDisabled();
            WatchUi.pushView(
                disabledView,
                new $.SettingsMapDisabledDelegate(disabledView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainAlerts) {
            if (settings.offTrackWrongDirection || settings.enableOffTrackAlerts) {
                var view = new SettingsAlerts();
                WatchUi.pushView(view, new $.SettingsAlertsDelegate(view), WatchUi.SLIDE_IMMEDIATE);
                return;
            }
            var disabledView = new SettingsAlertsDisabled();
            WatchUi.pushView(
                disabledView,
                new $.SettingsAlertsDisabledDelegate(disabledView),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainColours) {
            var view = new SettingsColours();
            WatchUi.pushView(view, new $.SettingsColoursDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainDebug) {
            var view = new SettingsDebug();
            WatchUi.pushView(view, new $.SettingsDebugDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainMapMoveScreenSize) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setMapMoveScreenSize),
                    settings.mapMoveScreenSize,
                    view
                )
            );
        } else if (itemId == :settingsMainClearStorage) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.clearStorage) as String
            );
            WatchUi.pushView(dialog, new ClearStorageDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainReturnToUser) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.returnToUserTitle) as String
            );
            WatchUi.pushView(dialog, new ReturnToUserDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMainResetDefaults) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.resetDefaults) as String
            );
            WatchUi.pushView(dialog, new ResetSettingsDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

(:noSettingsView)
class SettingsMainDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMain;
    function initialize(view as SettingsMain) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsMainActivityType) {
            WatchUi.pushView(
                new Rez.Menus.SettingsActivityType(),
                new SettingsActivityTypeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMainMapAttribution) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsMapAttribution(),
                new $.SettingsMapAttributionDelegate(),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView)
class ResetSettingsDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getApp()._breadcrumbContext.settings.resetDefaults();
        }

        return true; // we always handle it
    }
}

(:settingsView)
class ReturnToUserDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getApp()._breadcrumbContext.cachedValues.returnToUser();
        }

        return true; // we always handle it
    }
}

(:settingsView)
class ClearStorageDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            Application.Storage.clearValues(); // purge the storage, but we have to clean up all our classes that load from storage too
            getApp()._breadcrumbContext.tileCache._storageTileCache.reset(); // reload our tile storage class
            getApp()._breadcrumbContext.tileCache.clearValues(); // also clear the tile cache, it case it pulled from our storage
            getApp()._breadcrumbContext.clearRoutes(); // also clear the routes to mimic storage being removed
            getApp()._breadcrumbContext.settings.storageCleared();
        }

        return true; // we always handle it
    }
}

(:settingsView)
class ClearCachedTilesDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getApp()._breadcrumbContext.tileCache._storageTileCache.clearValues();
            getApp()._breadcrumbContext.tileCache.clearValues(); // also clear the tile cache, in case it pulled from our storage

            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop confirmation
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop map storage view
            var view = new $.SettingsMapStorage();
            WatchUi.pushView(view, new $.SettingsMapStorageDelegate(view), WatchUi.SLIDE_IMMEDIATE); // replace with new updated map storage view
            WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the confirmation to pop
        }

        return true; // we always handle it
    }
}

(:settingsView)
class StartCachedTilesDelegate extends WatchUi.ConfirmationDelegate {
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getApp()._breadcrumbContext.cachedValues.startCacheCurrentMapArea();
        }

        return true; // we always handle it
    }
}

(:settingsView)
class DeleteRouteDelegate extends WatchUi.ConfirmationDelegate {
    var routeId as Number;
    var settings as Settings;
    function initialize(_routeId as Number, _settings as Settings) {
        WatchUi.ConfirmationDelegate.initialize();
        routeId = _routeId;
        settings = _settings;
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getApp()._breadcrumbContext.clearRoute(routeId);

            // WARNING: this is a massive hack, probably dependant on platform
            // just poping the vew and replacing does not work, because the confirmation is still active whilst we are in this function
            // so we need to pop the confirmation too
            // but the confirmation is also about to call WatchUi.popView()
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop confirmation
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop route view
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop routes view
            var view = new $.SettingsRoutes(settings);
            WatchUi.pushView(
                view,
                new $.SettingsRoutesDelegate(view, settings),
                WatchUi.SLIDE_IMMEDIATE
            ); // replace with new updated routes view
            WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the confirmation to pop
        }

        return true; // we always handle it
    }
}

(:settingsView)
class SettingsModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsMain;
    function initialize(parent as SettingsMain) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsModeTrackRoute) {
            settings.setMode(MODE_NORMAL);
        } else if (itemId == :settingsModeElevation) {
            settings.setMode(MODE_ELEVATION);
        } else if (itemId == :settingsModeMapMove) {
            settings.setMode(MODE_MAP_MOVE);
        } else if (itemId == :settingsModeMapDebug) {
            settings.setMode(MODE_DEBUG);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView)
class SettingsMapChoiceDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsTileServer;
    function initialize(parent as SettingsTileServer) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId() as Object;
        switch (itemId) {
            case :settingsMapChoiceCustom:
                settings.setMapChoice(0);
                break;
            case :settingsMapChoiceCompanionApp:
                settings.setMapChoice(1);
                break;
            case :settingsMapChoiceOpenTopoMap:
                settings.setMapChoice(2);
                break;
            case :settingsMapChoiceEsriWorldImagery:
                settings.setMapChoice(3);
                break;
            case :settingsMapChoiceEsriWorldStreetMap:
                settings.setMapChoice(4);
                break;
            case :settingsMapChoiceEsriWorldTopoMap:
                settings.setMapChoice(5);
                break;
            case :settingsMapChoiceEsriWorldTransportation:
                settings.setMapChoice(6);
                break;
            case :settingsMapChoiceEsriWorldDarkGrayBase:
                settings.setMapChoice(7);
                break;
            case :settingsMapChoiceEsriWorldHillshade:
                settings.setMapChoice(8);
                break;
            case :settingsMapChoiceEsriWorldHillshadeDark:
                settings.setMapChoice(9);
                break;
            case :settingsMapChoiceEsriWorldLightGrayBase:
                settings.setMapChoice(10);
                break;
            case :settingsMapChoiceEsriUSATopoMaps:
                settings.setMapChoice(11);
                break;
            case :settingsMapChoiceEsriWorldOceanBase:
                settings.setMapChoice(12);
                break;
            case :settingsMapChoiceEsriWorldShadedRelief:
                settings.setMapChoice(13);
                break;
            case :settingsMapChoiceEsriNatGeoWorldMap:
                settings.setMapChoice(14);
                break;
            case :settingsMapChoiceEsriWorldNavigationCharts:
                settings.setMapChoice(15);
                break;
            case :settingsMapChoiceEsriWorldPhysicalMap:
                settings.setMapChoice(16);
                break;
            case :settingsMapChoiceOpenStreetMapcyclosm:
                settings.setMapChoice(17);
                break;
            case :settingsMapChoiceStadiaAlidadeSmooth:
                settings.setMapChoice(18);
                break;
            case :settingsMapChoiceStadiaAlidadeSmoothDark:
                settings.setMapChoice(19);
                break;
            case :settingsMapChoiceStadiaOutdoors:
                settings.setMapChoice(20);
                break;
            case :settingsMapChoiceStadiaStamenToner:
                settings.setMapChoice(21);
                break;
            case :settingsMapChoiceStadiaStamenTonerLite:
                settings.setMapChoice(22);
                break;
            case :settingsMapChoiceStadiaStamenTerrain:
                settings.setMapChoice(23);
                break;
            case :settingsMapChoiceStadiaStamenWatercolor:
                settings.setMapChoice(24);
                break;
            case :settingsMapChoiceStadiaOSMBright:
                settings.setMapChoice(25);
                break;
            case :settingsMapChoiceCartoVoyager:
                settings.setMapChoice(26);
                break;
            case :settingsMapChoiceCartoDarkMatter:
                settings.setMapChoice(27);
                break;
            case :settingsMapChoiceCartoDarkLightAll:
                settings.setMapChoice(28);
                break;
            case :settingsMapChoiceMapyBasic:
                settings.setMapChoice(29);
                break;
            case :settingsMapChoiceMapyOutdoor:
                settings.setMapChoice(30);
                break;
            case :settingsMapChoiceMapyWinter:
                settings.setMapChoice(31);
                break;
            case :settingsMapChoiceMapyAerial:
                settings.setMapChoice(32);
                break;
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView)
class SettingsPackingFormatDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsMap;
    function initialize(parent as SettingsMap) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId() as Object;
        switch (itemId) {
            case :settingsPackingFormatDefault:
                settings.setPackingFormat(0);
                break;
            case :settingsPackingFormatYUV:
                settings.setPackingFormat(1);
                break;
            case :settingsPackingFormatPNG:
                settings.setPackingFormat(2);
                break;
            case :settingsPackingFormatJPG:
                settings.setPackingFormat(3);
                break;
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

class SettingsMapAttributionDelegate extends WatchUi.Menu2InputDelegate {
    function initialize() {
        WatchUi.Menu2InputDelegate.initialize();
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId() as Object;
        switch (itemId) {
            case :settingsMapAttributionOpenTopoMap:
                Communications.openWebPage("https://opentopomap.org/about", {}, {});
                break;
            case :settingsMapAttributionGoogle:
                Communications.openWebPage("https://cloud.google.com/maps-platform/terms", {}, {});
                break;
            case :settingsMapAttributionEsri:
                Communications.openWebPage("https://www.esri.com", {}, {});
                break;
            case :settingsMapAttributionOpenStreetmap:
                Communications.openWebPage("https://openstreetmap.org/copyright", {}, {});
                break;
            case :settingsMapAttributionStadia:
                Communications.openWebPage("https://stadiamaps.com/", {}, {});
                break;
            case :settingsMapAttributionOpenMapTiles:
                Communications.openWebPage("https://openmaptiles.org/", {}, {});
                break;
            case :settingsMapAttributionCarto:
                Communications.openWebPage("https://carto.com/attributions/", {}, {});
                break;
            case :settingsMapAttributionMapy:
                Communications.openWebPage("https://mapy.com/", {}, {});
                break;
        }

        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView)
class SettingsUiModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsMain;
    function initialize(parent as SettingsMain) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsUiModeShowall) {
            settings.setUiMode(UI_MODE_SHOW_ALL);
        } else if (itemId == :settingsUiModeHidden) {
            settings.setUiMode(UI_MODE_HIDDEN);
        } else if (itemId == :settingsUiModeNone) {
            settings.setUiMode(UI_MODE_NONE);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView)
class SettingsElevationModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsMain;
    function initialize(parent as SettingsMain) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsElevationModeStacked) {
            settings.setElevationMode(ELEVATION_MODE_STACKED);
        } else if (itemId == :settingsElevationModeOrderedRoutes) {
            settings.setElevationMode(ELEVATION_MODE_ORDERED_ROUTES);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView)
class SettingsAlertTypeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsAlerts or SettingsAlertsDisabled;
    function initialize(parent as SettingsAlerts or SettingsAlertsDisabled) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsAlertTypeToast) {
            settings.setAlertType(ALERT_TYPE_TOAST);
        } else if (itemId == :settingsAlertTypeImage) {
            settings.setAlertType(ALERT_TYPE_IMAGE);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView)
class SettingsRenderModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsMain;
    function initialize(parent as SettingsMain) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsRenderModeBufferedRotating) {
            settings.setRenderMode(RENDER_MODE_BUFFERED_ROTATING);
        } else if (itemId == :settingsRenderModeUnbufferedRotating) {
            settings.setRenderMode(RENDER_MODE_UNBUFFERED_ROTATING);
        } else if (itemId == :settingsRenderModeBufferedNoRotating) {
            settings.setRenderMode(RENDER_MODE_BUFFERED_NO_ROTATION);
        } else if (itemId == :settingsRenderModeNoBufferedNoRotating) {
            settings.setRenderMode(RENDER_MODE_UNBUFFERED_NO_ROTATION);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView)
class SettingsZoomAtPaceDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsZoomAtPace;
    function initialize(view as SettingsZoomAtPace) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsZoomAtPaceMode) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsZoomAtPaceMode(),
                new $.SettingsZoomAtPaceModeDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsZoomAtPaceUserMeters) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMetersAroundUser),
                    settings.metersAroundUser,
                    view
                )
            );
        } else if (itemId == :settingsZoomAtPaceMPS) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setZoomAtPaceSpeedMPS),
                    settings.zoomAtPaceSpeedMPS,
                    view
                )
            );
        }
    }
}

(:settingsView)
class SettingsRoutesDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsRoutes;
    var settings as Settings;
    function initialize(view as SettingsRoutes, settings as Settings) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
        me.settings = settings;
    }

    function setRouteMax(value as Number) as Void {
        settings.setRouteMax(value);
        // reload our ui, so any route changes are cleared
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // remove the number picker view
        reloadView();
        WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the number picker to remove
    }

    function reloadView() as Void {
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        var view = new $.SettingsRoutes(settings);
        WatchUi.pushView(
            view,
            new $.SettingsRoutesDelegate(view, settings),
            WatchUi.SLIDE_IMMEDIATE
        );
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        if (itemId == :settingsRoutesEnabled) {
            settings.toggleRoutesEnabled();
            reloadView();
        } else if (itemId == :settingsDisplayRouteNames) {
            settings.toggleDisplayRouteNames();
            view.rerender();
        } else if (itemId == :settingsDisplayRouteMax) {
            startPicker(new SettingsNumberPicker(method(:setRouteMax), settings.routeMax(), view));
        } else if (itemId == :settingsRoutesClearAll) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.clearRoutes1) as String
            );
            WatchUi.pushView(dialog, new ClearRoutesDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }

        // itemId should now be the route storageIndex = routeId
        if (itemId instanceof Number) {
            var thisView = new $.SettingsRoute(settings, itemId, view);
            WatchUi.pushView(
                thisView,
                new $.SettingsRouteDelegate(thisView, settings),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView)
class SettingsRouteDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsRoute;
    var settings as Settings;
    function initialize(view as SettingsRoute, settings as Settings) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
        me.settings = settings;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();
        if (itemId == :settingsRouteName) {
            var pickerView = new TextPickerView(
                "Route Name",
                "",
                0,
                256,
                settings.routeName(view.routeId)
            );
            var picker = new SettingsStringPicker(view.method(:setName), view, pickerView);
            WatchUi.pushView(pickerView, picker, WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsRouteEnabled) {
            if (view.routeEnabled()) {
                view.setEnabled(false);
            } else {
                view.setEnabled(true);
            }
            view.rerender();
        } else if (itemId == :settingsRouteReversed) {
            if (view.routeReversed()) {
                view.setReversed(false);
            } else {
                view.setReversed(true);
            }
            view.rerender();
        } else if (itemId == :settingsRouteColour) {
            startPicker(
                new SettingsColourPicker(view.method(:setColour), view.routeColour(), view)
            );
        } else if (itemId == :settingsRouteDelete) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.routeDelete) as String
            );
            WatchUi.pushView(
                dialog,
                new DeleteRouteDelegate(view.routeId, settings),
                WatchUi.SLIDE_IMMEDIATE
            );
        }
    }
}

(:settingsView)
class SettingsZoomAtPaceModeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsZoomAtPace;
    function initialize(parent as SettingsZoomAtPace) {
        WatchUi.Menu2InputDelegate.initialize();
        me.parent = parent;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsZoomAtPaceModePace) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_PACE);
        } else if (itemId == :settingsZoomAtPaceModeStopped) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_STOPPED);
        } else if (itemId == :settingsZoomAtPaceModeNever) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_NEVER_ZOOM);
        } else if (itemId == :settingsZoomAtPaceModeAlways) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_ALWAYS_ZOOM);
        } else if (itemId == :settingsZoomAtPaceModeRoutesWithoutTrack) {
            settings.setZoomAtPaceMode(ZOOM_AT_PACE_MODE_SHOW_ROUTES_WITHOUT_TRACK);
        }

        parent.rerender();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}

(:settingsView)
class SettingsMapDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMap;
    function initialize(view as SettingsMap) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsMapEnabled) {
            settings.setMapEnabled(false);
            var view = new SettingsMapDisabled();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(
                view,
                new $.SettingsMapDisabledDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMapTileCacheSize) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setTileCacheSize),
                    settings.tileCacheSize,
                    view
                )
            );
        } else if (itemId == :settingsMapTileCachePadding) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setTileCachePadding),
                    settings.tileCachePadding,
                    view
                )
            );
        } else if (itemId == :settingsMapMaxPendingWebRequests) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setMaxPendingWebRequests),
                    settings.maxPendingWebRequests,
                    view
                )
            );
        } else if (itemId == :settingsMapDisableMapsFailureCount) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setDisableMapsFailureCount),
                    settings.disableMapsFailureCount,
                    view
                )
            );
        } else if (itemId == :settingsMapHttpErrorTileTTLS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setHttpErrorTileTTLS),
                    settings.httpErrorTileTTLS,
                    view
                )
            );
        } else if (itemId == :settingsMapErrorTileTTLS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setErrorTileTTLS),
                    settings.errorTileTTLS,
                    view
                )
            );
        } else if (itemId == :settingsMapFixedLatitude) {
            var fixedLatitude = settings.fixedLatitude;
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setFixedLatitude),
                    fixedLatitude != null ? fixedLatitude : 0f,
                    view
                )
            );
        } else if (itemId == :settingsMapFixedLongitude) {
            var fixedLongitude = settings.fixedLongitude;
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setFixedLongitude),
                    fixedLongitude != null ? fixedLongitude : 0f,
                    view
                )
            );
        } else if (itemId == :settingsMapScaleRestrictedToTileLayers) {
            settings.toggleScaleRestrictedToTileLayers();
            view.rerender();
        } else if (itemId == :settingsMapAttribution) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsMapAttribution(),
                new $.SettingsMapAttributionDelegate(),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMapUseDrawBitmap) {
            settings.toggleUseDrawBitmap();
            view.rerender();
        } else if (itemId == :settingsMapPackingFormat) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsPackingFormat(),
                new $.SettingsPackingFormatDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsMapStorageSettings) {
            var view = new SettingsMapStorage();
            WatchUi.pushView(view, new $.SettingsMapStorageDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMapTileServerSettings) {
            var view = new SettingsTileServer();
            WatchUi.pushView(view, new $.SettingsTileServerDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

(:settingsView)
class SettingsTileServerDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsTileServer;
    function initialize(view as SettingsTileServer) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsMapChoice) {
            WatchUi.pushView(
                new $.Rez.Menus.SettingsMapChoice(),
                new $.SettingsMapChoiceDelegate(view),
                WatchUi.SLIDE_IMMEDIATE
            );
        } else if (itemId == :settingsTileUrl) {
            var pickerView = new TextPickerView("Tile Url", "", 0, 256, settings.tileUrl);
            var picker = new SettingsStringPicker(settings.method(:setTileUrl), view, pickerView);
            WatchUi.pushView(pickerView, picker, WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsAuthToken) {
            var pickerView = new TextPickerView("Auth Token", "", 0, 256, settings.authToken);
            var picker = new SettingsStringPicker(settings.method(:setAuthToken), view, pickerView);
            WatchUi.pushView(pickerView, picker, WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMapTileSize) {
            startPicker(
                new SettingsNumberPicker(settings.method(:setTileSize), settings.tileSize, view)
            );
        } else if (itemId == :settingsMapFullTileSize) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setFullTileSize),
                    settings.fullTileSize,
                    view
                )
            );
        } else if (itemId == :settingsMapScaledTileSize) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setScaledTileSize),
                    settings.scaledTileSize,
                    view
                )
            );
        } else if (itemId == :settingsMapTileLayerMax) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setTileLayerMax),
                    settings.tileLayerMax,
                    view
                )
            );
        } else if (itemId == :settingsMapTileLayerMin) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setTileLayerMin),
                    settings.tileLayerMin,
                    view
                )
            );
        }
    }
}

(:settingsView)
class SettingsMapStorageDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMapStorage;
    function initialize(view as SettingsMapStorage) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsMapStorageCacheTilesInStorage) {
            settings.toggleCacheTilesInStorage();
            view.rerender();
        } else if (itemId == :settingsMapStorageStorageMapTilesOnly) {
            settings.toggleStorageMapTilesOnly();
            view.rerender();
        } else if (itemId == :settingsMapStorageStorageSeedBoundingBox) {
            settings.toggleStorageSeedBoundingBox();
            view.rerender();
        } else if (itemId == :settingsMapStorageStorageTileCacheSize) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setStorageTileCacheSize),
                    settings.storageTileCacheSize,
                    view
                )
            );
        } else if (itemId == :settingsMapStorageStorageTileCachePageCount) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setStorageTileCachePageCount),
                    settings.storageTileCachePageCount,
                    view
                )
            );
        } else if (itemId == :settingsMapStorageStorageSeedRouteDistanceM) {
            startPicker(
                new SettingsFloatPicker(
                    settings.method(:setStorageSeedRouteDistanceM),
                    settings.storageSeedRouteDistanceM,
                    view
                )
            );
        } else if (itemId == :settingsMapStorageCacheCurrentArea) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.startTileCache1) as String
            );
            WatchUi.pushView(dialog, new StartCachedTilesDelegate(), WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMapStorageCancelCacheDownload) {
            getApp()._breadcrumbContext.cachedValues.cancelCacheCurrentMapArea();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :settingsMapStorageClearCachedTiles) {
            var dialog = new WatchUi.Confirmation(
                WatchUi.loadResource(Rez.Strings.clearCachedTiles) as String
            );
            WatchUi.pushView(dialog, new ClearCachedTilesDelegate(), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

(:settingsView)
class SettingsMapDisabledDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsMapDisabled;
    function initialize(view as SettingsMapDisabled) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsMapEnabled) {
            settings.setMapEnabled(true);
            var view = new SettingsMap();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.pushView(view, new $.SettingsMapDelegate(view), WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

(:settingsView)
function checkAlertViewDisplay(
    oldView as SettingsAlerts or SettingsAlertsDisabled,
    settings as Settings
) as Void {
    if (
        oldView instanceof SettingsAlerts &&
        !settings.offTrackWrongDirection &&
        !settings.enableOffTrackAlerts
    ) {
        var view = new SettingsAlertsDisabled();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(view, new $.SettingsAlertsDisabledDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    } else if (
        oldView instanceof SettingsAlertsDisabled &&
        (settings.offTrackWrongDirection || settings.enableOffTrackAlerts)
    ) {
        var view = new SettingsAlerts();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        WatchUi.pushView(view, new $.SettingsAlertsDelegate(view), WatchUi.SLIDE_IMMEDIATE);
    } else {
        oldView.rerender();
    }
}

(:settingsView)
function onSelectAlertCommon(
    itemId as Object?,
    settings as Settings,
    view as SettingsAlerts or SettingsAlertsDisabled
) as Void {
    if (itemId == :settingsAlertsDrawLineToClosestPoint) {
        settings.toggleDrawLineToClosestPoint();
        view.rerender();
    } else if (itemId == :settingsAlertsEnabled) {
        settings.toggleEnableOffTrackAlerts();
        checkAlertViewDisplay(view, settings);
    } else if (itemId == :settingsAlertsOffTrackWrongDirection) {
        settings.toggleOffTrackWrongDirection();
        checkAlertViewDisplay(view, settings);
    } else if (itemId == :settingsAlertsDrawCheverons) {
        settings.toggleDrawCheverons();
        view.rerender();
    } else if (itemId == :settingsAlertsOffTrackDistanceM) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setOffTrackAlertsDistanceM),
                settings.offTrackAlertsDistanceM,
                view
            )
        );
    } else if (itemId == :settingsAlertsTurnAlertTimeS) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setTurnAlertTimeS),
                settings.turnAlertTimeS,
                view
            )
        );
    } else if (itemId == :settingsAlertsMinTurnAlertDistanceM) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setMinTurnAlertDistanceM),
                settings.minTurnAlertDistanceM,
                view
            )
        );
    } else if (itemId == :settingsAlertsOffTrackCheckIntervalS) {
        startPicker(
            new SettingsNumberPicker(
                settings.method(:setOffTrackCheckIntervalS),
                settings.offTrackCheckIntervalS,
                view
            )
        );
    } else if (itemId == :settingsAlertsAlertType) {
        WatchUi.pushView(
            new $.Rez.Menus.SettingsAlertType(),
            new $.SettingsAlertTypeDelegate(view),
            WatchUi.SLIDE_IMMEDIATE
        );
    }
}

(:settingsView)
class SettingsAlertsDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsAlerts;
    function initialize(view as SettingsAlerts) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();

        if (itemId == :settingsAlertsOffTrackAlertsMaxReportIntervalS) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setOffTrackAlertsMaxReportIntervalS),
                    settings.offTrackAlertsMaxReportIntervalS,
                    view
                )
            );
            return;
        }

        onSelectAlertCommon(itemId, settings, view);
    }
}

(:settingsView)
class SettingsAlertsDisabledDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsAlertsDisabled;
    function initialize(view as SettingsAlertsDisabled) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        onSelectAlertCommon(itemId, settings, view);
    }
}

(:settingsView)
class DummyView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }
}

(:settingsView)
class ClearRoutesDelegate extends WatchUi.ConfirmationDelegate {
    var settings as Settings;
    function initialize() {
        WatchUi.ConfirmationDelegate.initialize();
        self.settings = getApp()._breadcrumbContext.settings;
    }
    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            getApp()._breadcrumbContext.clearRoutes();

            // WARNING: this is a massive hack, probably dependant on platform
            // just poping the vew and replacing does not work, because the confirmation is still active whilst we are in this function
            // so we need to pop the confirmation too
            // but the confirmation is also about to call WatchUi.popView()
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop confirmation
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop routes view
            var view = new $.SettingsRoutes(settings);
            WatchUi.pushView(
                view,
                new $.SettingsRoutesDelegate(view, settings),
                WatchUi.SLIDE_IMMEDIATE
            ); // replace with new updated routes view
            WatchUi.pushView(new DummyView(), null, WatchUi.SLIDE_IMMEDIATE); // push dummy view for the confirmation to pop
        }

        return true; // we always handle it
    }
}

(:settingsView)
class SettingsColoursDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsColours;
    function initialize(view as SettingsColours) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsColoursTrackColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setTrackColour),
                    settings.trackColour,
                    view
                )
            );
        } else if (itemId == :settingsColoursDefaultRouteColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setDefaultRouteColour),
                    settings.defaultRouteColour,
                    view
                )
            );
        } else if (itemId == :settingsColoursElevationColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setElevationColour),
                    settings.elevationColour,
                    view
                )
            );
        } else if (itemId == :settingsColoursUserColour) {
            startPicker(
                new SettingsColourPicker(settings.method(:setUserColour), settings.userColour, view)
            );
        } else if (itemId == :settingsColoursNormalModeColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setNormalModeColour),
                    settings.normalModeColour,
                    view
                )
            );
        } else if (itemId == :settingsColoursUiColour) {
            startPicker(
                new SettingsColourPicker(settings.method(:setUiColour), settings.uiColour, view)
            );
        } else if (itemId == :settingsColoursDebugColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setDebugColour),
                    settings.debugColour,
                    view
                )
            );
        }
    }
}

(:settingsView)
class SettingsDebugDelegate extends WatchUi.Menu2InputDelegate {
    var view as SettingsDebug;
    function initialize(view as SettingsDebug) {
        WatchUi.Menu2InputDelegate.initialize();
        me.view = view;
    }
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        if (itemId == :settingsDebugTileErrorColour) {
            startPicker(
                new SettingsColourPicker(
                    settings.method(:setTileErrorColour),
                    settings.tileErrorColour,
                    view
                )
            );
        } else if (itemId == :settingsDebugShowPoints) {
            settings.toggleShowPoints();
            view.rerender();
        } else if (itemId == :settingsDebugDrawLineToClosestTrack) {
            settings.toggleDrawLineToClosestTrack();
            view.rerender();
        } else if (itemId == :settingsDebugShowTileBorders) {
            settings.toggleShowTileBorders();
            view.rerender();
        } else if (itemId == :settingsDebugShowErrorTileMessages) {
            settings.toggleShowErrorTileMessages();
            view.rerender();
        } else if (itemId == :settingsDebugIncludeDebugPageInOnScreenUi) {
            settings.toggleIncludeDebugPageInOnScreenUi();
            view.rerender();
        } else if (itemId == :settingsDebugDrawHitBoxes) {
            settings.toggleDrawHitBoxes();
            view.rerender();
        } else if (itemId == :settingsDebugShowDirectionPoints) {
            settings.toggleShowDirectionPoints();
            view.rerender();
        } else if (itemId == :settingsDebugShowDirectionPointTextUnderIndex) {
            startPicker(
                new SettingsNumberPicker(
                    settings.method(:setShowDirectionPointTextUnderIndex),
                    settings.showDirectionPointTextUnderIndex,
                    view
                )
            );
        }
    }
}

class SettingsActivityTypeDelegate extends WatchUi.Menu2InputDelegate {
    var parent as SettingsMain;

    function initialize(parentView as SettingsMain) {
        Menu2InputDelegate.initialize();
        parent = parentView;
    }

    public function onSelect(item as WatchUi.MenuItem) as Void {
        var settings = getApp()._breadcrumbContext.settings;
        var itemId = item.getId();
        var combinedValue = 0; // Default to Generic

        if(itemId != null)
        {
        // This switch statement maps the menu item ID back to the combined numeric value
        switch (itemId) {
            case :ActGeneric:
                combinedValue = 0;
                break;
            case :ActRun:
                combinedValue = 1000;
                break;
            case :ActRunTreadmill:
                combinedValue = 1001;
                break;
            case :ActRunStreet:
                combinedValue = 1002;
                break;
            case :ActRunTrail:
                combinedValue = 1003;
                break;
            case :ActRunTrack:
                combinedValue = 1004;
                break;
            case :ActRunIndoor:
                combinedValue = 1045;
                break;
            case :ActRunVirtual:
                combinedValue = 1058;
                break;
            case :ActRunObstacle:
                combinedValue = 1059;
                break;
            case :ActRunUltra:
                combinedValue = 1067;
                break;
            case :ActCycle:
                combinedValue = 2000;
                break;
            case :ActCycleSpin:
                combinedValue = 2005;
                break;
            case :ActCycleIndoor:
                combinedValue = 2006;
                break;
            case :ActCycleRoad:
                combinedValue = 2007;
                break;
            case :ActCycleMtn:
                combinedValue = 2008;
                break;
            case :ActCycleDownhill:
                combinedValue = 2009;
                break;
            case :ActCycleRecumbent:
                combinedValue = 2010;
                break;
            case :ActCycleCyclocross:
                combinedValue = 2011;
                break;
            case :ActCycleHand:
                combinedValue = 2012;
                break;
            case :ActCycleTrack:
                combinedValue = 2013;
                break;
            case :ActCycleBmx:
                combinedValue = 2029;
                break;
            case :ActCycleGravel:
                combinedValue = 2046;
                break;
            case :ActCycleCommute:
                combinedValue = 2048;
                break;
            case :ActCycleMixed:
                combinedValue = 2049;
                break;
            case :ActTransition:
                combinedValue = 3000;
                break;
            case :ActFitness:
                combinedValue = 4000;
                break;
            case :ActFitRow:
                combinedValue = 4014;
                break;
            case :ActFitElliptical:
                combinedValue = 4015;
                break;
            case :ActFitStair:
                combinedValue = 4016;
                break;
            case :ActFitStrength:
                combinedValue = 4020;
                break;
            case :ActFitCardio:
                combinedValue = 4026;
                break;
            case :ActFitYoga:
                combinedValue = 4043;
                break;
            case :ActFitPilates:
                combinedValue = 4044;
                break;
            case :ActFitIndoorClimb:
                combinedValue = 4068;
                break;
            case :ActFitBouldering:
                combinedValue = 4069;
                break;
            case :ActSwim:
                combinedValue = 5000;
                break;
            case :ActSwimLap:
                combinedValue = 5017;
                break;
            case :ActSwimOpen:
                combinedValue = 5018;
                break;
            case :ActBasketball:
                combinedValue = 6000;
                break;
            case :ActSoccer:
                combinedValue = 7000;
                break;
            case :ActTennis:
                combinedValue = 8000;
                break;
            case :ActFootballUS:
                combinedValue = 9000;
                break;
            case :ActTraining:
                combinedValue = 10000;
                break;
            case :ActWalk:
                combinedValue = 11000;
                break;
            case :ActWalkIndoor:
                combinedValue = 11027;
                break;
            case :ActWalkCasual:
                combinedValue = 11030;
                break;
            case :ActWalkSpeed:
                combinedValue = 11031;
                break;
            case :ActXcSki:
                combinedValue = 12000;
                break;
            case :ActXcSkiSkate:
                combinedValue = 12042;
                break;
            case :ActAlpineSki:
                combinedValue = 13000;
                break;
            case :ActAlpineSkiBack:
                combinedValue = 13037;
                break;
            case :ActAlpineSkiResort:
                combinedValue = 13038;
                break;
            case :ActSnowboard:
                combinedValue = 14000;
                break;
            case :ActSnowboardBack:
                combinedValue = 14037;
                break;
            case :ActSnowboardResort:
                combinedValue = 14038;
                break;
            case :ActRowing:
                combinedValue = 15000;
                break;
            case :ActMountaineering:
                combinedValue = 16000;
                break;
            case :ActHiking:
                combinedValue = 17000;
                break;
            case :ActMulti:
                combinedValue = 18000;
                break;
            case :ActMultiTri:
                combinedValue = 18078;
                break;
            case :ActMultiDu:
                combinedValue = 18079;
                break;
            case :ActMultiBrick:
                combinedValue = 18080;
                break;
            case :ActMultiSwimrun:
                combinedValue = 18081;
                break;
            case :ActMultiAdvRace:
                combinedValue = 18082;
                break;
            case :ActPaddling:
                combinedValue = 19000;
                break;
            case :ActFlying:
                combinedValue = 20000;
                break;
            case :ActFlyingDrone:
                combinedValue = 20039;
                break;
            case :ActEbike:
                combinedValue = 21000;
                break;
            case :ActEbikeFit:
                combinedValue = 21028;
                break;
            case :ActEbikeMtn:
                combinedValue = 21047;
                break;
            case :ActMotorcycle:
                combinedValue = 22000;
                break;
            case :ActMotorcycleAtv:
                combinedValue = 22035;
                break;
            case :ActMotorcycleMx:
                combinedValue = 22036;
                break;
            case :ActBoating:
                combinedValue = 23000;
                break;
            case :ActBoatingSail:
                combinedValue = 23032;
                break;
            case :ActDriving:
                combinedValue = 24000;
                break;
            case :ActGolf:
                combinedValue = 25000;
                break;
            case :ActHangGliding:
                combinedValue = 26000;
                break;
            case :ActHorseback:
                combinedValue = 27000;
                break;
            case :ActHunting:
                combinedValue = 28000;
                break;
            case :ActFishing:
                combinedValue = 29000;
                break;
            case :ActInlineSkate:
                combinedValue = 30000;
                break;
            case :ActRockClimb:
                combinedValue = 31000;
                break;
            case :ActRockClimbIndoor:
                combinedValue = 31068;
                break;
            case :ActRockClimbBoulder:
                combinedValue = 31069;
                break;
            case :ActSailing:
                combinedValue = 32000;
                break;
            case :ActSailingRace:
                combinedValue = 32065;
                break;
            case :ActIceSkate:
                combinedValue = 33000;
                break;
            case :ActIceSkateHockey:
                combinedValue = 33073;
                break;
            case :ActSkyDiving:
                combinedValue = 34000;
                break;
            case :ActSkyDivingWingsuit:
                combinedValue = 34040;
                break;
            case :ActSnowshoe:
                combinedValue = 35000;
                break;
            case :ActSnowmobile:
                combinedValue = 36000;
                break;
            case :ActSup:
                combinedValue = 37000;
                break;
            case :ActSurfing:
                combinedValue = 38000;
                break;
            case :ActWakeboard:
                combinedValue = 39000;
                break;
            case :ActWaterSki:
                combinedValue = 40000;
                break;
            case :ActKayak:
                combinedValue = 41000;
                break;
            case :ActKayakWhite:
                combinedValue = 41041;
                break;
            case :ActRafting:
                combinedValue = 42000;
                break;
            case :ActRaftingWhite:
                combinedValue = 42041;
                break;
            case :ActWindsurf:
                combinedValue = 43000;
                break;
            case :ActKitesurf:
                combinedValue = 44000;
                break;
            case :ActTactical:
                combinedValue = 45000;
                break;
            case :ActJumpmaster:
                combinedValue = 46000;
                break;
            case :ActBoxing:
                combinedValue = 47000;
                break;
            case :ActFloorClimb:
                combinedValue = 48000;
                break;
            case :ActBaseball:
                combinedValue = 49000;
                break;
            case :ActSoftballFast:
                combinedValue = 50000;
                break;
            case :ActSoftballSlow:
                combinedValue = 51000;
                break;
            case :ActShooting:
                combinedValue = 56000;
                break;
            case :ActAutoRacing:
                combinedValue = 57000;
                break;
            case :ActWinterSport:
                combinedValue = 58000;
                break;
            case :ActGrinding:
                combinedValue = 59000;
                break;
            case :ActHealthMon:
                combinedValue = 60000;
                break;
            case :ActMarine:
                combinedValue = 61000;
                break;
            case :ActHiit:
                combinedValue = 62000;
                break;
            case :ActHiitAmrap:
                combinedValue = 62073;
                break;
            case :ActHiitEmom:
                combinedValue = 62074;
                break;
            case :ActHiitTabata:
                combinedValue = 62075;
                break;
            case :ActGaming:
                combinedValue = 63000;
                break;
            case :ActGamingEsport:
                combinedValue = 63077;
                break;
            case :ActRacket:
                combinedValue = 64000;
                break;
            case :ActRacketPickle:
                combinedValue = 64084;
                break;
            case :ActRacketPadel:
                combinedValue = 64085;
                break;
            case :ActRacketSquash:
                combinedValue = 64094;
                break;
            case :ActRacketBadminton:
                combinedValue = 64095;
                break;
            case :ActRacketRacquetball:
                combinedValue = 64096;
                break;
            case :ActRacketTableTennis:
                combinedValue = 64097;
                break;
            case :ActWheelWalk:
                combinedValue = 65000;
                break;
            case :ActWheelWalkIndoor:
                combinedValue = 65086;
                break;
            case :ActWheelRun:
                combinedValue = 66000;
                break;
            case :ActWheelRunIndoor:
                combinedValue = 66087;
                break;
            case :ActMeditation:
                combinedValue = 67000;
                break;
            case :ActMeditationBreath:
                combinedValue = 67062;
                break;
            case :ActParaSport:
                combinedValue = 68000;
                break;
            case :ActDiscGolf:
                combinedValue = 69000;
                break;
            case :ActTeamSport:
                combinedValue = 70000;
                break;
            case :ActTeamUltimate:
                combinedValue = 70092;
                break;
            case :ActCricket:
                combinedValue = 71000;
                break;
            case :ActRugby:
                combinedValue = 72000;
                break;
            case :ActHockey:
                combinedValue = 73000;
                break;
            case :ActHockeyField:
                combinedValue = 73090;
                break;
            case :ActHockeyIce:
                combinedValue = 73091;
                break;
            case :ActLacrosse:
                combinedValue = 74000;
                break;
            case :ActVolleyball:
                combinedValue = 75000;
                break;
            case :ActTube:
                combinedValue = 76000;
                break;
            case :ActWakesurf:
                combinedValue = 77000;
                break;
        }
        }

        // Call the new method in your settings class
        settings.setSportAndSubSport(combinedValue);

        // Rerender the parent menu to show the new selection
        parent.rerender();

        // Go back to the parent menu
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
}
