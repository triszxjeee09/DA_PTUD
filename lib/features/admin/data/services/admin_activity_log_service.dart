import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/admin_activity_log_model.dart';

class AdminActivityLogService {
  AdminActivityLogService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _permissionErrorMessage =
      'Bạn không có quyền xem lịch sử hoạt động';
  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<PageResponse<AdminActivityLogModel>> getLogs({
    int page = 0,
    int size = 20,
    String? keyword,
    String? action,
    String? entityName,
    String? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
      if (action != null && action.trim().isNotEmpty) 'action': action.trim(),
      if (entityName != null && entityName.trim().isNotEmpty)
        'entityName': entityName.trim(),
      if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
      if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
      if (toDate != null) 'toDate': toDate.toIso8601String(),
    };

    try {
      final response = await _dioClient.get<dynamic>(
        ApiConstants.adminActivityLogs,
        queryParameters: queryParameters,
      );
      final apiResponse =
          _parseApiResponse<PageResponse<AdminActivityLogModel>>(
            response.data,
            (json) => _readLogPage(json, page: page, size: size),
          );

      return await _requireData(apiResponse);
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  ApiResponse<T> _parseApiResponse<T>(
    Object? data,
    T Function(dynamic json) fromJsonT,
  ) {
    final response = ApiResponse<T>.fromJson(_asJsonObject(data), fromJsonT);

    if (response.status >= 400) {
      throw ApiException(
        _messageOrDefault(response.message),
        statusCode: response.status,
      );
    }

    return response;
  }

  T _requireData<T>(ApiResponse<T> response) {
    final data = response.data;
    if (data == null) {
      throw ApiException(
        _messageOrDefault(response.message),
        statusCode: response.status,
      );
    }

    return data;
  }

  PageResponse<AdminActivityLogModel> _readLogPage(
    Object? data, {
    required int page,
    required int size,
  }) {
    if (data is Map) {
      final json = _asJsonObject(data);
      if (json.containsKey('content')) {
        return PageResponse<AdminActivityLogModel>.fromJson(
          json,
          (item) => AdminActivityLogModel.fromJson(_asJsonObject(item)),
        );
      }
    }

    final content = _asList(data)
        .map((item) => AdminActivityLogModel.fromJson(_asJsonObject(item)))
        .toList();
    return PageResponse<AdminActivityLogModel>(
      content: content,
      page: page,
      size: size,
      totalElements: content.length,
      totalPages: 1,
      last: true,
    );
  }

  ApiException _toApiException(DioException error) {
    final apiException = error.error;
    if (apiException is ApiException) {
      return ApiException(
        _extractBackendMessage(error.response?.data) ??
            (apiException.statusCode == 403
                ? _permissionErrorMessage
                : apiException.message),
        statusCode: apiException.statusCode,
      );
    }

    final statusCode = error.response?.statusCode;
    if (statusCode == 403) {
      return const ApiException(_permissionErrorMessage, statusCode: 403);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException(
        _extractBackendMessage(error.response?.data) ?? _connectionErrorMessage,
        statusCode: statusCode,
      );
    }

    return ApiException(
      _extractBackendMessage(error.response?.data) ?? _defaultErrorMessage,
      statusCode: statusCode,
    );
  }

  String _messageOrDefault(String message) {
    return message.trim().isEmpty ? _defaultErrorMessage : message;
  }

  String? _extractBackendMessage(Object? data) {
    final json = data is Map ? _asJsonObject(data) : null;
    final message = json?['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message;
    }

    return null;
  }

  Map<String, dynamic> _asJsonObject(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    return const {};
  }

  List<Object?> _asList(Object? data) {
    return data is List ? data : const [];
  }
}
