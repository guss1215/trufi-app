# Deep Links — Shared Route Links

When a user shares a route from the app, the message includes a link such as:

```
https://planner.trufi.app/route?fromLat=...&fromLng=...&fromName=...&toLat=...&toLng=...&toName=...&time=...
```

Because it is an `https://` link, messaging apps (WhatsApp, etc.) render it as a
tappable hyperlink. With **Android App Links** and **iOS Universal Links**
configured, tapping it opens the installed app directly on the shared route
instead of a browser.

This replaces the old behavior where a `trufiapp://route?...` custom-scheme link
was shared as plain, non-tappable text. See trufi-association/trufi-core#899.

## How it works

1. `lib/main.dart` sets `HomeScreenConfig.shareBaseUrl = 'https://planner.trufi.app'`.
   trufi-core's `ShareRouteService` then generates the `https://planner.trufi.app/route?...`
   link instead of the custom scheme.
2. The OS verifies the app ↔ domain association by fetching two files from the
   domain (see below).
3. On tap, Android/iOS routes the URL to the app. trufi-core's `DeepLinkService`
   receives it and `SharedRoute.fromUri()` parses the query params, then the home
   screen re-plans the shared route.

## Domain & hosting

The verification files live on **`planner.trufi.app`** (server `143.198.77.246`).

That host is served by the `trufi-planner` container — a Dart `shelf` server that
cascades unmatched paths to a static file handler rooted at `web/`
(see `trufi-server-planner/bin/server.dart`). So any file placed under
`web/.well-known/` is served at `https://planner.trufi.app/.well-known/<file>`
with no code, container, or reverse-proxy changes.

The `web/` directory on that server is the **Flutter web build of this app**.
That's why the verification files are committed here at `web/.well-known/` — every
web build/deploy copies them into the deploy output, so they survive deploys.

### Files

- `web/.well-known/assetlinks.json` — Android Digital Asset Links
- `web/.well-known/apple-app-site-association` — iOS Universal Links (no extension)

### Deploying to the server (immediate, until next web deploy)

```bash
ssh root@143.198.77.246 'mkdir -p /root/planner/web/.well-known'
scp web/.well-known/assetlinks.json \
    root@143.198.77.246:/root/planner/web/.well-known/assetlinks.json
scp web/.well-known/apple-app-site-association \
    root@143.198.77.246:/root/planner/web/.well-known/apple-app-site-association
# verify
curl -i https://planner.trufi.app/.well-known/assetlinks.json
curl -i https://planner.trufi.app/.well-known/apple-app-site-association
```

## Android

- `android/app/src/main/AndroidManifest.xml` has an `<intent-filter android:autoVerify="true">`
  for `https://planner.trufi.app/route`.
- `assetlinks.json` lists `package_name = app.trufi.navigator` and the SHA-256 of the
  signing certificate.

### ⚠️ TODO — release signing

The app currently signs release builds with the **debug** keystore
(`android/app/build.gradle` → `signingConfig = signingConfigs.debug`). The SHA-256
in `assetlinks.json` is therefore the **debug** fingerprint:

```
22:C6:BE:5E:54:9B:4C:BE:9C:0F:A9:70:8A:3D:9F:40:12:09:86:01:65:6C:B6:75:9B:89:FA:74:BE:DE:47:8F
```

This makes App Links verify for locally-built (debug) APKs only. For the
**Play-Store-distributed** build to verify, configure a release keystore, then
append its SHA-256 to the `sha256_cert_fingerprints` array (it accepts multiple):

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" \
  -list -v -alias <release-alias> -keystore <release.keystore> | grep SHA256
```

> Note: the repo also contains an unused `android/app/build.gradle.kts` (and
> `settings.gradle.kts`) with a different `applicationId` (`app.trufi.trufi`).
> Gradle uses the Groovy `build.gradle` (`app.trufi.navigator`, confirmed via the
> built APK's manifest), so the `.kts` files are currently dead. Worth cleaning up
> to avoid confusion, but out of scope for #899.

## iOS

- `ios/Runner/Runner.entitlements` declares `applinks:planner.trufi.app`.
- `ios/Runner.xcodeproj/project.pbxproj` references it via `CODE_SIGN_ENTITLEMENTS`
  on all three Runner build configs (Debug/Release/Profile).
- `apple-app-site-association` lists the App ID `NNB9PHQ49J.app.trufi.navigator`
  and matches the path `/route*`.

### ⚠️ Requires the Associated Domains capability

The App ID must have the **Associated Domains** capability enabled in the Apple
Developer portal (Certificates, Identifiers & Profiles → the `app.trufi.navigator`
identifier). If the provisioning profile doesn't include it, signing the iOS build
will fail. Enabling it in Xcode (Signing & Capabilities → + Associated Domains)
also updates the portal when using automatic signing.

### ⚠️ Known caveat — AASA content-type

The `trufi-planner` server (`shelf_static`) serves the extension-less
`apple-app-site-association` file as `text/plain`, not the `application/json` that
Apple's docs recommend. Modern iOS (14+) fetches the file through Apple's CDN and
tolerates this in practice, so Universal Links work. If iOS verification ever fails,
the fix is in `trufi-server-planner`: add a dedicated route that serves
`/.well-known/apple-app-site-association` with `Content-Type: application/json`
ahead of the static-file cascade, then redeploy the planner container.

## Verification

- iOS AASA: <https://branch.io/resources/aasa-validator/> (enter `planner.trufi.app`).
- Android: after installing the debug APK, run
  `adb shell pm get-app-links app.trufi.navigator` — expect `planner.trufi.app: verified`.
- End-to-end: share a route → open the message on a device with the app installed →
  tap the link → the app should open directly on the shared route.
