# Tahoe kiosk lockdown with Screen Time

Parental Controls are no longer the right setup path for macOS kiosk accounts.
On Tahoe, use Screen Time for local content and app-use restrictions, and treat
MDM configuration profiles as the only Apple-supported way to enforce the old
Finder, login window, and single-app style restrictions at deployment scale.

This document updates the older Parental Controls workflow described in
https://gist.github.com/kulas/e51bd454547c0200ed791cdb31525be6.

## Summary

For a visitor-facing Mac with keyboard access:

1. Keep the two-account model.
   - `admin`: password-protected administrator account for maintenance.
   - `visitor` or `kiosk`: standard account used by the public.
2. Apply the scriptable kiosk baseline with `kiosk.sh` or `.osx`.
3. Configure Screen Time manually in System Settings for the visitor account.
4. If the kiosk must resist deliberate keyboard escape attempts, use MDM or a
   dedicated kiosk browser/app. Screen Time alone is not a full Parental
   Controls replacement.

## What changed from Parental Controls

Old Parental Controls exposed a single local UI for application allow-listing,
web limits, store/content limits, Simple Finder, and some login restrictions.
Tahoe splits this:

| Old Parental Controls goal | Tahoe replacement | CLI without MDM |
| --- | --- | --- |
| Limit web content | Screen Time > Content & Privacy > App Store, Media, Web, & Games | No supported CLI found |
| Restrict app/content ratings | Screen Time > Content & Privacy > Store Restrictions | No supported CLI found |
| Disable Camera, Siri/Dictation, Book Store, SharePlay | Screen Time > Content & Privacy > App & Feature Restrictions | No supported CLI found |
| Lock Screen Time settings | Screen Time > Content & Privacy > Preference Restrictions | No supported CLI found |
| Simple Finder and Finder command restrictions | Finder configuration payload via MDM | No, except ordinary Finder defaults that are not equivalent |
| Hide login window buttons, configure auto login | Login Window payload via MDM, or local System Settings for auto login | Partially scriptable but not recommended for password handling |
| Single-app kiosk lock | Autonomous Single App Mode via MDM and an app that supports it | No |

## Research notes

Test environment for local command availability: macOS Tahoe 26.3.1
(`sw_vers` build `25D2128`) in this workspace. No `screentime`,
`familycontrols`, or equivalent Apple command-line tool was present in
`/usr/bin`, `/bin`, `/usr/sbin`, or `/sbin`; only unrelated `screen` and
`screencapture` binaries were found.

Apple documents Screen Time setup for Mac through System Settings, including
Content & Privacy, App & Feature Restrictions, Store Restrictions, and
Preference Restrictions. Apple also documents deployable Mac restrictions as
device-management payloads: Finder payload, Login Window payload, Parental
Controls payload, and Autonomous Single App Mode payload. Those payloads require
Device Enrollment or Automated Device Enrollment. Apple documents Macs enrolled
in device management as supervised, with supervision providing additional
control over configuration and restrictions.

Practical result: without MDM, Screen Time configuration is a GUI task on Tahoe.
Do not rely on reverse-engineered plist edits for museum kiosk lockdown; the
settings are private implementation details and can be overwritten by Screen
Time services, Apple Account family state, or OS updates.

## Recommended non-MDM setup

Use this when you have a small number of kiosks and physical maintenance access.

1. Create an administrator account.
   - Use a named admin account, not the visitor account.
   - Store credentials in the institution password manager.
2. Create a standard visitor account.
   - System Settings > Users & Groups > Add User.
   - New User: Standard.
   - Avoid Apple Account sign-in for the visitor account unless you need it for
     Screen Time Family Sharing.
3. Sign in as the visitor account and apply local kiosk defaults:

   ```sh
   ./kiosk.sh --apply-current-user
   ```

4. Configure auto login if the machine must recover unattended.
   - System Settings > Users & Groups > Automatically log in as.
   - Choose the visitor account.
   - Do this only on physically secured machines. Auto login stores credentials
     in a way Apple manages outside this repo, so `kiosk.sh` does not script it.
