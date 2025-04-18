class ValidationError implements Exception {
  final String message;

  ValidationError(this.message);

  @override
  String toString() => 'ValidationError: $message';
}