# OSX Kiosk Dotfiles

Preferences and settings for using macOS as a kiosk in an exhibition environment.
The current target for verification is macOS Tahoe in a UTM VM on Apple Silicon.

## Structure

- `bootstrap.sh`: syncs the repo contents into the current home directory
- `kiosk.sh`: orchestrates the full kiosk baseline, including sudo keepalive and macOS version check
- `lib/power.sh`: `pmset`, sleep, scheduled restart, power-on-connect
- `lib/ui.sh`: Dock, Finder, animations, screensaver, menu bar, app UI defaults
- `lib/system.sh`: Spotlight, Time Machine, crash reporter, update suppression
- `lib/sharing.sh`: Screen Sharing, optional File Sharing, optional Bluetooth disable
- `lib/security.sh`: Gatekeeper, Launch Services quarantine, iCloud suppression
- `lib/notifications.sh`: Notification Center suppression, Siri, Apple Intelligence
- `templates/com.kiosk.artwork.plist`: LaunchAgent template for artwork auto-launch
- `docs/setup.md`: manual setup steps and the formal test plan
- `docs/tahoe-auto-login.md`: supported auto-login procedure and Tahoe test record
- `verify.sh`: Tahoe verification checks for the scripted baseline

Each `lib/` file is independently runnable for partial re-application:

```sh
./lib/power.sh
./lib/ui.sh
./lib/system.sh
./lib/sharing.sh
./lib/security.sh
./lib/notifications.sh
```

## Usage

```sh
./bootstrap.sh
./kiosk.sh
./verify.sh
```

Run `verify.sh` again after reboot to confirm settings survive restart.

## What these settings change

Among miscellaneous smaller changes, the main changes are:

- Cleans up unused menu bar icons
- Disables window and Get Info animations
- Disables Resume system-wide
- Disables automatic termination of inactive apps
- Disables the crash reporter
- Allows quick access to IP address, hostname, OS version, etc. from the clock in the login window
- Restarts automatically after reconnecting power where the hardware supports it
- Increases sound quality for Bluetooth audio
- Leaves Bluetooth enabled by default, with optional commented-out disable commands
- Enables full keyboard access for all controls
- Enables keyboard-focus zoom controls
- Disables auto-correct
- Enables HiDPI display modes
- Shows icons for hard drives, servers, and removable media on the desktop
- Shows hidden files
- Avoids creating `.DS_Store` files on network volumes
- Enables AirDrop over Ethernet and on unsupported Macs running Lion
- Shows the `~/Library` folder
- Wipes default app icons from the Dock
- Shows Dock indicator lights for open applications
- Hides the Dock, with no delay on show and hide
- Makes hidden application icons translucent in the Dock
- Adds Dock spacers
- Prevents Time Machine from prompting to use new hard drives as backup volumes
- Suppresses automatic software update checks, downloads, installs, and update notifications
- Enables the debug menu in Disk Utility
- Disables Spotlight and indexing
- Enables Screen Sharing
- Suppresses Notification Center, Siri, and Apple Intelligence onboarding
- Disables Launch Services quarantine prompts and attempts to disable Gatekeeper assessments
- Suppresses iCloud and Apple Account onboarding prompts
- Never goes into sleep mode
- Never starts the screensaver
- Schedules a restart at 2am every day

See [docs/setup.md](docs/setup.md) for manual steps that cannot be scripted,
including auto-login and Screen Time lockdown.
