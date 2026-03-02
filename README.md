# GoonTwin (goon_tracker)

An anime & manga tracking app built with Flutter. Search via AniList & MangaDex, manage your library, log progress, and view stats.

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

## Running the App

```bash
# Windows (debug)
flutter run -d windows

# Android (debug, with device/emulator connected)
flutter run -d android

# iOS (debug, macOS only)
flutter run -d ios

# List available devices
flutter devices
```

## Building for Release

```bash
# Windows
flutter build windows

# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle
```

## Running Tests

```bash
flutter test
```

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
