import 'package:dio/dio.dart';

import '../errors/api_exception.dart';
import 'dio_client.dart';

/// Gọi REST API có dạng `{status, message, data}` và trả về trực tiếp phần `data`.
///
/// Dùng cho các tính năng mới để không phải lặp lại code parse/bắt lỗi.
class JsonApi {
  JsonApi({DioClient? dioClient}) : _client = dioClient ?? DioClient();

  static const String _defaultError = 'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _client;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) {
    return _run(() => _client.get<dynamic>(path, queryParameters: query));
  }

  Future<dynamic> post(String path, {Object? body}) {
    return _run(() => _client.post<dynamic>(path, data: body));
  }

  Future<dynamic> put(String path, {Object? body}) {
    return _run(() => _client.put<dynamic>(path, data: body));
  }

  Future<dynamic> delete(String path) {
    return _run(() => _client.delete<dynamic>(path));
  }

  Future<dynamic> _run(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      final body = response.data;
      if (body is Map) {
        final status = (body['status'] as num?)?.toInt() ?? 200;
        if (status >= 400) {
          throw ApiException(
            (body['message'] ?? _defaultError).toString(),
            statusCode: status,
          );
        }
        return body['data'];
      }
      return body;
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      final inner = error.error;
      if (inner is ApiException) {
        throw inner;
      }
      throw ApiException(_defaultError, statusCode: error.response?.statusCode);
    }
  }

  static Map<String, dynamic> asMap(Object? value) {
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  static List<Map<String, dynamic>> asList(Object? value) {
    if (value is List) {
      return value.map(asMap).toList();
    }
    return <Map<String, dynamic>>[];
  }

  static String message(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return _defaultError;
  }
}
