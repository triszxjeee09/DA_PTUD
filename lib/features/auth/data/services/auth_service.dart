import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/auth_response_model.dart';
import '../models/forgot_password_request_model.dart';
import '../models/forgot_password_response_model.dart';
import '../models/google_login_request_model.dart';
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
    );

    return _requireData(response);
  }

  Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    final normalizedIdToken = idToken.trim();
    if (normalizedIdToken.isEmpty) {
      throw const ApiException(
        'Dữ liệu đăng nhập Google không hợp lệ',
        statusCode: 400,
      );
    }

    final request = GoogleLoginRequestModel(idToken: normalizedIdToken);
    const fallbackMessage = 'Đăng nhập Google không thành công';

    try {
      final response = await _dioClient.post<dynamic>(
        ApiConstants.googleLogin,
        data: request.toJson(),
        options: Options(extra: const {'skipAuth': true}),
      );
      final apiResponse = _parseApiResponse<AuthResponseModel>(
        response.data,
        (json) => AuthResponseModel.fromJson(_asJsonObject(json)),
        fallbackMessage: fallbackMessage,
      );

      return _requireData(apiResponse, fallbackMessage: fallbackMessage);
    } on DioException catch (error) {
      throw _toGoogleLoginException(error);
    } on ApiException catch (error) {
      throw _googleLoginExceptionFromStatus(error.statusCode, error.message);
    } catch (_) {
      throw const ApiException(fallbackMessage);
    }
  }

  Future<AuthResponseModel> register(RegisterRequestModel request) async {
    final response = await _post<AuthResponseModel>(
      ApiConstants.register,
      data: request.toJson(),
      fromJsonT: (json) => AuthResponseModel.fromJson(_asJsonObject(json)),
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

      return _requireData(apiResponse);
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
  }) async {
    try {
      final response = await _dioClient.post<dynamic>(path, data: data);
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

  ApiException _toGoogleLoginException(DioException error) {
    final backendMessage = _extractBackendMessage(error.response?.data);
    if (_isConnectionError(error)) {
      return ApiException(
        backendMessage ?? _connectionErrorMessage,
        statusCode: error.response?.statusCode,
      );
    }

    return _googleLoginExceptionFromStatus(
      error.response?.statusCode,
      backendMessage,
    );
  }

  ApiException _googleLoginExceptionFromStatus(
    int? statusCode,
    String? message,
  ) {
    final trimmedMessage = message?.trim();
    if (trimmedMessage != null && trimmedMessage.isNotEmpty) {
      return ApiException(trimmedMessage, statusCode: statusCode);
    }

    return ApiException(
      _googleLoginFallbackMessage(statusCode),
      statusCode: statusCode,
    );
  }

  String _googleLoginFallbackMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Dữ liệu đăng nhập Google không hợp lệ';
      case 401:
        return 'Tài khoản Google không hợp lệ hoặc đã hết hạn';
      case 403:
        return 'Tài khoản không được phép đăng nhập';
      case 409:
        return 'Tài khoản Google đã được liên kết với người dùng khác';
      default:
        return 'Đăng nhập Google không thành công';
    }
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
