# Awesome Habits — Architecture Decisions

This document captures the current architecture with Firebase backend integration, Riverpod for state management, and a layered structure.

## Overview
- Flutter app using layered architecture: domain, application, infrastructure, presentation, and core.
- State management: Riverpod (Provider, StreamProvider, AsyncNotifier).
- Backend: Firebase Auth (anonymous sign-in) + Cloud Firestore for persistent storage.
- Web-first: Firebase is initialized defensively to handle hot restarts on web.

## Layers and responsibilities
- domain/
  - Entities and repository interfaces only; pure Dart.
  - Files: lib/domain/habits/habit.dart, lib/domain/habits/habit_repository.dart
- application/
  - Orchestrates use-cases and exposes state via Riverpod providers/controllers.
  - Files: lib/application/habits/habit_providers.dart
- infrastructure/
  - Concrete implementations (Firebase, SharedPreferences) and services.
  - Files: lib/infrastructure/habits/firestore_habit_repository.dart, lib/infrastructure/habits/shared_prefs_habit_repository.dart, lib/infrastructure/auth/auth_service.dart
- presentation/
  - UI pages and widgets, consuming providers.
  - Files: lib/presentation/pages/auth_prompt_page.dart, lib/presentation/pages/habit_list_page.dart, lib/presentation/widgets/habit_card.dart
- core/
  - Shared utilities.
  - Files: lib/core/date_key.dart

## State management (Riverpod)
- authServiceProvider: exposes AuthService (Firebase Auth wrapper).
- authStateProvider: StreamProvider<User?> for auth state changes.
- habitRepositoryProvider: provides HabitRepository (currently Firestore implementation).
- habitStreamProvider: StreamProvider<List<Habit>> reflecting Firestore live updates for the authenticated user.
- habitListController: AsyncNotifier for imperative actions (add/toggle/delete) with invalidateSelf to refresh state.

## Backend: Firebase integration
- Firebase Core and Auth are initialized before usage.
  - main.dart initializes Firebase at startup using firebase_options.dart.
  - AuthService lazily initializes Firebase before sign-in/sign-out to survive web hot restarts.
- Authentication
  - Anonymous sign-in used by default.
  - Entry flow: AuthPromptPage -> signInAnonymously -> HabitListPage.
  - Sign out from HabitListPage AppBar returns to AuthPromptPage and clears navigation stack.
- Firestore
  - Habits stored per user, filtered by owner_id.
  - Queries order by createdAt, filter by archived=false.

## Data model
- Domain entity: Habit (lib/domain/habits/habit.dart)
  - Fields: id, name, ownerId, createdAt, updatedAt, archived, completions (Map<yyyy-MM-dd,bool>).
  - Methods: copyWith, toMap/fromMap, toggleCompletion, isCompletedOn.
  - createdAt/updatedAt are maintained; updatedAt is refreshed on mutating ops.
- Firestore schema (lib/firestore/firestore_data_schema.dart)
  - Collection: habits
  - Fields: id (String), name (String), owner_id (String), createdAt (Timestamp), updatedAt (Timestamp), archived (bool), completions (Map<String,bool>)
  - Constants in HabitFields provide field names, used consistently across reads/writes.

## Repository strategy
- Interface: HabitRepository (lib/domain/habits/habit_repository.dart)
  - Legacy: fetchAll/saveAll for local storage compatibility.
  - Primary: watchHabits/addHabit/updateHabit/deleteHabit for Firestore.
- FirestoreHabitRepository (production default)
  - Enforces per-user access via current FirebaseAuth UID.
  - Sets ownerId on add; validates ownership on update/delete.
  - Uses typed field constants and converts DateTime <-> Timestamp.
  - Streams user’s non-archived habits sorted by createdAt.
- SharedPrefsHabitRepository (local fallback)
  - Keeps a JSON-encoded array under a single key; ownerId defaults to "local_user".
  - Useful for offline/local-only scenarios or testing without backend.
  - Note: Not wired by default; habitRepositoryProvider currently returns Firestore.

## Providers and UI flow
- Startup: main.dart initializes Firebase and shows AuthPromptPage.
- AuthPromptPage: anonymous sign-in via AuthService then pushReplacement to HabitListPage.
- HabitListPage: subscribes to habitStreamProvider for live updates; provides actions to add, toggle for today, and delete.
- HabitCard: reusable widget displaying a habit with a vertically centered, clickable checkbox.

## Error handling
- Auth and repository operations surface errors via exceptions and user feedback with SnackBars.
- Providers default to empty streams when not authenticated to avoid null access.

## Web and hot restart considerations
- On web, hot restarts can drop Firebase app instances; AuthService ensures Firebase.initializeApp runs if needed before using Auth APIs.
- main.dart also initializes Firebase on cold start.

## Security rules (recommended)
Use owner-based access control for the habits collection:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /habits/{habitId} {
      allow read, create: if request.auth != null && request.resource.data.owner_id == request.auth.uid;
      allow update, delete: if request.auth != null && resource.data.owner_id == request.auth.uid;
    }
  }
}
```

## Indexes (recommended)
To support the query combining filters and ordering:
- Collection: habits
- Composite index on:
  - Fields: owner_id Asc, archived Asc, createdAt Desc

## Offline and caching
- Firestore client-side caching provides resilience; on web, behavior depends on browser storage availability. The app expects connectivity for writes to complete.

## Configuration
- Firebase configuration is generated in lib/firebase_options.dart.
- App initializes Firebase with DefaultFirebaseOptions.currentPlatform.
- No platform-specific code paths; the app runs on Android, iOS, and web.

## Future extensions
- Replace anonymous auth with email/password, Apple, or Google sign-in; AuthService can be extended.
- Sync strategy: add conflict resolution if editing from multiple devices.
- Archive or reorder habits; add statistics/analytics pages.
- Migrate habitRepositoryProvider to switch between Firestore and SharedPrefs based on auth or a feature flag if desired.
