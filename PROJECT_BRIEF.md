## PROJECT: Private Anime & Manga Tracker (Production Grade)

### Vision

Build a production-grade Flutter mobile app focused on:

* Tracking anime episodes watched
* Tracking manga chapters read
* Logging daily consumption time
* Advanced analytics (lifetime hours, monthly stats, streaks)
* Default 18+ content filter
* Optional MangaDex reader integration (secondary feature)

This is NOT a streaming platform.

This is a premium dark-themed personal tracking app.

---

## Core Principles

1. Tracker-first architecture.
2. Reader is secondary utility.
3. Clean Architecture enforced.
4. Dark aesthetic only.
5. Local-first storage (Isar).
6. No business logic inside UI.
7. All external APIs abstracted behind repository layer.

---

## Tech Stack

* Flutter (latest stable)
* Riverpod (state management)
* GoRouter (navigation)
* Dio (network)
* Isar (local database)
* fl_chart (stats)
* cached_network_image
* Google Fonts (Inter)

---

## External APIs

* AniList (GraphQL) → anime metadata
* MangaDex → manga metadata + chapters

---

## MVP Scope (Phase 1)

* Bottom navigation (Home, Library, Search, Stats)
* Dark theme system
* Isar setup
* Add anime/manga to library
* Log episodes/chapters
* Calculate total time
* Display stats

NO reader yet.
NO notifications.
NO social.
NO sync.
