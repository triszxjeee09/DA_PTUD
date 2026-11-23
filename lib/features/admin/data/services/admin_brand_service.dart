import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../brand/data/models/brand_model.dart';
import '../models/admin_brand_request_model.dart';

class AdminBrandService {
  AdminBrandService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<List<BrandModel>> getBrands() async {
    try {
      final response = await _dioClient.get<dynamic>(ApiConstants.brandAdmin);
      final apiResponse = _parseApiResponse<List<BrandModel>>(
        response.data,
        (json) => _readBrandList(json),
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

  Future<BrandModel> getBrandDetail(String id) async {
    try {
      final response = await _dioClient.get<dynamic>(
        '${ApiConstants.brands}/$id',
      );
      final apiResponse = _parseApiResponse<BrandModel>(
        response.data,
        (json) => BrandModel.fromJson(_asJsonObject(json)),
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

  Future<BrandModel> createBrand(AdminBrandRequestModel request) async {
    try {
      final response = await _dioClient.post<dynamic>(
        ApiConstants.brands,
        data: request.toJson(),
      );
      final apiResponse = _parseApiResponse<BrandModel>(
        response.data,
        (json) => BrandModel.fromJson(_asJsonObject(json)),
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

  Future<BrandModel> updateBrand(
    String id,
    AdminBrandRequestModel request,
  ) async {
    try {
      final response = await _dioClient.put<dynamic>(
        '${ApiConstants.brands}/$id',
        data: request.toJson(),
      );
      final apiResponse = _parseApiResponse<BrandModel>(
        response.data,
        (json) => BrandModel.fromJson(_asJsonObject(json)),
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

  Future<void> deleteBrand(String id) async {
    try {
      final response = await _dioClient.delete<dynamic>(
        '${ApiConstants.brands}/$id',
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

  List<BrandModel> _readBrandList(Object? data) {
    final list = data is Map ? _asJsonObject(data)['content'] : data;
    return _asList(
      list,
    ).map((item) => BrandModel.fromJson(_asJsonObject(item))).toList();
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
