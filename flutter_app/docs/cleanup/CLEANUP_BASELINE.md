# CLEANUP BASELINE

## Flutter Environment
- **Flutter version**: 3.35.7 (channel stable)
- **Dart version**: 3.9.2

## Static Analysis Result
- **Result**: `flutter analyze` found 161 issues.
- **Errors**: No compile errors preventing build.
- **Warnings**: Many unused imports, dead code, `prefer_const_constructors`, deprecated members (`withOpacity`, `value`).

## Test Results
- **Result**: `flutter test` reported no test files found ending with `_test.dart` in the `test` directory.

## Project Structure
- Top-level directories: `android`, `assets`, `build`, `docs`, `ios`, `lib`, `linux`, `macos`, `test`, `web`, `windows`.
- Dependency Count: ~30 dependencies listed in `pubspec.yaml` (99 packages resolved).
- Known backups: `pubspec.lock.bak`, `pubspec.yaml.bak`.
