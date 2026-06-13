import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/admin_voucher_model.dart';
import '../models/admin_voucher_request_model.dart';

class AdminVoucherService {
  AdminVoucherService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const String _expiredSessionMessage = 'Phiên đăng nhập đã hết hạn';
  static const String _permissionErrorMessage =
      'Bạn không có quyền quản lý voucher';
  static const String _duplicateCodeMessage = 'Mã voucher đã tồn tại';
  static const String _invalidDateMessage =
      'Ngày kết thúc phải sau ngày bắt đầu';

  final DioClient _dioClient;

  Future<PageResponse<AdminVoucherModel>> getVouchers({
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
      final response = await _requestWithFallback<dynamic>(
        primary: () => _dioClient.get<dynamic>(
          ApiConstants.adminVouchers,
          queryParameters: queryParameters,
        ),
        fallback: () => _dioClient.get<dynamic>(
          ApiConstants.legacyAdminVouchers,
          queryParameters: queryParameters,
        ),
      );
      final apiResponse = _parseApiResponse<PageResponse<AdminVoucherModel>>(
        response.data,
        (json) => _readVoucherPage(json, page: page, size: size),
      );

      return _requireData(apiResponse);
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException catch (error) {
      throw _normalizeApiException(error);
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<AdminVoucherModel> getVoucherById(String id) async {
    try {
      final response = await _requestWithFallback<dynamic>(
        primary: () =>
            _dioClient.get<dynamic>('${ApiConstants.adminVouchers}/$id'),
        fallback: () => _dioClient.get<dynamic>('${ApiConstants.vouchers}/$id'),
      );
      final apiResponse = _parseApiResponse<AdminVoucherModel>(
        response.data,
        (json) => AdminVoucherModel.fromJson(_asJsonObject(json)),
      );

      return _requireData(apiResponse);
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException catch (error) {
      throw _normalizeApiException(error);
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<AdminVoucherModel> createVoucher(
    AdminVoucherRequestModel request,
  ) async {
    try {
      final response = await _requestWithFallback<dynamic>(
        primary: () => _dioClient.post<dynamic>(
          ApiConstants.adminVouchers,
          data: request.toJson(),
        ),
        fallback: () => _dioClient.post<dynamic>(
          ApiConstants.vouchers,
          data: request.toJson(),
        ),
      );
      final apiResponse = _parseApiResponse<AdminVoucherModel>(
        response.data,
        (json) => AdminVoucherModel.fromJson(_asJsonObject(json)),
      );

      return _requireData(apiResponse);
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException catch (error) {
      throw _normalizeApiException(error);
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<AdminVoucherModel> updateVoucher(
    String id,
    AdminVoucherRequestModel request,
  ) async {
    try {
      final response = await _requestWithFallback<dynamic>(
        primary: () => _dioClient.put<dynamic>(
          '${ApiConstants.adminVouchers}/$id',
          data: request.toJson(),
        ),
        fallback: () => _dioClient.put<dynamic>(
          '${ApiConstants.vouchers}/$id',
          data: request.toJson(),
        ),
      );
      final apiResponse = _parseApiResponse<AdminVoucherModel>(
        response.data,
        (json) => AdminVoucherModel.fromJson(_asJsonObject(json)),
      );

      return _requireData(apiResponse);
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException catch (error) {
      throw _normalizeApiException(error);
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<void> deleteVoucher(String id) async {
    try {
      final response = await _requestWithFallback<dynamic>(
        primary: () =>
            _dioClient.delete<dynamic>('${ApiConstants.adminVouchers}/$id'),
        fallback: () =>
            _dioClient.delete<dynamic>('${ApiConstants.vouchers}/$id'),
      );
      _ensureDeleteSucceeded(response);
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException catch (error) {
      throw _normalizeApiException(error);
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<Response<T>> _requestWithFallback<T>({
    required Future<Response<T>> Function() primary,
    required Future<Response<T>> Function() fallback,
  }) async {
    try {
      return await primary();
    } on ApiException catch (error) {
      if (_shouldTryLegacyEndpoint(error)) {
        return fallback();
      }

      rethrow;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 404 || statusCode == 405) {
        return fallback();
      }

      rethrow;
    }
  }

  bool _shouldTryLegacyEndpoint(ApiException error) {
    return error.statusCode == 404 || error.statusCode == 405;
  }

  ApiResponse<T> _parseApiResponse<T>(
    Object? data,
    T Function(Object? json) fromJsonT,
  ) {
    if (data == null) {
      return const ApiResponse(status: 200, message: '');
    }

    final json = data is Map ? _asJsonObject(data) : null;
    if (json == null || !_isApiResponse(json)) {
      return ApiResponse<T>(status: 200, message: '', data: fromJsonT(data));
    }

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

  void _ensureDeleteSucceeded(Response<dynamic> response) {
    final statusCode = response.statusCode ?? 200;
    if (statusCode >= 400) {
      throw ApiException(
        _normalizeErrorMessage(
          statusCode: statusCode,
          message: _extractBackendMessage(response.data),
        ),
        statusCode: statusCode,
      );
    }

    final data = response.data;
    if (data == null || (data is String && data.trim().isEmpty)) {
      return;
    }

    final json = data is Map ? _asJsonObject(data) : null;
    if (json == null || !_isApiResponse(json)) {
      return;
    }

    final apiResponse = ApiResponse<void>.fromJson(json, (_) {});
    if (apiResponse.status >= 400) {
      throw ApiException(
        _normalizeErrorMessage(
          statusCode: apiResponse.status,
          message: _extractValidationMessage(json) ?? apiResponse.message,
        ),
        statusCode: apiResponse.status,
      );
    }
  }

  PageResponse<AdminVoucherModel> _readVoucherPage(
    Object? data, {
    required int page,
    required int size,
  }) {
    if (data is Map) {
      final json = _asJsonObject(data);
      if (json.containsKey('content')) {
        return PageResponse<AdminVoucherModel>.fromJson(
          json,
          (item) => AdminVoucherModel.fromJson(_asJsonObject(item)),
        );
      }
    }

    final content = _asList(
      data,
    ).map((item) => AdminVoucherModel.fromJson(_asJsonObject(item))).toList();
    return PageResponse<AdminVoucherModel>(
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

  ApiException _normalizeApiException(ApiException error) {
    return ApiException(
      _normalizeErrorMessage(
        statusCode: error.statusCode,
        message: error.message,
      ),
      statusCode: error.statusCode,
    );
  }

  String _normalizeErrorMessage({required int? statusCode, String? message}) {
    final normalizedMessage = message?.trim();
    final lowerMessage = normalizedMessage?.toLowerCase() ?? '';

    if (statusCode == 401) {
      return _expiredSessionMessage;
    }

    if (statusCode == 403) {
      return _permissionErrorMessage;
    }

    if (statusCode == 409 ||
        ((lowerMessage.contains('voucher') || lowerMessage.contains('code')) &&
            (lowerMessage.contains('exist') ||
                lowerMessage.contains('duplicate') ||
                lowerMessage.contains('tồn tại') ||
                lowerMessage.contains('trùng')))) {
      return _duplicateCodeMessage;
    }

    if (lowerMessage.contains('ngày') ||
        lowerMessage.contains('date') ||
        lowerMessage.contains('start') ||
        lowerMessage.contains('end')) {
      return _invalidDateMessage;
    }

    if (normalizedMessage == null ||
        normalizedMessage.isEmpty ||
        normalizedMessage.contains('Ã') ||
        normalizedMessage.contains('Ä')) {
      return _defaultErrorMessage;
    }

    return normalizedMessage;
  }

  String? _extractValidationMessage(Object? data) {
    final json = data is Map ? _asJsonObject(data) : null;
    final validationErrors = json?['validationErrors'] ?? json?['errors'];

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
      final message =
          json['message'] ?? json['error'] ?? json['detail'] ?? json['reason'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return null;
  }

  String? _extractBackendMessage(Object? data) {
    final json = data is Map ? _asJsonObject(data) : null;
    final message =
        _extractValidationMessage(data) ??
        json?['message'] ??
        json?['error'] ??
        json?['detail'] ??
        json?['title'];

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return null;
  }

  bool _isApiResponse(Map<String, dynamic> json) {
    return json.containsKey('status') ||
        json.containsKey('message') ||
        json.containsKey('data') ||
        json.containsKey('timestamp');
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
