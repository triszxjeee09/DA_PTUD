class ApiResponse<T> {
  const ApiResponse({
    required this.status,
    required this.message,
    this.data,
    this.timestamp,
  });

  final int status;
  final String message;
  final T? data;
  final DateTime? timestamp;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    final rawData = json['data'];

    return ApiResponse<T>(
      status: (json['status'] as num?)?.toInt() ?? 0,
      message: json['message'] as String? ?? '',
      data: rawData == null ? null : fromJsonT(rawData),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? ''),
    );
  }
}
