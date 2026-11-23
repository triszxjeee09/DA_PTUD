import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/admin_user_model.dart';
import '../models/assign_role_request_model.dart';
import '../models/update_user_status_request_model.dart';

class AdminUserService {
  AdminUserService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const String _expiredSessionMessage = 'Phiên đăng nhập đã hết hạn';
  static const String _permissionErrorMessage =
      'Bạn không có quyền thực hiện thao tác này';
  static const String _notFoundMessage = 'Không tìm thấy người dùng';

  final DioClient _dioClient;

  Future<PageResponse<AdminUserModel>> getUsers({
    int page = 0,
    int size = 10,
    String? keyword,
    String? status,
    String? role,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
      if (role != null && role.trim().isNotEmpty) 'role': role.trim(),
    };

    try {
      final response = await _dioClient.dio.get<dynamic>(
        ApiConstants.adminUsers,
        queryParameters: queryParameters,
      );
      final apiResponse = _parseApiResponse<PageResponse<AdminUserModel>>(
        response.data,
        (json) => _readUserPage(json, page: page, size: size),
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

  Future<AdminUserModel> getUserById(String userId) async {
    try {
      final response = await _dioClient.dio.get<dynamic>(
        '${ApiConstants.adminUsers}/$userId',
      );
      final apiResponse = _parseApiResponse<AdminUserModel>(
        response.data,
        (json) => AdminUserModel.fromJson(_asJsonObject(json)),
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

  Future<AdminUserModel> updateUserStatus({
    required String userId,
    required String status,
  }) async {
    final user = await _putUserOrNull(
      '${ApiConstants.adminUsers}/$userId/status',
      data: UpdateUserStatusRequestModel(status: status).toJson(),
    );

    if (user == null) {
      throw const ApiException(_defaultErrorMessage);
    }

    return user;
  }

  Future<AdminUserModel?> blockUser(String userId) {
    return _putUserOrNull('${ApiConstants.adminUsers}/$userId/block');
  }

  Future<AdminUserModel?> unlockUser(String userId) {
    return _putUserOrNull('${ApiConstants.adminUsers}/$userId/unlock');
  }

  Future<AdminUserModel?> resetPassword({
    required String userId,
    required String newPassword,
    required String confirmPassword,
  }) {
    return _putUserOrNull(
      '${ApiConstants.adminUsers}/$userId/reset-password',
      data: {'newPassword': newPassword, 'confirmPassword': confirmPassword},
    );
  }

  Future<void> deactivateUser(String userId) async {
    try {
      final response = await _dioClient.dio.delete<dynamic>(
        '${ApiConstants.adminUsers}/$userId',
      );
      _parseApiResponse<void>(response.data, (_) {});
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<AdminUserModel?> _putUserOrNull(String path, {Object? data}) async {
    try {
      final response = await _dioClient.dio.put<dynamic>(path, data: data);
      final apiResponse = _parseApiResponse<AdminUserModel?>(
        response.data,
        (json) =>
            json == null ? null : AdminUserModel.fromJson(_asJsonObject(json)),
      );

      return apiResponse.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<AdminUserModel?> assignRole({
    required String userId,
    required String roleName,
  }) async {
    try {
      final response = await _dioClient.dio.post<dynamic>(
        '${ApiConstants.adminUsers}/$userId/roles',
        data: AssignRoleRequestModel(roleName: roleName).toJson(),
      );
      final apiResponse = _parseApiResponse<AdminUserModel?>(
        response.data,
        (json) =>
            json == null ? null : AdminUserModel.fromJson(_asJsonObject(json)),
      );

      return apiResponse.data;
    } on DioException catch (error) {
      throw _toApiException(error);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  Future<AdminUserModel?> removeRole({
    required String userId,
    required String roleName,
  }) async {
    try {
      final encodedRoleName = Uri.encodeComponent(roleName);
      final response = await _dioClient.dio.delete<dynamic>(
        '${ApiConstants.adminUsers}/$userId/roles/$encodedRoleName',
      );
      final apiResponse = _parseApiResponse<AdminUserModel?>(
        response.data,
        (json) =>
            json == null ? null : AdminUserModel.fromJson(_asJsonObject(json)),
      );

      return apiResponse.data;
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

  PageResponse<AdminUserModel> _readUserPage(
    Object? data, {
    required int page,
    required int size,
  }) {
    if (data is Map) {
      final json = _asJsonObject(data);
      if (json.containsKey('content')) {
        return PageResponse<AdminUserModel>.fromJson(
          json,
          (item) => AdminUserModel.fromJson(_asJsonObject(item)),
        );
      }
    }

    final content = _asList(
      data,
    ).map((item) => AdminUserModel.fromJson(_asJsonObject(item))).toList();
    return PageResponse<AdminUserModel>(
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

    if (statusCode == 404) {
      return _notFoundMessage;
    }

    final normalizedMessage = message?.trim();
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