5. Configure Screen Time while logged in as an admin.
   - System Settings > Screen Time.
   - Select the visitor account or child account if available.
   - Turn on App & Website Activity if it is off.
   - Open Content & Privacy and turn it on.
   - App Store, Media, Web, & Games:
     - Set Web Content to the narrowest workable setting.
     - Prefer `Allowed Websites Only` if the kiosk has a fixed URL set.
   - Store Restrictions:
     - Disable purchases, app installs, and explicit content where available.
   - App & Feature Restrictions:
     - Disable Camera, Siri & Dictation, Book Store, and SharePlay unless the
       exhibit needs them.
   - Preference Restrictions:
     - Lock Screen Time settings with a Screen Time passcode.
6. Configure the kiosk browser or app.
   - Prefer a dedicated kiosk browser that traps common shortcuts and relaunches
     itself.
   - Add the app to Login Items for the visitor account.
   - Test escape keys: Command-Tab, Command-Space, Command-Q, Command-H,
     Control-Command-Q, Mission Control, function keys, and the app's own
     address/search shortcuts.

## When to use MDM

Use MDM when visitor keyboard access must be meaningfully constrained. Screen
Time can limit content and some features, but it is not the old Simple Finder
lockdown surface.

MDM lets you deploy:

- Finder payload: Simple Finder, desktop item visibility, and Finder commands
  such as Connect to Server, Go to Folder, Restart, Shut Down, and Log Out.
- Login Window payload: login prompt shape, login window buttons, `>console`,
  Fast User Switching, and supervised auto-login behavior on macOS 14 or later.
- Parental Controls payloads: managed content filters and time limits.
- Autonomous Single App Mode payload: grants a supported app control of the Mac
  for single-app kiosk behavior.

For a public kiosk, the MDM target state is usually:

- standard visitor account;
- auto login to visitor;
- kiosk app as a login item;
- Finder payload set to Simple Finder with shutdown/logout commands removed;
- Login Window payload removing unnecessary buttons and `>console`;
- content restrictions for web/store/Siri/Dictation;
- app-supported single-app mode if the kiosk app vendor supports it.

## What `kiosk.sh` scripts

`kiosk.sh` handles the local pieces that are still suitable for shell setup:

- reports the OS version and whether any Screen Time CLI is present;
- optionally creates a standard local visitor account;
- applies current-user Dock, Finder, Safari, Spotlight, screen saver, and power
  defaults useful for a kiosk baseline.

It intentionally does not write private Screen Time preference plists or store
auto-login passwords.

## Verification checklist

Run this on the Tahoe VM or kiosk Mac:

1. `./kiosk.sh --check-screen-time-cli` reports no supported Screen Time CLI.
2. Visitor account is standard, not admin.
3. Reboot logs into the visitor account if auto login is required.
4. Kiosk app starts after login.
5. Screen Time Content & Privacy is on and locked with a passcode.
6. Attempted escape shortcuts do not expose Finder, menu bar access to other
   apps, Terminal, System Settings, Spotlight, or the App Store.
7. A forced restart returns to the kiosk app without manual intervention.

## Sources

- Apple, Screen Time on Mac:
  https://support.apple.com/guide/mac-help/mchlfafa9773/mac
- Apple, Content & Privacy in Screen Time:
  https://support.apple.com/guide/mac-help/mchlad1c54b0/mac
- Apple, App & Feature Restrictions in Screen Time:
  https://support.apple.com/guide/mac-help/change-app-feature-restrictions-settings-mchl3a19a9e7/mac
- Apple, device supervision:
  https://support.apple.com/en-ca/guide/deployment/dep1d89f0bff/web
- Apple, Mac device-management restrictions:
  https://support.apple.com/en-ca/guide/deployment/depba790e53/web
- Apple, Finder payload:
  https://support.apple.com/en-ca/guide/deployment/dep1c778fx7/web
- Apple, Login Window payload:
  https://support.apple.com/en-ca/guide/deployment/dep2a822b29/web
- Apple, Parental Controls payload:
  https://support.apple.com/en-ca/guide/deployment/dep1c778f77/web
- Apple, Autonomous Single App Mode payload:
  https://support.apple.com/en-ca/guide/deployment/dep8a42c4c4a/web
