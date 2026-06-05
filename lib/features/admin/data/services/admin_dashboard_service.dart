import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_dashboard_model.dart';
import '../models/order_status_statistic_model.dart';
import '../models/revenue_statistic_model.dart';

class AdminDashboardService {
  AdminDashboardService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<AdminDashboardModel> getOverview() async {
    final response = await _get<AdminDashboardModel>(
      ApiConstants.adminDashboardOverview,
      (json) => AdminDashboardModel.fromJson(_asJsonObject(json)),
    );

    return _requireData(response);
  }

  Future<List<OrderStatusStatisticModel>> getOrderStatusStatistics() async {
    final response = await _get<List<OrderStatusStatisticModel>>(
      ApiConstants.adminDashboardOrderStatus,
      (json) => _asList(json)
          .map(
            (item) => OrderStatusStatisticModel.fromJson(_asJsonObject(item)),
          )
          .toList(),
    );

    return response.data ?? const [];
  }

  Future<List<RevenueStatisticModel>> getRevenueLast7Days() async {
    final response = await _get<List<RevenueStatisticModel>>(
      ApiConstants.adminDashboardRevenueLast7Days,
      (json) => _asList(json)
          .map((item) => RevenueStatisticModel.fromJson(_asJsonObject(item)))
          .toList(),
    );

    return response.data ?? const [];
  }

  Future<ApiResponse<T>> _get<T>(
    String path,
    T Function(dynamic json) fromJsonT,
  ) async {
    try {
      final response = await _dioClient.get<dynamic>(path);
      return _parseApiResponse<T>(response.data, fromJsonT);
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

  List<Object?> _asList(Object? data) {
    return data is List ? data : const [];
  }
}
