This is a mirror of the https://github.com/pauljohnston2025/breadcrumb-garmin repo with a few things switched to support breadcrumb as its own app.
There are subtle changes, and I expect it to diverge over time, but want to be able to keep everything up to date.
I could use monkey barrels to share common code, but they have a memory overhead, and I only expect 1 of these apps/datafields to be installed at a time.

This serves as the repo for the 'App' type of Breadcrumb, there may be some comments/documentation that still say datafield.

A garmin watch app that shows a breadcrumb trail. For watches that do not support breadcrumb navigation out of the box.

The app provides extra functionality, and enables companion app map tiles on more watches.

Donations are always welcome, but not required: https://www.paypal.com/paypalme/pauljohnston2025

Information on all the settings can be found in [Settings](settings.md)  
note: Map support is disabled by default, but can be turned on in app settings, this is because map tile loading is memory intensive and may cause crashes on some devices. You must set `Tile Cache Size` if using maps to avoid crashes.    
Companion app can be found at [Companion App](https://github.com/pauljohnston2025/breadcrumb-mobile.git)  
[Companion App Releases](https://github.com/pauljohnston2025/breadcrumb-mobile/releases/latest)

---

There are several different apps/datafields on the connect-iq store all with similar breadcrumb functionality 

Each one has its own repository mirror (git push --mirror https://github.com/pauljohnston2025/XXX.git).  
I could use monkey barrels to share common code, but barrels have a memory overhead, and I only expect 1 of these apps/datafields to be installed at a time.  
I also expect the merge conflicts will be easier to deal with rather than a whole heap of (:excludeAnnotations)  
Doing it this way also means each repo has 0 dependents and is fully stand-alone.   
There are multiple Datafield app types, so that users can install 2 alongside eachother if they want. eg. have both the BreadcrumbDataField and LWBreadcrumbDataField enabled at the same time so that if BreadcrumbDataField crashes from OOM or some high usage map task we can still navigate the planned route using LWBreadcrumbDataField.  If a user has 2 installed it would be good practice to disable alerts on one of the datafields, or you will get 2 independent alert for each 'off track' etc.  

The original project is https://github.com/pauljohnston2025/breadcrumb-garmin it contains the main datafield with all features on supported watches.

note: Some older devices will not support all of the features (eg. routes/ device settings) This is a garmin limitation as those devices (<3.2.0 api) do not support phone app messages for datafields.

The current mirrors are: 

* [BreadcrumbDataField](https://github.com/pauljohnston2025/breadcrumb-garmin) 
  * Type - DataField
  * Full breadcrumb trail with map tile support
* [BreadcrumbApp](https://github.com/pauljohnston2025/breadcrumb-garmin-app)
  * [Upstream mirror - BreadcrumbDataField](https://github.com/pauljohnston2025/breadcrumb-garmin)
  * Type - App
  * An app instead of a datafield
  * Full breadcrumb trail with map tile support
  * Adds more control
    * Support for non-touch screen devices, as it can handle button press events
    * Touch screens can drag the map around to pan
  * Supports more features on more devices (the app has larger memory limits than a datafield)
* [LWBreadcrumbDataField](https://github.com/pauljohnston2025/breadcrumb-garmin-light-weight)
  * [Upstream mirror - BreadcrumbDataField](https://github.com/pauljohnston2025/breadcrumb-garmin)
  * Type - DataField
  * Full breadcrumb trail (no map tile support)
* [ULBreadcrumbDataField](https://github.com/pauljohnston2025/breadcrumb-garmin-ultra-light)
  * [Upstream mirror - LWBreadcrumbDataField](https://github.com/pauljohnston2025/breadcrumb-garmin-light-weight)
  * Type - DataField
  * Limited breadcrumb trail (no map support, no alerts)
  * This is the lightest weight datafield and is supported on more devices, it is restricted to 1 route and 1 track and alot of customisation is missing

The companion app supports all of the watch apps, but the watch app must be selected in the companion app settings.


---

# Bug Reports

To aid in the fastest resolution, please include.

- Some screenshots of the issue, and possibly a recording
- A reproduction case of exactly how to reproduce the issue
- What you expected to happen
- The settings that you had enabled/disabled (a full screenshot of all the settings is best)

Please ensure any images/recordings do not contain any identifying information, such as your current location.

If the watch app encounters a crash (connect iq symbol displayed), you should also include the crash report. This can be obtained by:

* Connect the watch to a computer
* Open the contents of the watch and navigate to  `<watch>\Internal Storage\GARMIN\APPS\LOGS`
* Copy any log files, usually it is called CIQ_LOG.LOG, but may be called CIQ_LOG.BAK

You can also manually add a text file `BreadcrumbApp.TXT` to the log directory (before the crash), and any app logs will be printed there. Please also include this log file.

---

# Development

Must port forward both adb and the tile server for the simulator to be able to fetch tiles from the companion app

* adb forward tcp:8080 tcp:8080
* adb forward tcp:7381 tcp:7381

To merge in the upstream do

```
cd path/to/mirrored/repo  eg. breadcrumb-garmin-light-weight
git remote add old-repo https://github.com/pauljohnston2025/breadcrumb-garmin.git
git fetch old-repo --no-tags
git merge old-repo/master
```

---

# Map Tiles

Powered by Esri: https://www.esri.com  
OpenStreetMap: https://openstreetmap.org/copyright  
OpenTopoMap: https://opentopomap.org/about  
Google: https://cloud.google.com/maps-platform/terms https://policies.google.com/privacy  
Carto: https://carto.com/attribution  
Stadia: &copy; <a href="https://stadiamaps.com/" target="_blank">Stadia Maps</a> &copy; <a href="https://openmaptiles.org/" target="_blank">OpenMapTiles</a> &copy; <a href="https://www.openstreetmap.org/copyright" target="_blank">OpenStreetMap</a>  
Mapy: https://mapy.com/ https://api.mapy.com/copyright

---

# Licencing

Attribution-NonCommercial-ShareAlike 4.0 International: https://creativecommons.org/licenses/by-nc-sa/4.0/  

---
