# ReadIntent

Flutter client for ReadIntent.

## Setup

```bash
flutter pub get
dart run build_runner build
```

## Development

```bash
flutter run            # debug on connected device
flutter run -d linux   # debug on linux desktop
```

## Release Build (Android)

### 1. Create upload keystore (one-time)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2. Create `android/key.properties`

```properties
storePassword=<your-password>
keyPassword=<your-password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

This file is gitignored. Do not commit it.

### 3. Build the app bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Google Play Store

- **Application ID:** `com.readintent.app`
- **App name:** ReadIntent

### Publishing a new version

1. Bump `version` in `pubspec.yaml` (e.g. `1.1.0+2` — the `+N` build number must increase each upload)
2. Build the release bundle (step 3 above)
3. Upload the `.aab` to Google Play Console > Release > Production (or testing track)
4. Submit for review
