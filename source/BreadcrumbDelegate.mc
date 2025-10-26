import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

// see BreadcrumbDataFieldView if touch stops working
class BreadcrumbDelegate extends WatchUi.BehaviorDelegate {
    var _breadcrumbContext as BreadcrumbContext;

    function initialize(breadcrumbContext as BreadcrumbContext) {
        BehaviorDelegate.initialize();
        _breadcrumbContext = breadcrumbContext;
    }

    // see BreadcrumbDataFieldView if touch stops working
    function onTap(evt as WatchUi.ClickEvent) as Boolean {
        if (getApp()._view.imageAlert != null) {
            // any touch cancels the alert
            getApp()._view.imageAlert = null;
            return true;
        }
        // logT("got tap (x,y): (" + evt.getCoordinates()[0] + "," +
        //                evt.getCoordinates()[1] + ")");

        var coords = evt.getCoordinates();
        var x = coords[0];
        var y = coords[1];
        var renderer = _breadcrumbContext.breadcrumbRenderer;
        var settings = _breadcrumbContext.settings;
        var cachedValues = _breadcrumbContext.cachedValues;

        var hitboxSize = renderer.hitboxSize;
        var halfHitboxSize = hitboxSize / 2.0f;

        if (settings.uiMode == UI_MODE_NONE) {
            return false;
        }

        if (cachedValues.seeding()) {
            // we are displaying the tile seed screen, only allow cancel
            if (y < hitboxSize) {
                // top of screen
                cachedValues.cancelCacheCurrentMapArea();
            }
            return true;
        }

        if (renderer.handleStartCacheRoute(x, y)) {
            return true;
        }

        if (renderer.handleStartMapEnable(x, y)) {
            return true;
        }

        if (renderer.handleStartMapDisable(x, y)) {
            return true;
        }

        if (renderer.handleClearRoute(x, y)) {
            // returns true if it handles touches on top left
            // also blocks input if we are in the menu
            return true;
        }

        // perhaps put this into new class to handle touch events, and have a
        // renderer for that ui would allow us to switch out ui and handle touched
        // differently also will alow setting the scren height
        if (inHitbox(x, y, renderer.modeSelectX, renderer.modeSelectY, halfHitboxSize)) {
            // top right
            settings.nextMode();
            return true;
        }

        if (settings.mode == MODE_DEBUG) {
            return false;
        }

        if (inHitbox(x, y, renderer.returnToUserX, renderer.returnToUserY, halfHitboxSize)) {
            // return to users location
            // bottom left
            // reset scale to user tracking mode (we auto set it when enterring move mode so we do not get weird zooms when we are panning)
            // there is a chance the user already had a custom scale set (by pressing the +/- zoom  buttons on the track page)
            // but we will just clear it when they click 'go back to user', and it will now be whatever is in the 'zoom at pace' settings
            renderer.returnToUser();
            return true;
        }
        //  else if (
        //     y > renderer.mapEnabledY - halfHitboxSize &&
        //     y < renderer.mapEnabledY + halfHitboxSize &&
        //     x > renderer.mapEnabledX - halfHitboxSize &&
        //     x < renderer.mapEnabledX + halfHitboxSize
        // ) {
        //     // botom right
        //     // map enable/disable now handled above
        //     // if (settings.mode == MODE_NORMAL) {
        //     //     settings.toggleMapEnabled();
        //     //     return true;
        //     // }

        //     return false;
        // }
        // todo update these to use inHitbox ?
        else if (y < hitboxSize) {
            if (settings.mode == MODE_MAP_MOVE) {
                cachedValues.moveFixedPositionUp();
                return true;
            }
            // top of screen
            renderer.incScale();
            return true;
        } else if (y > cachedValues.physicalScreenHeight - hitboxSize) {
            // bottom of screen
            if (settings.mode == MODE_MAP_MOVE) {
                cachedValues.moveFixedPositionDown();
                return true;
            }
            renderer.decScale();
            return true;
        } else if (x > cachedValues.physicalScreenWidth - hitboxSize) {
            // right of screen
            if (settings.mode == MODE_MAP_MOVE) {
                cachedValues.moveFixedPositionRight();
                return true;
            }
            // handled by handleStartCacheRoute
            // cachedValues.startCacheCurrentMapArea();
            return true;
        } else if (x < hitboxSize) {
            // left of screen
            if (settings.mode == MODE_MAP_MOVE) {
                cachedValues.moveFixedPositionLeft();
                return true;
            }
            settings.nextZoomAtPaceMode();
            return true;
        }

        return false;
    }

    public function onMenu() as Boolean {
        var settingsView = getApp().getSettingsView();
        WatchUi.pushView(settingsView[0], settingsView[1], WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    // public function onSelect() as Boolean {
    // onselect never seems to work on venu2s, but KEY_ENTER works on all products
    // }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        logT("got number picker key event: " + key);
        if (key == WatchUi.KEY_ENTER) {
            if (!_breadcrumbContext.session.isRecording()) {
                // If we are NOT recording, start the session.
                _breadcrumbContext.session.start();
                WatchUi.showToast("Activity Started", null);
            } else {
                // If we ARE recording, stop and save the session.
                // we need to force an exit when they confirm
                pauseAndConfirmExit(_breadcrumbContext, true);
            }

            return true;
        }

        return false;
    }

    // todo: currently start/stop is controlled by KEY_ENTER, just like in a datafield
    // Will have to update this when we want to handle the on screen ui for non-touch devices
    // need some cursor on screen or something, or just make zoomin/out the only allowed function for those devices?
    public function onBack() as Boolean {
        if (_breadcrumbContext.session.isRecording()) {
            // we are already trying to exit, so don't kill the app
            pauseAndConfirmExit(_breadcrumbContext, false);
            return true;
        }

        return false;
    }
}

function pauseAndConfirmExit(
    breadcrumbContext as BreadcrumbContext,
    killOnComplete as Boolean
) as Void {
    var dialog = new WatchUi.Confirmation(
        WatchUi.loadResource(Rez.Strings.saveAndExitConfirm) as String
    );

    var delegate = new SaveAndExitConfirmationDelegate(breadcrumbContext, killOnComplete);
    WatchUi.pushView(dialog, delegate, WatchUi.SLIDE_IMMEDIATE);
}

class SaveAndExitConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    var _breadcrumbContext as BreadcrumbContext;
    var _killOnComplete as Boolean;

    function initialize(context as BreadcrumbContext, killOnComplete as Boolean) {
        ConfirmationDelegate.initialize();
        _breadcrumbContext = context;
        _killOnComplete = killOnComplete;
        _breadcrumbContext.session.stop(); // pause the session
    }

    function onResponse(response as Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            _breadcrumbContext.stopAndSaveSession();
            WatchUi.showToast("Activity Saved", null);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); // pop the activity from the view stack, this exits the app
        }

        _breadcrumbContext.session.start(); // resume the session
        return true; // We handled the response.
    }
}
