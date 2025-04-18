sealed class RepoResult<T> {}

class RepoSuccess<T> extends RepoResult<T> {
  final T data;
  RepoSuccess(this.data);
}

class RepoFailure<T> extends RepoResult<T> {
  final String message;
  RepoFailure(this.message);
}