# Manual test checklist

## UI and accessibility

- [ ] Launch with the device in light mode: splash transitions to home without a white flash
- [ ] Home fort artwork covers the full viewport and continues behind the translucent mobile app bar
- [ ] Repeat launch and home checks in dark mode and with **System** theme selected
- [ ] Check home, search, messages, settings, and calls at 360dp, 600dp, and 840dp+ widths
- [ ] At 840dp+, the persistent navigation panel appears without clipping the page content
- [ ] Switch between English and Arabic; verify directional spacing and text alignment while logos and background artwork remain unmirrored
- [ ] Verify loading, offline, empty-room, no-search-result, and error states in both themes
- [ ] Verify all primary controls are reachable by keyboard and have visible focus; mobile tap targets are at least 44dp
- [ ] Confirm text remains readable with system text scaling at 200%

## Auth

- [ ] Password login and session restore after restart
- [ ] Register new account on a test homeserver
- [ ] Logout keeps app lock PIN; session cleared
- [ ] QR sign-in: scan Element Web “Sign in with QR” (homeserver with `org.matrix.msc4108` unstable feature)
- [ ] QR sign-in: unsupported server shows a clear English error
- [ ] Link device → **Sign in another phone** shows QR; **Verify** flow still uses emoji SAS

## Messages

- [ ] Send text, image, voice note, location
- [ ] Forward text to another room
- [ ] Forward image/file (re-upload, not `Forwarded:` text only)

## Calls (mobile)

- [ ] Outbound voice/video from room call screen; call UI opens if you navigate away
- [ ] Incoming call opens call screen while app is foregrounded
- [ ] Two clients on same homeserver; verify audio (TURN from `/voip/turnServer` when available)
- [ ] Encrypted DM: note any decrypt/call limitations
- [ ] Background incoming ring: **not** supported without push (see below)

## Push

- [ ] No FCM/APNs in repo by default — messages sync only while app runs
- [ ] To enable: add `google-services.json`, `firebase_messaging`, call `PushRepo.registerAfterLogin` with a real token

## Enterprise

- [ ] Enterprise screen remains unavailable (`EnterpriseRepoImpl.available == false`) unless Element enterprise config is ported

## Reported rooms

- [ ] Report room badge is session-scoped (not persisted across logout on other devices)
