import Toybox.WatchUi;
import Toybox.System;
import Toybox.Lang;

// see BreadcrumbDataFieldView if touch stops working
class BreadcrumbDelegate extends WatchUi.BehaviorDelegate {
    var _breadcrumbContext as BreadcrumbContext;
    private var _dragStartX as Number? = null;
    private var _dragStartY as Number? = null;

    function initialize(breadcrumbContext as BreadcrumbContext) {
        BehaviorDelegate.initialize();
        _breadcrumbContext = breadcrumbContext;
    }

    // onDrag is called when the user drags their finger across the screen
    // Handle map panning when the user drags their finger across the screen.
    function onDrag(dragEvent as WatchUi.DragEvent) as Lang.Boolean {
        System.println("onDrag: " + dragEvent.getType());
        // Only handle drag events if we are in map move mode.
        // we also allow it on the normal track page, since we can handle drag events in apps unlike on datafields.
        // perhaps on touchscreen devices this should be the only way to move?
        // it can be a bit finicky though, some users might still prefer the tapping interface (so ill leave both)
        if (_breadcrumbContext.settings.mode != MODE_MAP_MOVE && _breadcrumbContext.settings.mode != MODE_NORMAL) {
            return false;
        }

        var eventType = dragEvent.getType();
        var coords = dragEvent.getCoordinates();

        if (eventType == WatchUi.DRAG_TYPE_START) {
            // The user has started dragging. Record the initial coordinates.
            _dragStartX = coords[0];
            _dragStartY = coords[1];
        } else if (eventType == WatchUi.DRAG_TYPE_CONTINUE) {
            // The user is continuing a drag.
            // Safety check to ensure we have a starting point.
            var _dragStartXLocal = _dragStartX;
            var _dragStartYLocal = _dragStartY;
            if (_dragStartXLocal == null || _dragStartYLocal == null) {
                // some invalid state
                return true;
            }

            var cachedValues = _breadcrumbContext.cachedValues;

            // Calculate the distance dragged in pixels since the last event.
            var dx = (coords[0] as Number) - _dragStartXLocal;
            var dy = (coords[1] as Number) - _dragStartYLocal;

            // Update the stored coordinates to be the current point for the next continue event.
            _dragStartX = coords[0];
            _dragStartY = coords[1];

            var currentScale = cachedValues.currentScale;
            // Avoid division by zero if scale is not set.
            if (currentScale == 0.0f) {
                return true;
            }

            // Convert the pixel movement to meters using the current scale.
            var xMoveUnrotatedMeters = -dx / currentScale;
            var yMoveUnrotatedMeters = dy / currentScale;

            // Calculate the rotated movement to account for map orientation.
            var xMoveRotatedMeters =
                xMoveUnrotatedMeters * cachedValues.rotateCos +
                yMoveUnrotatedMeters * cachedValues.rotateSin;
            var yMoveRotatedMeters =
                -(xMoveUnrotatedMeters * cachedValues.rotateSin) +
                yMoveUnrotatedMeters * cachedValues.rotateCos;

            // Apply the calculated movement to the map's fixed position.
            cachedValues.moveLatLong(
                xMoveUnrotatedMeters,
                yMoveUnrotatedMeters,
                xMoveRotatedMeters,
                yMoveRotatedMeters
            );
        } else if (eventType == WatchUi.DRAG_TYPE_STOP) {
            // The user has stopped dragging. Reset the state variables.
            _dragStartX = null;
            _dragStartY = null;
        }

        return true;
    }

    function onFlick(flickEvent as WatchUi.FlickEvent) as Lang.Boolean {
        var direction = flickEvent.getDirection();
        System.println("Flick event deg: " + direction);

        return false; // let it propagate
    }

    function onSwipe(swipeEvent) {
        // prevent exit when we flick instead of drag
        System.println("onSwipe: " + swipeEvent.getDirection());
        return true; // this has to be true to prevent the default onback handler (that quits the app)
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
        var settingsView = getApp().myGetSettingsView();
        WatchUi.pushView(settingsView[0], settingsView[1], WatchUi.SLIDE_IMMEDIATE);
        return true;
    }

    // public function onSelect() as Boolean {
    // onselect never seems to work on venu2s, but KEY_ENTER works on all products
    // }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        logT("got key event: " + key);
        if (key == WatchUi.KEY_ENTER) {
            if (!_breadcrumbContext.session.isRecording()) {
                // If we are NOT recording, start the session.
                _breadcrumbContext.startSession(); // resume the session
                WatchUi.showToast("Activity Started", null);
            } else {
                var cachedValues = _breadcrumbContext.cachedValues;
                if (cachedValues.seeding()) {
                    cachedValues.cancelCacheCurrentMapArea();
                    return true;
                }

                // If recording, cycle through the main display modes. or return to user if we have moved/zoomed
                if (cachedValues.fixedPosition != null || cachedValues.scale != null) {
                    _breadcrumbContext.breadcrumbRenderer.returnToUser();
                } else {
                    _breadcrumbContext.settings.nextMode();
                }
            }

            return true;
        } else if (key == WatchUi.KEY_ESC) {
            if (_breadcrumbContext.session.isRecording()) {
                pauseAndConfirmExit(_breadcrumbContext);
                return true;
            }

            return false;
        }

