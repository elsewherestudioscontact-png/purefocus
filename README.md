# PureFocus — Flutter App

Deep work timer + focus app. Flutter WebView wrapper around the PureFocus HTML app.

## Stack
- Flutter 3.19 (stable)
- `flutter_inappwebview` — renders the HTML app
- `permission_handler` — notification permissions
- `wakelock_plus` — keeps screen on during focus sessions
- GitHub Actions — builds the APK automatically on push

## Project Structure
```
purefocus/
├── lib/
│   └── main.dart              # App entry, splash screen, WebView
├── assets/
│   └── purefocus.html         # The full PureFocus web app (bundled)
├── android/
│   └── app/
│       ├── build.gradle
│       └── src/main/
│           └── AndroidManifest.xml
├── .github/
│   └── workflows/
│       └── build.yml          # CI/CD → builds APK on push to main
└── pubspec.yaml
```

## Setup & Build

### 1. Clone and push to your GitHub
```bash
git init
git add .
git commit -m "init: purefocus flutter app"
git remote add origin https://github.com/YOUR_USERNAME/purefocus.git
git push -u origin main
```

GitHub Actions will automatically build the APK. Download it from the **Actions** tab → latest run → **Artifacts**.

### 2. Build locally (optional)
```bash
flutter pub get
flutter build apk --release
# APK → build/app/outputs/flutter-apk/app-release.apk
```

### 3. Install on Android
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
# or just transfer the APK and open it on your phone
```

## Package ID
`com.elsewhere.purefocus`

## Updating the App
To update PureFocus UI/logic — just replace `assets/purefocus.html` with the new version and push. GitHub Actions rebuilds the APK automatically.
