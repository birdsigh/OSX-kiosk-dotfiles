#OSX Kiosk Dotfiles
![Sorely needs updating](https://img.shields.io/badge/needs%20updating-sorely-red.svg)

Preferences and settings for using OS X as a kiosk in an exhibition environment. This assumes running 10.6 or higher.

## What do these settings change?

These dotfiles disable small things like UI animation, set power management settings, as well as disabling system-wide services such as Spotlight Indexing and other processes that can swallow significant resources at any point while the kiosk is active.

###Among miscellaneous smaller changes, the main changes are:

* Cleans up unused menu bar icons
* Disables window and get info animations
* Disables Resume system-wide
* Disables automatic termination of inactive apps
* Disables the crash reporter
* Allows quick access to IP address, hostname, OS version, etc. from the clock in login window
* Restarts automatically after reconnecting power
* Increases sound quality for Bluetooth audio
* Leaves Bluetooth enabled by default, with optional commented-out disable commands for kiosks without Bluetooth peripherals
* Enables full keyboard access for all controls
* Enables keyboard-focus zoom controls
* Disables auto-correct
* Enables HiDPI display modes
* Shows icons for hard drives, servers, and removable media on the desktop
* Shows hidden files
* Avoids creating .DS_Store files on network volumes
* Enables AirDrop over Ethernet and on unsupported Macs running Lion
* Shows the ~/Library folder
* Wipes all default app icons from the Dock
* Shows Dock indicator lights for open applications
* Hides the Dock, with no delay on show / hide
* Makes hidden application icons translucent in the Dock
* Adds Dock spacers
* Prevents Time Machine from prompting to use new hard drives as backup volume
* Enables the debug menu in Disk Utility
* Disables Spotlight and indexing
* Enables screen sharing
* Never goes into sleep mode
* Never start the screensaver
* Scheduled restart at 2am every day

## Launching artwork on login

Use `templates/com.kiosk.artwork.plist` as a starting point for launching the
actual artwork or kiosk application when the user logs in. The template uses
`RunAtLoad` to start immediately, `KeepAlive` to restart after a crash, and a
10 second `ThrottleInterval` to avoid tight restart loops.

Copy the template into the user's LaunchAgents folder, then edit the placeholder
paths before loading it:

```sh
mkdir -p ~/Library/LaunchAgents ~/Library/Logs
cp templates/com.kiosk.artwork.plist ~/Library/LaunchAgents/
$EDITOR ~/Library/LaunchAgents/com.kiosk.artwork.plist
launchctl bootstrap "gui/$(id -u)" ~/Library/LaunchAgents/com.kiosk.artwork.plist
launchctl enable "gui/$(id -u)/com.kiosk.artwork"
launchctl kickstart -k "gui/$(id -u)/com.kiosk.artwork"
```

Check status and logs with:

```sh
launchctl print "gui/$(id -u)/com.kiosk.artwork"
tail -f ~/Library/Logs/kiosk-artwork.log
```

To unload the agent while testing:

```sh
launchctl bootout "gui/$(id -u)" ~/Library/LaunchAgents/com.kiosk.artwork.plist
```
