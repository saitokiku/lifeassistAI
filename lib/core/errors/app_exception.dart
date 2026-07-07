/// Base exception for expected, user-facing failures.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message';
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

class ImportException extends AppException {
  const ImportException(super.message, {super.cause});
}

class NotificationException extends AppException {
  const NotificationException(super.message, {super.cause});
}