        return false;
    }

    function onPreviousPage() as Boolean {
        System.println("onPreviousPage");
        var cachedValues = _breadcrumbContext.cachedValues;
        if (cachedValues.isTouchScreen) {
            // they should be pressing the screen, drag events are handled for map panning
            return false;  // let it propagate
        }
        var settings = _breadcrumbContext.settings;
        var renderer = _breadcrumbContext.breadcrumbRenderer;

        if (settings.mode == MODE_MAP_MOVE) {
            cachedValues.moveFixedPositionUp();
            return true;
        }
        renderer.incScale();
        return true;
    }

    function onNextPage() as Boolean {
        System.println("onNextPage");
        var cachedValues = _breadcrumbContext.cachedValues;
        if (cachedValues.isTouchScreen) {
            // they should be pressing the screen, drag events are handled for map panning
            return false;  // let it propagate
        }
        var settings = _breadcrumbContext.settings;
        var renderer = _breadcrumbContext.breadcrumbRenderer;

        if (settings.mode == MODE_MAP_MOVE) {
            cachedValues.moveFixedPositionDown();
        } else {
            renderer.decScale();
        }
        return true;
    }

    public function onBack() as Boolean {
        // touchscreens swipe right to call onback, prevent this, as we only want it to happen on key press
        // the swipe could be from a map pan drag and get misinterpreted as an onback
        System.println("onBack");
        return false; // let it propagate to the onKey handler
    }
}

function pauseAndConfirmExit(breadcrumbContext as BreadcrumbContext) as Void {
    breadcrumbContext.session.stop();
    var menuView = new Rez.Menus.Exit();
    var delegate = new ExitMenuDelegate(breadcrumbContext);
    WatchUi.pushView(menuView, delegate, WatchUi.SLIDE_IMMEDIATE);
}

class ExitMenuDelegate extends WatchUi.Menu2InputDelegate {
    var _breadcrumbContext as BreadcrumbContext;

    function initialize(context as BreadcrumbContext) {
        Menu2InputDelegate.initialize();
        _breadcrumbContext = context;
    }

    // This function is called when the user selects an item from the menu.
    public function onSelect(item as WatchUi.MenuItem) as Void {
        var itemId = item.getId();

        if (itemId == :resume) {
            // User wants to resume.
            // 1. Pop the menu off the screen.
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            // 2. Resume the session recording.
            _breadcrumbContext.startSession();
            WatchUi.showToast("Resumed", null);
        } else if (itemId == :saveAndExit) {
            // User wants to save and exit the app.
            // 1. Call your existing helper to save the session.
            _breadcrumbContext.stopAndSaveSession();
            WatchUi.showToast("Activity Saved", null);

            // 2. Exit the app completely by popping the main view.
            // Since the menu is on top, we pop it first, then the main app view.
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        } else if (itemId == :exitWithoutSaving) {
            // User wants to discard the activity.
            var message = "Discard Activity?";
            var confirmationView = new WatchUi.Confirmation(message);
            var delegate = new DiscardConfirmationDelegate(_breadcrumbContext);

            // Push the confirmation view to the user.
            WatchUi.pushView(confirmationView, delegate, WatchUi.SLIDE_IMMEDIATE);
        }
    }
}

// A delegate to handle the response from a confirmation dialog.
class DiscardConfirmationDelegate extends WatchUi.ConfirmationDelegate {
    var _breadcrumbContext as BreadcrumbContext;

    function initialize(context as BreadcrumbContext) {
        ConfirmationDelegate.initialize();
        _breadcrumbContext = context;
    }

    // This method is called when the user responds to the confirmation.
    function onResponse(response as WatchUi.Confirm) as Boolean {
        if (response == WatchUi.CONFIRM_YES) {
            // The user confirmed they want to discard the activity.
            // 1. Discard the session data.
            _breadcrumbContext.discardSession();
            WatchUi.showToast("Activity Discarded", null);

            // 2. Exit the app completely by popping both the menu
            //    and the main view from the view stack.
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        }
        // If the user selects "No" (CONFIRM_NO), the system automatically
        // pops the confirmation dialog, returning them to the previous menu.
        // No further action is needed from us.

        return true; // Indicate that we have handled the response.
    }
}
