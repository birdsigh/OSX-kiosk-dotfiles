# Tahoe kiosk auto-login

Use macOS's supported UI for auto-login. Do not create or modify
`/etc/kcpassword`: its format is undocumented, stores a recoverable credential,
and this repository has not validated a Tahoe-compatible encoding procedure.

## Preconditions

- Use a dedicated, standard local kiosk account. Never auto-login an admin.
- The kiosk must be physically secured. Anyone who can restart it can access
  the auto-login account.
- FileVault must be off. macOS disables automatic login while FileVault is on.
- The account must use a local password, not an Apple Account password. A
  managed profile can also prohibit auto-login.

Apple documents these restrictions and the UI path in [How to log in
automatically to a Mac user account](https://support.apple.com/102316).

## Configure

1. Sign in as the administrator that manages the kiosk.
2. Open **System Settings > Users & Groups**.
3. Set **Automatically log in as** to the dedicated kiosk account.
4. Enter that account's local password when macOS requests it.
5. Sign out or restart once. Confirm the kiosk account starts the artwork via
   `templates/com.kiosk.artwork.plist` or the deployed equivalent.

This UI applies to Tahoe on both Apple Silicon and Intel Macs. No supported
Apple documentation identifies a different automatic-login procedure by CPU
architecture. Validate the exact Mac model and installed management profiles
before deployment.

## Tahoe UTM validation record

Run this after making a clean UTM Tahoe snapshot. Do not mark this ticket as
verified until all checks pass on the target macOS build.

| Check | Expected result | Result / notes |
| --- | --- | --- |
| FileVault status | Off before enabling auto-login | |
| UI setting | Kiosk account is selectable and saved | |
| Restart | VM reaches kiosk desktop without credentials | |
| Artwork | LaunchAgent starts the artwork after login | |
| Scheduled restart | Kiosk account returns after the configured restart | |
| Physical target | Repeat restart test on the deployment hardware | |

If FileVault is a deployment requirement, leave automatic login off and use a
different, manually authenticated recovery procedure. FileVault requires
authentication to unlock the startup disk; it is not compatible with this
unattended auto-login design.
