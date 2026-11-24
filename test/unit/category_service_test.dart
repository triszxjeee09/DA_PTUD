import 'package:an_tam_pharma/core/database/local_json_cache.dart';
import 'package:an_tam_pharma/core/errors/api_exception.dart';
import 'package:an_tam_pharma/core/network/dio_client.dart';
import 'package:an_tam_pharma/features/category/data/services/category_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses cached categories after a connection failure', () async {
    final cache = _MemoryJsonCache();
    final online = CategoryService(
      dioClient: _FakeDioClient(responseData: _categoryResponse),
      localCache: cache,
    );
    await online.getCategories();

    final offline = CategoryService(
      dioClient: _FakeDioClient(
        apiException: const ApiException('Không thể kết nối đến máy chủ'),
      ),
      localCache: cache,
    );
    final categories = await offline.getCategories();

    expect(categories.map((category) => category.name), ['Thuốc không kê đơn']);
  });

  test('does not mask authorization failures with cached categories', () async {
    final cache = _MemoryJsonCache();
    await CategoryService(
      dioClient: _FakeDioClient(responseData: _categoryResponse),
      localCache: cache,
    ).getCategories();

    await expectLater(
      CategoryService(
        dioClient: _FakeDioClient(
          apiException: const ApiException(
            'Vui lòng đăng nhập',
            statusCode: 401,
          ),
        ),
        localCache: cache,
      ).getCategories(),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}

class _FakeDioClient extends DioClient {
  _FakeDioClient({this.responseData, this.apiException}) : super(dio: Dio());

  final Object? responseData;
  final ApiException? apiException;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (apiException != null) throw apiException!;
    return Response<T>(
      data: responseData as T?,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

class _MemoryJsonCache implements JsonCache {
  final _values = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, Map<String, dynamic> value) async {
    _values[key] = value;
  }
}

const _categoryResponse = {
  'status': 200,
  'message': 'Thành công',
  'data': [
    {
      'id': 'category-001',
      'name': 'Thuốc không kê đơn',
      'slug': 'thuoc-khong-ke-don',
      'isActive': true,
    },
  ],
};
