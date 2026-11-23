import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/api_constants.dart';
import '../../errors/api_exception.dart';
import '../../network/dio_client.dart';
import '../../utils/upload_file.dart';
import '../models/file_upload_response_model.dart';

class FileUploadService {
  FileUploadService({DioClient? dioClient, Dio? dio})
    : _dioClient = dioClient ?? DioClient(dio: dio);

  static const String _connectionErrorMessage = 'Không thể kết nối đến máy chủ';
  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final DioClient _dioClient;

  Future<FileUploadResponseModel> uploadImage({
    required XFile file,
    required String folder,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await UploadFile.toMultipart(file),
        'folder': folder,
      });

      final response = await _dioClient.dio.post<dynamic>(
        ApiConstants.uploadFile,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );

      return FileUploadResponseModel.fromJson(_readUploadData(response.data));
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      throw _toApiException(error);
    } catch (_) {
      throw const ApiException(_defaultErrorMessage);
    }
  }

  ApiException _toApiException(DioException error) {
    final apiException = error.error;
    final message = _extractBackendMessage(error.response?.data);

    if (apiException is ApiException) {
      return ApiException(
        message ?? _cleanApiMessage(apiException.message),
        statusCode: apiException.statusCode,
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return ApiException(
        message ?? _connectionErrorMessage,
        statusCode: error.response?.statusCode,
      );
    }

    return ApiException(
      message ?? _defaultErrorMessage,
      statusCode: error.response?.statusCode,
    );
  }

  Map<String, dynamic> _readUploadData(Object? data) {
    final json = _asJsonObject(data);
    final status = _readStatus(json['status']);
    if (status != null && status >= 400) {
      throw ApiException(
        _extractBackendMessage(json) ?? _defaultErrorMessage,
        statusCode: status,
      );
    }

    final responseData = json['data'];
    if (responseData is Map) {
      return _asJsonObject(responseData);
    }

    return json;
  }

  String? _extractBackendMessage(Object? data) {
    final json = data is Map ? _asJsonObject(data) : null;
    final message = json?['message'];

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    return null;
  }

  int? _readStatus(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim());
    }

    return null;
  }

  String _cleanApiMessage(String message) {
    final value = message.trim();
    if (value.isEmpty || value.contains('Ã') || value.contains('Ä')) {
      return _defaultErrorMessage;
    }

    return value;
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
