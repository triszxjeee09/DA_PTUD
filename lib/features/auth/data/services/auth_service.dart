import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_response_model.dart';
import '../models/forgot_password_request_model.dart';
import '../models/forgot_password_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/reset_password_with_otp_request_model.dart';
import '../models/user_model.dart';
import '../models/verify_forgot_password_otp_request_model.dart';
import '../models/verify_forgot_password_otp_response_model.dart';

class AuthService {
  AuthService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<AuthResponseModel> login(LoginRequestModel request) async {
    final response = await _post<AuthResponseModel>(
      ApiConstants.login,
      data: request.toJson(),
      fromJsonT: (json) => AuthResponseModel.fromJson(_asJsonObject(json)),
      skipAuth: true,
    );

    return _requireData(response);
  }

  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    final response = await _post<AuthResponseModel>(
      ApiConstants.register,
      data: request.toJson(),
      fromJsonT: (json) => AuthResponseModel.fromJson(_asJsonObject(json)),
      skipAuth: true,
    );

    return _requireData(response);
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dioClient.get<dynamic>(ApiConstants.me);
      final apiResponse = _parseApiResponse<UserModel>(
        response.data,
        (json) => UserModel.fromJson(_asJsonObject(json)),
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

  Future<ForgotPasswordResponseModel> forgotPassword(
    ForgotPasswordRequestModel request,
  ) async {
    final response = await _post<ForgotPasswordResponseModel>(
      ApiConstants.forgotPassword,
      data: request.toJson(),
      fromJsonT: (json) =>
          ForgotPasswordResponseModel.fromJson(_asJsonObject(json)),
      fallbackMessage: 'Không thể gửi mã xác thực',
      skipAuth: true,
    );

    return _requireData(response, fallbackMessage: 'Không thể gửi mã xác thực');
  }

  Future<VerifyForgotPasswordOtpResponseModel> verifyForgotPasswordOtp(
    VerifyForgotPasswordOtpRequestModel request,
  ) async {
    final response = await _post<VerifyForgotPasswordOtpResponseModel>(
      ApiConstants.verifyForgotPasswordOtp,
      data: request.toJson(),
      fromJsonT: (json) =>
          VerifyForgotPasswordOtpResponseModel.fromJson(_asJsonObject(json)),
      fallbackMessage: 'Mã xác thực không hợp lệ',
      skipAuth: true,
    );

    return _requireData(response, fallbackMessage: 'Mã xác thực không hợp lệ');
  }

  Future<void> resetPasswordWithOtp(
    ResetPasswordWithOtpRequestModel request,
  ) async {
    await _post<void>(
      ApiConstants.resetPasswordWithOtp,
      data: request.toJson(),
      fromJsonT: (_) {},
      fallbackMessage: 'Không thể đặt lại mật khẩu',
      skipAuth: true,
    );
  }

  Future<void> logout() async {
    try {
      final response = await _dioClient.post<dynamic>(ApiConstants.logout);
      final apiResponse = ApiResponse<void>.fromJson(
        _asJsonObject(response.data),
        (_) {},
      );

      if (apiResponse.status >= 400) {
        debugPrint(_messageOrDefault(apiResponse.message));
      }
    } on ApiException catch (error) {
      if (error.statusCode == null ||
          error.statusCode == 401 ||
          error.statusCode == 403) {
        return;
      }

      debugPrint('Logout API failed: ${error.message}');
    } on DioException catch (error) {
      if (_isConnectionError(error) ||
          error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return;
      }

      debugPrint('Logout API failed: ${error.message}');
    } catch (error) {
      debugPrint('Logout API failed: $error');
    }
  }

  Future<ApiResponse<T>> _post<T>(
    String path, {
    required Map<String, dynamic> data,
    required T Function(dynamic json) fromJsonT,
    String? fallbackMessage,
    bool skipAuth = false,
  }) async {
    try {
      final response = await _dioClient.post<dynamic>(
        path,
        data: data,
        options: skipAuth ? Options(extra: const {'skipAuth': true}) : null,
      );
      return _parseApiResponse<T>(
        response.data,
        fromJsonT,
        fallbackMessage: fallbackMessage,
      );
    } on DioException catch (error) {
      throw _toApiException(error, fallbackMessage: fallbackMessage);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(fallbackMessage ?? _defaultErrorMessage);
    }
  }

  ApiResponse<T> _parseApiResponse<T>(
    Object? data,
    T Function(dynamic json) fromJsonT, {
    String? fallbackMessage,
  }) {
    final json = _asJsonObject(data);
    final response = ApiResponse<T>.fromJson(json, fromJsonT);

    if (response.status >= 400) {
      throw ApiException(
        _messageOrDefault(response.message, fallback: fallbackMessage),
        statusCode: response.status,
      );
    }

    return response;
  }

  T _requireData<T>(ApiResponse<T> response, {String? fallbackMessage}) {
    final data = response.data;
    if (data == null) {
      throw ApiException(
        _messageOrDefault(response.message, fallback: fallbackMessage),
        statusCode: response.status,
      );
    }

    return data;
  }

  ApiException _toApiException(DioException error, {String? fallbackMessage}) {
    final apiException = error.error;
    if (apiException is ApiException) {
      return ApiException(
        _extractBackendMessage(error.response?.data) ??
            _messageOrDefault(apiException.message, fallback: fallbackMessage),
        statusCode: apiException.statusCode,
      );
    }

    if (_isConnectionError(error)) {
      return ApiException(
        _extractBackendMessage(error.response?.data) ??
            fallbackMessage ??
            _connectionErrorMessage,
        statusCode: error.response?.statusCode,
      );
    }

    return ApiException(
      _extractBackendMessage(error.response?.data) ??
          fallbackMessage ??
          _defaultErrorMessage,
      statusCode: error.response?.statusCode,
    );
  }

  bool _isConnectionError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  String _messageOrDefault(String message, {String? fallback}) {
    return message.trim().isEmpty ? fallback ?? _defaultErrorMessage : message;
  }

  String? _extractBackendMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
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
