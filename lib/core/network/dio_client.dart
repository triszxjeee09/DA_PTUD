import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../errors/api_exception.dart';
import '../navigation/app_navigator.dart';
import '../storage/token_storage.dart';

class DioClient {
  DioClient({Dio? dio, TokenStorage? tokenStorage, String? baseUrl})
    : _tokenStorage = tokenStorage ?? const TokenStorage(),
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {
                Headers.contentTypeHeader: Headers.jsonContentType,
              },
            ),
          ) {
    _setupInterceptors();
  }

  final Dio dio;
  final TokenStorage _tokenStorage;

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint('[API] ${options.method} ${options.uri}');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[API] ${response.statusCode} ${response.requestOptions.uri}',
            );
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            await _handleUnauthorized();
          } else if (statusCode == 403) {
            AppNavigator.showForbiddenMessage();
          }

          final apiException = _toApiException(error);

          if (kDebugMode) {
            debugPrint(
              '[API] ERROR ${error.response?.statusCode} '
              '${error.requestOptions.uri}: ${error.message}',
            );
          }

          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: apiException,
              message: apiException.message,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleUnauthorized() async {
    try {
      await _tokenStorage.clearToken();
    } catch (error) {
      debugPrint('Không thể xóa token hết hạn: $error');
    }

    debugPrint('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại');
    AppNavigator.goToLoginAndClearStack();
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request(
      () =>
          dio.get<T>(path, queryParameters: queryParameters, options: options),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request(
      () => dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request(
      () => dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _request(
      () => dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
    );
  }

  Future<Response<T>> _request<T>(
    Future<Response<T>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      final apiException = error.error is ApiException
          ? error.error! as ApiException
          : _toApiException(error);
      throw apiException;
    }
  }

  ApiException _toApiException(DioException error) {
    final statusCode = error.response?.statusCode;

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException('Không kết nối được máy chủ', statusCode: statusCode);
    }

    if (statusCode == 401) {
      return ApiException('Phiên đăng nhập đã hết hạn', statusCode: statusCode);
    }

    if (statusCode == 403) {
      return ApiException(
        'Bạn không có quyền thực hiện thao tác này',
        statusCode: statusCode,
      );
    }

    if (statusCode == 400 || statusCode == 422) {
      return ApiException('Dữ liệu không hợp lệ', statusCode: statusCode);
    }

    return ApiException('Đã có lỗi xảy ra', statusCode: statusCode);
  }
}
