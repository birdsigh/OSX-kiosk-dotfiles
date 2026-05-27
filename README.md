#OSX Kiosk Dotfiles
![Sorely needs updating](https://img.shields.io/badge/needs%20updating-sorely-red.svg)

Preferences and settings for using OS X as a kiosk in an exhibition environment. This assumes running 10.6 or higher.

## What do these settings change?

These dotfiles disable small things like UI animation, set power management settings, as well as disabling system-wide services such as Spotlight Indexing and other processes that can swallow significant resources at any point while the kiosk is active.

###Among miscellaneous smaller changes, the main changes are:

* Removes menu bar effects and clean up unused icons
* Disables window and get info animations
* Disables Resume system-wide
* Disables automatic termination of inactive apps
* Disables the crash reporter
* Allows quick access to IP address, hostname, OS version, etc. from the clock in login window
* Restarts automatically if the computer freezes
* Start up automatically after a power failure
* Increases sound quality for Bluetooth audio
* Disables bluetooth daemon (remove this from `.osx` if improved bluetooth audio is required)
* Enables access for assistive devices
* Disables auto-correct
* Enables subpixel font rendering on non-Apple LCDs
* Enables HiDPI display modes
* Shows icons for hard drives, servers, and removable media on the desktop
* Shows hidden files
* Avoids creating .DS_Store files on network volumes
* Enables AirDrop over Ethernet and on unsupported Macs running Lion
* Shows the ~/Library folder
* Wipes all default app icons from the Dock
* Enables the 2D Dock
* Hides the dock, with no delay on show / hide
* Prevents Time Machine from prompting to use new hard drives as backup volume
* Enables the debug menu in Disk Utility
* Disables Spotlight and indexing
* Disables Dashboard
* Enables screen sharing
* Enables file sharing
* Never goes into sleep mode
* Never start the screensaver
* Never sleep the display
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
