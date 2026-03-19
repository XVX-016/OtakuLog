# GoonTwin Backend + Sync Preparation

## Scope
This is a design-only document for the future cloud layer. The current app remains local-first.

Backend responsibilities for a later phase:
- user accounts and authentication
- cloud backup of library, sessions, and settings
- multi-device sync
- public reviews and shared wrapped pages

## Recommended stack
- Supabase
- Postgres
- Row-level security for user-owned records
- Flutter client using local-first writes with background sync

## Core tables
### `users`
- `id`
- `email`
- `created_at`

### `profiles`
- `user_id`
- `display_name`
- `default_search_medium`
- `default_adult_mode`
- `avg_chapter_minutes`
- `blur_cover_in_public`
- `notifications_enabled`

### `user_library`
- `id`
- `user_id`
- `content_id`
- `medium`
- `title`
- `cover_image`
- `status`
- `current_progress`
- `total_progress`
- `rating`
- `genres`
- `description`
- `updated_at`

### `user_sessions`
- `id`
- `user_id`
- `content_id`
- `medium`
- `units_consumed`
- `started_at`
- `ended_at`
- `duration_minutes`
- `created_at`

### `public_reviews`
- `id`
- `user_id`
- `content_id`
- `medium`
- `rating`
- `body`
- `created_at`

### `shared_wrapped`
- `id`
- `user_id`
- `period_type`
- `period_key`
- `payload_json`
- `created_at`
- `expires_at`

## Sync strategy
- Local-first writes remain the source of immediate UI truth.
- Remote sync runs in the background after local persistence succeeds.
- Each synced row should carry `updated_at` and a stable local id.
- Conflict resolution rule:
  - latest `updated_at` wins for settings and library metadata
  - sessions are append-only and should merge by id
- If sync fails, the app keeps working offline and retries later.

## Environment plan
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- feature flag to enable auth/sync later without changing local-only builds
