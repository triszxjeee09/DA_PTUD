import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../category/data/models/category_model.dart';
import '../models/admin_category_request_model.dart';

class AdminCategoryService {
  AdminCategoryService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await _dioClient.get<dynamic>(
        ApiConstants.categoryAdmin,
      );
      final apiResponse = _parseApiResponse<List<CategoryModel>>(
        response.data,
        (json) => _readCategoryList(json),
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

  Future<CategoryModel> getCategoryDetail(String id) async {
    try {
      final response = await _dioClient.get<dynamic>(
        '${ApiConstants.categories}/$id',
      );
      final apiResponse = _parseApiResponse<CategoryModel>(
        response.data,
        (json) => CategoryModel.fromJson(_asJsonObject(json)),
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

  Future<CategoryModel> createCategory(
    AdminCategoryRequestModel request,
  ) async {
    try {
      final response = await _dioClient.post<dynamic>(
        ApiConstants.categories,
        data: request.toJson(),
      );
      final apiResponse = _parseApiResponse<CategoryModel>(
        response.data,
        (json) => CategoryModel.fromJson(_asJsonObject(json)),
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

  Future<CategoryModel> updateCategory(
    String id,
    AdminCategoryRequestModel request,
  ) async {
    try {
      final response = await _dioClient.put<dynamic>(
        '${ApiConstants.categories}/$id',
        data: request.toJson(),
      );
      final apiResponse = _parseApiResponse<CategoryModel>(
        response.data,
        (json) => CategoryModel.fromJson(_asJsonObject(json)),
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

  Future<void> deleteCategory(String id) async {
    try {
      final response = await _dioClient.delete<dynamic>(
        '${ApiConstants.categories}/$id',
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

  List<CategoryModel> _readCategoryList(Object? data) {
    final list = data is Map ? _asJsonObject(data)['content'] : data;
    return _asList(
      list,
    ).map((item) => CategoryModel.fromJson(_asJsonObject(item))).toList();
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
