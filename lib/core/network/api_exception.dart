class ApiException implements Exception {
  ApiException(this.statusCode, [this.detalle]);
  final int? statusCode;
  final String? detalle;

  @override
  String toString() => 'ApiException($statusCode${detalle != null ? ": $detalle" : ""})';
}
