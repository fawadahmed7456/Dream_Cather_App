class GeneralException implements Exception {
  GeneralException({
    this.statusCode,
    this.message,
  });

  final int? statusCode;
  final String? message;

  @override
  String toString() {
    return "$message";
  }
}
