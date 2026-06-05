import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../inventory/data/models/inventory_model.dart';
import '../models/admin_inventory_request_model.dart';

class AdminInventoryService {
  AdminInventoryService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<List<InventoryModel>> getInventories({
    String? pharmacyId,
    String? productId,
    String? keyword,
  }) async {
    final queryParameters = <String, dynamic>{
      if (pharmacyId != null && pharmacyId.trim().isNotEmpty)
        'pharmacyId': pharmacyId.trim(),
      if (productId != null && productId.trim().isNotEmpty)
        'productId': productId.trim(),
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
    };

    try {
      final response = await _dioClient.get<dynamic>(
        ApiConstants.adminInventory,
        queryParameters: queryParameters,
      );
      final apiResponse = _parseApiResponse<List<InventoryModel>>(
        response.data,
        _readInventories,
      );

      return apiResponse.data ?? const [];
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<InventoryModel> saveInventory(
    AdminInventoryRequestModel request,
  ) async {
    try {
      final response = await _dioClient.post<dynamic>(
        ApiConstants.adminInventory,
        data: request.toJson(),
      );
      final apiResponse = _parseApiResponse<InventoryModel>(
        response.data,
        (json) => InventoryModel.fromJson(_asJsonObject(json)),
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

  Future<InventoryModel> updateQuantity(String id, int quantity) async {
    try {
      final response = await _dioClient.put<dynamic>(
        '${ApiConstants.adminInventory}/$id/quantity',
        data: {'quantity': quantity},
      );
      final apiResponse = _parseApiResponse<InventoryModel>(
        response.data,
        (json) => InventoryModel.fromJson(_asJsonObject(json)),
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

  Future<void> deleteInventory(String id) async {
    try {
      final response = await _dioClient.delete<dynamic>(
        '${ApiConstants.adminInventory}/$id',
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

  List<InventoryModel> _readInventories(Object? value) {
    if (value is Map) {
      final json = _asJsonObject(value);
      final content = json['content'];
      if (content is List) {
        return _readInventories(content);
      }
    }

    return _asList(
      value,
    ).map((item) => InventoryModel.fromJson(_asJsonObject(item))).toList();
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
