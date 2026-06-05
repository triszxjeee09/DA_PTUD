import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/create_payment_request_model.dart';
import '../models/payment_model.dart';
import '../models/update_payment_status_request_model.dart';
import '../models/vnpay_create_payment_request_model.dart';
import '../models/vnpay_create_payment_response_model.dart';

class PaymentService {
  PaymentService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<PaymentModel> createPayment(CreatePaymentRequestModel request) {
    return _requestPayment(
      () => _dioClient.post<dynamic>(
        ApiConstants.payments,
        data: request.toJson(),
      ),
    );
  }

  Future<VnPayCreatePaymentResponseModel> createVnPayPayment(
    VnPayCreatePaymentRequestModel request,
  ) {
    return _requestVnPayPayment(
      () => _dioClient.post<dynamic>(
        ApiConstants.vnpayCreatePayment,
        data: request.toJson(),
      ),
    );
  }

  Future<PaymentModel> updatePaymentStatus(
    String paymentId,
    UpdatePaymentStatusRequestModel request,
  ) {
    return _requestPayment(
      () => _dioClient.put<dynamic>(
        '${ApiConstants.payments}/$paymentId/status',
        data: request.toJson(),
      ),
    );
  }

  Future<PaymentModel> getPaymentByOrderId(String orderId) {
    return _requestPayment(
      () => _dioClient.get<dynamic>('${ApiConstants.payments}/order/$orderId'),
    );
  }

  Future<List<PaymentModel>> getMyPayments() {
    return _requestPaymentList(
      () => _dioClient.get<dynamic>(ApiConstants.myPayments),
    );
  }

  Future<PaymentModel> _requestPayment(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final apiResponse = _parseApiResponse<PaymentModel>(
        response.data,
        (json) => PaymentModel.fromJson(_asJsonObject(json)),
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

  Future<VnPayCreatePaymentResponseModel> _requestVnPayPayment(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final apiResponse = _parseApiResponse<VnPayCreatePaymentResponseModel>(
        response.data,
        (json) => VnPayCreatePaymentResponseModel.fromJson(_asJsonObject(json)),
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

  Future<List<PaymentModel>> _requestPaymentList(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final apiResponse = _parseApiResponse<List<PaymentModel>>(
        response.data,
        _readPayments,
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

  List<PaymentModel> _readPayments(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .map(PaymentModel.fromJson)
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
