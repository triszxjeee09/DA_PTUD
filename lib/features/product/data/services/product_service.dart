import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/product_model.dart';

class ProductService {
  ProductService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<PageResponse<ProductModel>> getProducts({
    String? keyword,
    String? categoryId,
    String? brandId,
    double? minPrice,
    double? maxPrice,
    bool? requiresPrescription,
    bool? isFeatured,
    int page = 0,
    int size = 10,
    String sortBy = 'createdAt',
    String sortDirection = 'desc',
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
      if (brandId != null && brandId.isNotEmpty) 'brandId': brandId,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (requiresPrescription != null)
        'requiresPrescription': requiresPrescription,
      if (isFeatured != null) 'isFeatured': isFeatured,
    };

    try {
      final response = await _dioClient.get<dynamic>(
        ApiConstants.products,
        queryParameters: queryParameters,
      );
      final apiResponse = _parseApiResponse<PageResponse<ProductModel>>(
        response.data,
        (json) => PageResponse<ProductModel>.fromJson(
          _asJsonObject(json),
          (item) => ProductModel.fromJson(_asJsonObject(item)),
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

  Future<ProductModel> getProductById(String id) {
    return _getProduct('${ApiConstants.products}/$id');
  }

  Future<ProductModel> getProductBySlug(String slug) {
    return _getProduct('${ApiConstants.products}/slug/$slug');
  }

  Future<ProductModel> _getProduct(String path) async {
    try {
      final response = await _dioClient.get<dynamic>(path);
      final apiResponse = _parseApiResponse<ProductModel>(
        response.data,
        (json) => ProductModel.fromJson(_asJsonObject(json)),
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
}
