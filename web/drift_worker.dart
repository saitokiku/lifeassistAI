// Entry point compiled to web/drift_worker.js so drift can run the database
// in a Web Worker with OPFS-backed persistence. Regenerate after a drift
// upgrade with:
//   dart compile js -O4 web/drift_worker.dart -o web/drift_worker.js
import 'package:drift/wasm.dart';

void main() {
  WasmDatabase.workerMainForOpen();
}
