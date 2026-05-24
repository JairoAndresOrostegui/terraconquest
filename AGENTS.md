# Terra Conquest Agent Notes

## Project Overview

Terra Conquest is a Flutter app backed by Firebase Auth, Cloud Firestore, Firebase Storage, and Cloud Functions. The app is in active development and currently has uncommitted work in the tree, so inspect `git status` before editing and do not revert unrelated changes.

## Main Entry Points

- Flutter app: `lib/main.dart`
- Firebase config: `lib/config/firebase_options.dart`
- Player screens: `lib/screens/game/`
- Admin screens: `lib/screens/admin/`
- Firestore/Auth/Functions access: `lib/services/`
- Firestore document models: `lib/models/`
- Cloud Functions source: `functions/src/`
- Cloud Functions exports: `functions/src/index.ts`
- Day processing core: `functions/src/core/procesarPasoDia.ts`

## Architecture Notes

- `main.dart` initializes Firebase and routes by Firebase Auth state.
- Unauthenticated users see `LoginScreen`.
- Authenticated users enter `HomePartidasScreen`.
- Client-side writes that affect game rules should generally go through Cloud Functions, not direct Firestore updates.
- Admin-only backend flows check `usuarios/{uid}.rol == "admin"`.
- Firestore game state is organized under `partidas/{partidaId}` subcollections such as `imperios`, `ciudades`, `regiones`, `heroes`, `heroesMercado`, `eventos`, `rankingsImperios`, `control`, and `pasosDiaLogs`.

## Development Commands

Run from the repository root unless noted:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Cloud Functions:

```bash
cd functions
npm install
npm run build
npm run serve
npm run deploy
```

## Coding Guidelines

- Follow the existing Flutter structure: screens contain UI, services wrap Firebase access, models handle Firestore serialization.
- Keep rule-sensitive game mutations in `functions/src` and expose them through callable functions where possible.
- Prefer focused changes over broad refactors.
- Preserve the dark Material 3 style unless a task explicitly changes the visual direction.
- Use existing model helpers and service patterns before introducing new abstractions.
- When adding Firestore queries that need indexes, update `firestore.indexes.json`.

## Verification

- For Flutter UI or client logic changes, run `flutter analyze` and relevant `flutter test` coverage when feasible.
- For Cloud Functions changes, run `npm run build` inside `functions`.
- Mention any command that could not be run and why.
