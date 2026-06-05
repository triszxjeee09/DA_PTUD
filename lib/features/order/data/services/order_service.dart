import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/cancel_order_request_model.dart';
import '../models/create_order_request_model.dart';
import '../models/order_detail_model.dart';
import '../models/order_model.dart';
import '../models/order_status_history_model.dart';

class OrderService {
  OrderService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<OrderDetailModel> createOrder(CreateOrderRequestModel request) {
    return _requestOrderDetail(
      () =>
          _dioClient.post<dynamic>(ApiConstants.orders, data: request.toJson()),
    );
  }

  Future<PageResponse<OrderModel>> getMyOrders({
    int page = 0,
    int size = 10,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };

    try {
      final response = await _dioClient.get<dynamic>(
        ApiConstants.myOrders,
        queryParameters: queryParameters,
      );
      final apiResponse = _parseApiResponse<PageResponse<OrderModel>>(
        response.data,
        (json) => PageResponse<OrderModel>.fromJson(
          _asJsonObject(json),
          (item) => OrderModel.fromJson(_asJsonObject(item)),
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

  Future<OrderDetailModel> getOrderDetail(String orderId) {
    return _requestOrderDetail(
      () => _dioClient.get<dynamic>('${ApiConstants.orders}/$orderId'),
    );
  }

  Future<List<OrderStatusHistoryModel>> getOrderStatusHistory(String orderId) {
    return _requestStatusHistories(
      () => _dioClient.get<dynamic>(
        '${ApiConstants.orders}/$orderId/status-history',
      ),
    );
  }

  Future<OrderDetailModel> cancelOrder(
    String orderId,
    CancelOrderRequestModel request,
  ) {
    return _requestOrderDetail(
      () => _dioClient.put<dynamic>(
        '${ApiConstants.orders}/$orderId/cancel',
        data: request.toJson(),
      ),
    );
  }

  Future<OrderDetailModel> _requestOrderDetail(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final apiResponse = _parseApiResponse<OrderDetailModel>(
        response.data,
        (json) => OrderDetailModel.fromJson(_asJsonObject(json)),
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

  Future<List<OrderStatusHistoryModel>> _requestStatusHistories(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final apiResponse = _parseApiResponse<List<OrderStatusHistoryModel>>(
        response.data,
        _readStatusHistories,
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

  List<OrderStatusHistoryModel> _readStatusHistories(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(OrderStatusHistoryModel.fromJson)
        .toList();
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
