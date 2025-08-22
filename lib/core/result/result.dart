sealed class Result<T> {}

class ResultSuccess<T> extends Result<T> {
  final T data;
  ResultSuccess(this.data);
}

class ResultFailure<T> extends Result<T> {
  final String message;
  ResultFailure(this.message);
}

class ResultError<T> extends Result<T> {
  final String message;
  final Object? exception;
  ResultError(this.message, [this.exception]);
}