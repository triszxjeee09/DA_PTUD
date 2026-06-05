import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../../../voucher/data/models/voucher_model.dart';
import '../models/admin_voucher_request_model.dart';

class AdminVoucherService {
  AdminVoucherService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<PageResponse<VoucherModel>> getVouchers({
    String? keyword,
    int page = 0,
    int size = 20,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': 'createdAt',
      'sortDirection': 'desc',
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
    };

    try {
      final response = await _dioClient.get<dynamic>(
        ApiConstants.adminVouchers,
        queryParameters: queryParameters,
      );
      final apiResponse = _parseApiResponse<PageResponse<VoucherModel>>(
        response.data,
        (json) => _readVoucherPage(json, page: page, size: size),
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

  Future<VoucherModel> getVoucherDetail(String id) async {
    try {
      final response = await _dioClient.get<dynamic>(
        '${ApiConstants.adminVouchers}/$id',
      );
      final apiResponse = _parseApiResponse<VoucherModel>(
        response.data,
        (json) => VoucherModel.fromJson(_asJsonObject(json)),
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

  Future<VoucherModel> createVoucher(AdminVoucherRequestModel request) async {
    try {
      final response = await _dioClient.post<dynamic>(
        ApiConstants.adminVouchers,
        data: request.toJson(),
      );
      final apiResponse = _parseApiResponse<VoucherModel>(
        response.data,
        (json) => VoucherModel.fromJson(_asJsonObject(json)),
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

  Future<VoucherModel> updateVoucher(
    String id,
    AdminVoucherRequestModel request,
  ) async {
    try {
      final response = await _dioClient.put<dynamic>(
        '${ApiConstants.adminVouchers}/$id',
        data: request.toJson(),
      );
      final apiResponse = _parseApiResponse<VoucherModel>(
        response.data,
        (json) => VoucherModel.fromJson(_asJsonObject(json)),
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

  Future<void> deleteVoucher(String id) async {
    try {
      final response = await _dioClient.delete<dynamic>(
        '${ApiConstants.adminVouchers}/$id',
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

  PageResponse<VoucherModel> _readVoucherPage(
    Object? data, {
    required int page,
    required int size,
  }) {
    if (data is Map) {
      final json = _asJsonObject(data);
      if (json.containsKey('content')) {
        return PageResponse<VoucherModel>.fromJson(
          json,
          (item) => VoucherModel.fromJson(_asJsonObject(item)),
        );
      }
    }

    final content = _asList(
      data,
    ).map((item) => VoucherModel.fromJson(_asJsonObject(item))).toList();
    return PageResponse<VoucherModel>(
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
