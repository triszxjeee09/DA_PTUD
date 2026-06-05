import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/add_to_cart_request_model.dart';
import '../models/cart_model.dart';
import '../models/update_cart_item_request_model.dart';

class CartService {
  CartService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<CartModel> getMyCart() {
    return _requestCart(() => _dioClient.get<dynamic>(ApiConstants.cart));
  }

  Future<CartModel> addToCart(AddToCartRequestModel request) {
    return _requestCart(
      () => _dioClient.post<dynamic>(
        ApiConstants.cartItems,
        data: request.toJson(),
      ),
    );
  }

  Future<CartModel> updateCartItem(
    String cartItemId,
    UpdateCartItemRequestModel request,
  ) {
    return _requestCart(
      () => _dioClient.put<dynamic>(
        '${ApiConstants.cartItems}/$cartItemId',
        data: request.toJson(),
      ),
    );
  }

  Future<CartModel> increaseCartItem(String cartItemId) {
    return _requestCart(
      () => _dioClient.put<dynamic>(
        '${ApiConstants.cartItems}/$cartItemId/increase',
      ),
    );
  }

  Future<CartModel> decreaseCartItem(String cartItemId) {
    return _requestCart(
      () => _dioClient.put<dynamic>(
        '${ApiConstants.cartItems}/$cartItemId/decrease',
      ),
    );
  }

  Future<void> removeCartItem(String cartItemId) async {
    await _requestVoid(
      () => _dioClient.delete<dynamic>('${ApiConstants.cartItems}/$cartItemId'),
    );
  }

  Future<void> clearCart() async {
    await _requestVoid(() => _dioClient.delete<dynamic>(ApiConstants.cart));
  }

  Future<CartModel> _requestCart(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final apiResponse = _parseApiResponse<CartModel>(
        response.data,
        (json) => CartModel.fromJson(_asJsonObject(json)),
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

  Future<void> _requestVoid(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final apiResponse = _parseApiResponse<dynamic>(
        response.data,
        (json) => json,
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
}
