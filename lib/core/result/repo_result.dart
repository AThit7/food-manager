sealed class RepoResult<T> {}

class RepoSuccess<T> extends RepoResult<T> {
  final T data;
  RepoSuccess(this.data);
}

class RepoFailure<T> extends RepoResult<T> {
  final String message;
  RepoFailure(this.message);
}

class RepoError<T> extends RepoResult<T> {
  final String message;
  final Object? exception;
  RepoError(this.message, [this.exception]);
}
