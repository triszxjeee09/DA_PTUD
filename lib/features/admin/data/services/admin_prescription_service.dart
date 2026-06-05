import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../../../prescription/data/models/prescription_model.dart';

class AdminPrescriptionService {
  AdminPrescriptionService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';
  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';

  final DioClient _dioClient;

  Future<PageResponse<PrescriptionModel>> getPrescriptions({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };

    try {
      final response = await _dioClient.get<dynamic>(
        ApiConstants.adminPrescriptions,
        queryParameters: queryParameters,
      );
      final apiResponse = _parseApiResponse<PageResponse<PrescriptionModel>>(
        response.data,
        (json) => PageResponse<PrescriptionModel>.fromJson(
          _asJsonObject(json),
          (item) => PrescriptionModel.fromJson(_asJsonObject(item)),
        ),
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

  Future<void> reviewPrescription({
    required String id,
    required String status,
    String? pharmacistNote,
  }) async {
    try {
      final response = await _dioClient.put<dynamic>(
        '${ApiConstants.adminPrescriptions}/$id/review',
        data: {
          'status': status,
          if (pharmacistNote != null && pharmacistNote.trim().isNotEmpty)
            'pharmacistNote': pharmacistNote.trim(),
        },
      );
      _throwIfError(response.data);
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

  void _throwIfError(Object? data) {
    final response = ApiResponse<void>.fromJson(_asJsonObject(data), (_) {});
    if (response.status >= 400) {
      throw ApiException(
        _messageOrDefault(response.message),
        statusCode: response.status,
      );
    }
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
    return message is String && message.trim().isNotEmpty ? message : null;
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
