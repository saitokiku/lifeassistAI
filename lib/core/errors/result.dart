/// Minimal Result type for operations whose failure the UI must report
/// (import/export, notification scheduling) without throwing across layers.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(String message, [Object? cause]) = Failure<T>;

  bool get isSuccess => this is Success<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failure<T>() => null,
      };

  String? get errorOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(:final message) => message,
      };

  R when<R>({
    required R Function(T value) success,
    required R Function(String message) failure,
  }) =>
      switch (this) {
        Success<T>(:final value) => success(value),
        Failure<T>(:final message) => failure(message),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, [this.cause]);
  final String message;
  final Object? cause;
}
