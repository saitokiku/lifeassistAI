# Web assets for drift persistence

Two files let drift persist data in the browser (OPFS-backed) instead of
falling back to in-memory storage:

- `drift_worker.js` — **committed.** Compiled from `web/drift_worker.dart`
  against the pinned drift version. Regenerate after a drift upgrade:
  `dart compile js -O4 web/drift_worker.dart -o web/drift_worker.js`
- `sqlite3.wasm` — **not committed** (must match the resolved `sqlite3`
  package version, currently 2.9.4). Download it once into this folder:
  `curl -L -o web/sqlite3.wasm \`
  `  https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm`

Without `sqlite3.wasm`, the web build still runs but data does not persist
across reloads (drift logs a warning and uses an in-memory database). iOS,
Android, macOS, Windows, and Linux persist natively and need neither file.
