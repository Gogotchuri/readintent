# ConnectRPC contract

This directory houses ConnectRPC contracts under `proto/` and their own respective modules for articles and auth services.

Generated files from proto should be included under each project directory (ui and backend).

## Requirements for generation
- `Go`
- `Dart`

Other requrements can be installed with `make setup`.

## Generating files from proto
Use the `Make` script from the root of this directory: `make generate` which will generate and distribute the generated files.
