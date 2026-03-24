# OtakuLog

A local-first anime and manga tracker built with Flutter. Search via AniList and MangaDex, manage your library, log progress quickly, view wrapped-style stats, and optionally back up to the cloud.

## Screenshots

| Home | Library |
| --- | --- |
| ![OtakuLog Home](landing/Screenshot%202026-03-19%20231537.png) | ![OtakuLog Library](landing/Screenshot%202026-03-19%20231546.png) |

| Search | Stats |
| --- | --- |
| ![OtakuLog Search](landing/Screenshot%202026-03-19%20231558.png) | ![OtakuLog Stats](landing/Screenshot%202026-03-19%20231617.png) |

## Manga Reader Flow

```mermaid
flowchart TD
    A[User taps READ]
    B[resolveMangaDexMangaId<br/>UUID from id or cover URL]
    C{UUID found?}
    D[Use directly]
    E[resolveMangaDexMangaIdForTitle<br/>Search MangaDex by title]
    F[fetchChapterFeed<br/>GET /manga/{id}/feed]
    G[Chapter selector sheet]
    H[fetchChapterPages<br/>GET /at-home/server/{id}]
    I{Downloaded?}
    J[Local]
    K[CDN]
    L[ReaderScreen / PageView]
    M[Download queue]
    N[Download pages<br/>Save to documents dir]
    O[Manifest updated]

    A --> B --> C
    C -- Yes --> D --> F
    C -- No --> E --> F
    F --> G
    G -- Read --> H
    H --> I
    I -- Yes --> J --> L
    I -- No --> K --> L
    G -- Download --> M --> N --> O

    classDef resolve fill:#4a3f96,stroke:#8b7cff,color:#ffffff
    classDef api fill:#105d4d,stroke:#52c7a5,color:#ffffff
    classDef download fill:#7a4a00,stroke:#f6a623,color:#ffffff
    classDef local fill:#335d0b,stroke:#8cc84b,color:#ffffff
    classDef neutral fill:#4a4a46,stroke:#bfbfbf,color:#ffffff

    class A,G neutral
    class B,E resolve
    class D,F,H,K,L api
    class M,N download
    class J,O local
```

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
