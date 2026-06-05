import "dart:async";

import "package:drift/drift.dart";

// the warning is a test-only artifact. Silence it so it doesn't drown out real test output.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
