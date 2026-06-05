import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<PageResponse<NotificationModel>> getNotifications({
    int page = 0,
    int size = 10,
  }) {
    return _requestNotificationPage(
      () => _dioClient.get<dynamic>(
        ApiConstants.notifications,
        queryParameters: {'page': page, 'size': size},
      ),
    );
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dioClient.get<dynamic>(ApiConstants.unreadCount);
      final apiResponse = _parseApiResponse<int>(
        response.data,
        _readUnreadCount,
      );

      return _requireData(apiResponse);
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<NotificationModel> markAsRead(String id) async {
    try {
      final response = await _dioClient.put<dynamic>(
        '${ApiConstants.notifications}/$id/read',
      );
      final apiResponse = _parseApiResponse<NotificationModel>(
        response.data,
        (json) => NotificationModel.fromJson(_asJsonObject(json)),
      );

      return _requireData(apiResponse);
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _dioClient.put<dynamic>(
        '${ApiConstants.notifications}/read-all',
      );
      final apiResponse = ApiResponse<void>.fromJson(
        _asJsonObject(response.data),
        (_) {},
      );

      if (apiResponse.status >= 400) {
        throw ApiException(
          _messageOrDefault(apiResponse.message),
          statusCode: apiResponse.status,
        );
      }
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<PageResponse<NotificationModel>> _requestNotificationPage(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final apiResponse = _parseApiResponse<PageResponse<NotificationModel>>(
        response.data,
        (json) => PageResponse<NotificationModel>.fromJson(
          _asJsonObject(json),
          (item) => NotificationModel.fromJson(_asJsonObject(item)),
        ),
      );

      return _requireData(apiResponse);
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

  int _readUnreadCount(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    if (value is Map) {
      final json = _asJsonObject(value);
      final count = json['count'] ?? json['unreadCount'];
      return _readUnreadCount(count);
    }

    return 0;
  }

  ApiException _toApiException(DioException error) {
    final apiException = error.error;
    if (apiException is ApiException) {
      return ApiException(
        _extractBackendMessage(error.response?.data) ?? apiException.message,
        statusCode: apiException.statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException(
        _extractBackendMessage(error.response?.data) ?? _connectionErrorMessage,
        statusCode: error.response?.statusCode,
      );
    }

    return ApiException(
      _extractBackendMessage(error.response?.data) ?? _defaultErrorMessage,
      statusCode: error.response?.statusCode,
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
}
