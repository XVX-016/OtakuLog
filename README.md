# OtakuLog

A local-first anime and manga tracker built with Flutter. Search via AniList and MangaDex, manage your library, log progress quickly, view wrapped-style stats, and optionally back up to the cloud.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (≥ 3.0.0)
- For **Windows**: Visual Studio with C++ desktop development workload
- For **Android**: Android Studio with Android SDK
- For **iOS/macOS**: Xcode (macOS only)

## Setup

```bash
# Clone the repo
git clone <repo-url>
cd GoonTwin

# Install dependencies
flutter pub get

# Generate Isar models (required after changes to .dart model files)
dart run build_runner build --delete-conflicting-outputs
```

## Environment

Create a local `.env` file for runtime cloud features:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Keep admin-only values like the service-role key in `.env.admin`. They are not loaded by the Flutter app.

## Running the App

```bash
# Windows (debug)
flutter run -d windows

# Android (debug, with device/emulator connected)
# iOS (debug, macOS only)
flutter run -d ios

# List available devices
flutter devices
```

## Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle
```

For signed Android releases:

1. Copy `android/key.properties.example` to `android/key.properties`
2. Fill in your keystore values
3. Run the release build command above

If `android/key.properties` is missing, the app falls back to debug signing for local testing.

## Running Tests

```bash
flutter test
```

## Internal Testing Checklist

- Complete onboarding or skip it
- Search anime and manga, then switch filters
- Add items to the library and verify duplicate prevention
- Use quick log and log-to-target flows
- Open wrapped cards and try share/save
- Sign in, back up, and restore on another device
- Toggle reminders and confirm they stop after logging

Feedback prompts:

- What feels easiest to use?
- What feels confusing?
- What would you remove?
- What would make you come back tomorrow?

Hidden tester tool:

- Long-press the version row in `Settings > About` to open the analytics debug screen

## Project Structure

```
lib/
├── app/          # App config, routing, providers, theme
├── core/         # Shared utilities, widgets, sync logic
├── data/         # Data layer (models, mappers, repositories, API services)
│   ├── local/    # Isar database service
│   ├── mappers/  # Entity ↔ Model mappers
│   ├── models/   # Isar collection models
│   ├── remote/   # AniList & MangaDex API clients
│   └── repositories/  # Repository implementations
├── domain/       # Domain layer (entities, repository interfaces, services)
│   ├── entities/ # Core domain objects
│   └── repositories/ # Abstract repository contracts
└── features/     # Feature screens (home, library, search, stats, details)
```

## Tech Stack

- **State Management**: Riverpod
- **Routing**: GoRouter
- **Local DB**: Isar
- **Networking**: Dio
- **APIs**: AniList (GraphQL), MangaDex (REST)
- **Charts**: fl_chart
