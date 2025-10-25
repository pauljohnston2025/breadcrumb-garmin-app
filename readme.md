This is a mirror of the https://github.com/pauljohnston2025/breadcrumb-garmin repo with a few things switched to support breadcrumb as its own app.
There are subtle changes, and I expect it to diverge over time, but want to be able to keep everything up to date.
I could use monkey barrels to share common code, but they have a memory overhead, and I only expect 1 of these apps/datafields to be installed at a time.

This serves as the repo for the 'App' type of Breadcrumb, there may be some comments/documentation that still say datafield.

The Versioning scheme is 

0.X -> BreadcrumbDataField (we will reserve 0-9.X for the datafield app)
10.X -> BreadcrumbApp

A garmin watch app that shows a breadcrumb trail. For watches that do not support breadcrumb navigation out of the box.

Donations are always welcome, but not required: https://www.paypal.com/paypalme/pauljohnston2025

Information on all the settings can be found in [Settings](settings.md)  
note: Map support is disabled by default, but can be turned on in app settings, this is because map tile loading is memory intensive and may cause crashes on some devices. You must set `Tile Cache Size` if using maps to avoid crashes.    
Companion app can be found at [Companion App](https://github.com/pauljohnston2025/breadcrumb-mobile.git)  
[Companion App Releases](https://github.com/pauljohnston2025/breadcrumb-mobile/releases/latest)

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

Must port forward both adb and the tile server for the simulator to be able to fetch tiles from the comapnion app

* adb forward tcp:8080 tcp:8080
* adb forward tcp:7381 tcp:7381

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
