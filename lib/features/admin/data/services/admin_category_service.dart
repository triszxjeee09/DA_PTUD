import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/admin_category_model.dart';
import '../models/admin_category_request_model.dart';

class AdminCategoryService {
  AdminCategoryService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const String _expiredSessionMessage = 'Phiên đăng nhập đã hết hạn';
  static const String _permissionErrorMessage =
      'Bạn không có quyền quản lý danh mục';
  static const String _duplicateSlugMessage = 'Slug danh mục đã tồn tại';

  final DioClient _dioClient;

  Future<PageResponse<AdminCategoryModel>> getCategories({
    int page = 0,
    int size = 10,
    String? keyword,
    bool? isActive,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
      if (isActive != null) 'isActive': isActive,
    };

    try {
      final response = await _dioClient.dio.get<dynamic>(
        ApiConstants.adminCategories,
        queryParameters: queryParameters,
      );
      final apiResponse = _parseApiResponse<PageResponse<AdminCategoryModel>>(
        response.data,
        (json) => _readCategoryPage(json, page: page, size: size),
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

  Future<AdminCategoryModel> getCategoryById(String id) async {
    try {
      final response = await _dioClient.dio.get<dynamic>(
        '${ApiConstants.categories}/$id',
      );
      final apiResponse = _parseApiResponse<AdminCategoryModel>(
        response.data,
        (json) => AdminCategoryModel.fromJson(_asJsonObject(json)),
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

  Future<AdminCategoryModel> createCategory(
    AdminCategoryRequestModel request,
  ) async {
    try {
      final response = await _dioClient.dio.post<dynamic>(
        ApiConstants.categories,
        data: request.toJson(),
      );
      final apiResponse = _parseApiResponse<AdminCategoryModel>(
        response.data,
        (json) => AdminCategoryModel.fromJson(_asJsonObject(json)),
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

  Future<AdminCategoryModel> updateCategory(
    String id,
    AdminCategoryRequestModel request,
  ) async {
    try {
      final response = await _dioClient.dio.put<dynamic>(
        '${ApiConstants.categories}/$id',
        data: request.toJson(),
      );
      final apiResponse = _parseApiResponse<AdminCategoryModel>(
        response.data,
        (json) => AdminCategoryModel.fromJson(_asJsonObject(json)),
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

  Future<void> deleteCategory(String id) async {
    try {
      final response = await _dioClient.dio.delete<dynamic>(
        '${ApiConstants.categories}/$id',
      );
      final apiResponse = ApiResponse<void>.fromJson(
        _asJsonObject(response.data),
        (_) {},
      );

      if (apiResponse.status >= 400) {
        throw ApiException(
          _normalizeErrorMessage(
            statusCode: apiResponse.status,
            message:
                _extractValidationMessage(response.data) ?? apiResponse.message,
          ),
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
    final json = _asJsonObject(data);
    final response = ApiResponse<T>.fromJson(json, fromJsonT);

    if (response.status >= 400) {
      throw ApiException(
        _normalizeErrorMessage(
          statusCode: response.status,
          message: _extractValidationMessage(json) ?? response.message,
        ),
        statusCode: response.status,
      );
    }

    return response;
  }

  T _requireData<T>(ApiResponse<T> response) {
    final data = response.data;
    if (data == null) {
      throw ApiException(
        _normalizeErrorMessage(
          statusCode: response.status,
          message: response.message,
        ),
        statusCode: response.status,
      );
    }

    return data;
  }

  PageResponse<AdminCategoryModel> _readCategoryPage(
    Object? data, {
    required int page,
    required int size,
  }) {
    if (data is Map) {
      final json = _asJsonObject(data);
      if (json.containsKey('content')) {
        return PageResponse<AdminCategoryModel>.fromJson(
          json,
          (item) => AdminCategoryModel.fromJson(_asJsonObject(item)),
        );
      }
    }

    final content = _asList(
      data,
    ).map((item) => AdminCategoryModel.fromJson(_asJsonObject(item))).toList();
    return PageResponse<AdminCategoryModel>(
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
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final backendMessage =
        _extractValidationMessage(responseData) ??
        _extractBackendMessage(responseData);

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException(
        _normalizeErrorMessage(
          statusCode: statusCode,
          message: backendMessage ?? _connectionErrorMessage,
        ),
        statusCode: statusCode,
      );
    }

    if (apiException is ApiException) {
      return ApiException(
        _normalizeErrorMessage(
          statusCode: apiException.statusCode ?? statusCode,
          message: backendMessage ?? apiException.message,
        ),
        statusCode: apiException.statusCode ?? statusCode,
      );
    }

    return ApiException(
      _normalizeErrorMessage(
        statusCode: statusCode,
        message: backendMessage ?? _defaultErrorMessage,
      ),
      statusCode: statusCode,
    );
  }

  String _normalizeErrorMessage({required int? statusCode, String? message}) {
    if (statusCode == 401) {
      return _expiredSessionMessage;
    }

    if (statusCode == 403) {
      return _permissionErrorMessage;
    }

    final normalizedMessage = message?.trim();
    final lowerMessage = normalizedMessage?.toLowerCase() ?? '';
    if (statusCode == 409 ||
        (lowerMessage.contains('slug') &&
            (lowerMessage.contains('exist') ||
                lowerMessage.contains('duplicate') ||
                lowerMessage.contains('tồn tại') ||
                lowerMessage.contains('trùng')))) {
      return _duplicateSlugMessage;
    }

    if (normalizedMessage == null ||
        normalizedMessage.isEmpty ||
        normalizedMessage.contains('Ãƒ') ||
        normalizedMessage.contains('Ã„')) {
      return _defaultErrorMessage;
    }

    return normalizedMessage;
  }

  String? _extractValidationMessage(Object? data) {
    final json = data is Map ? _asJsonObject(data) : null;
    final validationErrors = json?['validationErrors'];

    if (validationErrors is List) {
      for (final item in validationErrors) {
        final message = _validationItemMessage(item);
        if (message != null) {
          return message;
        }
      }
    }

    if (validationErrors is Map) {
      for (final value in validationErrors.values) {
        final message = _validationItemMessage(value);
        if (message != null) {
          return message;
        }
      }
    }

    return null;
  }

  String? _validationItemMessage(Object? item) {
    if (item is String && item.trim().isNotEmpty) {
      return item.trim();
    }

    if (item is List) {
      for (final value in item) {
        final message = _validationItemMessage(value);
        if (message != null) {
          return message;
        }
      }
    }

    if (item is Map) {
      final json = _asJsonObject(item);
      final message = json['message'] ?? json['error'] ?? json['detail'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return null;
  }

  String? _extractBackendMessage(Object? data) {
    final json = data is Map ? _asJsonObject(data) : null;
    final message =
        json?['message'] ?? json?['error'] ?? json?['detail'] ?? json?['title'];

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
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
