# Kiosk setup and test plan

Target test environment: macOS Tahoe VM in UTM on Apple Silicon.

## Scripted setup

Run these from the repository root while logged into the kiosk account:

```sh
./bootstrap.sh
./kiosk.sh
./verify.sh
```

`kiosk.sh` is split into independently runnable modules:

- `lib/power.sh`: `pmset`, sleep, scheduled restart, power-on-connect
- `lib/ui.sh`: Dock, Finder, animations, screensaver, menu bar, app UI defaults
- `lib/system.sh`: Spotlight, Time Machine, crash reporter, update suppression
- `lib/sharing.sh`: Screen Sharing, optional File Sharing, optional Bluetooth disable
- `lib/security.sh`: Gatekeeper, Launch Services quarantine, iCloud suppression
- `lib/notifications.sh`: Notification Center suppression, Siri, Apple Intelligence

Run any module directly to reapply just that slice, for example:

```sh
./lib/power.sh
```

## Manual steps

These cannot be safely scripted in this repo:

1. Create a dedicated standard kiosk account and a separate administrator account.
2. Configure auto-login in System Settings > Users & Groups if the kiosk must recover unattended.
3. Configure Screen Time lockdown in System Settings > Screen Time for the kiosk account.
4. Lock Screen Time settings with a passcode stored in the institution password manager.
5. Install the artwork launcher as a LaunchAgent using `templates/com.kiosk.artwork.plist`.
6. Validate escape paths on the physical installation keyboard and input hardware.

## Test cycle

Use this cycle for every change:

1. Snapshot a clean Tahoe install.
2. Run `bootstrap.sh`.
3. Run `kiosk.sh`.
4. Run `verify.sh`; all checks must pass.
5. Reboot and re-run `verify.sh` to confirm settings survive restart.
6. Revert to the snapshot for the next test run.

The restructured script must produce the same `verify.sh` pass result as the
monolithic script before the restructure is merged.

## Hardware-dependent checks

`pmset autorestartatconnect` is hardware dependent. UTM may not report it, so
`verify.sh` reports this as informational when unavailable. Confirm it on
supported physical hardware before deploying to a gallery kiosk.
