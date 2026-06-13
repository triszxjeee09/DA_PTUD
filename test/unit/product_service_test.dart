import 'package:dio/dio.dart';
import 'package:doan/core/errors/api_exception.dart';
import 'package:doan/core/network/dio_client.dart';
import 'package:doan/features/product/data/services/product_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PHAN 1 - PASS: Kiem thu ProductService thay cho Postman', () {
    test('getProducts parse danh sach san pham thanh cong', () async {
      final dioClient = _FakeDioClient(
        responseData: _apiResponse(
          data: {
            'content': [_productJson()],
            'page': 0,
            'size': 10,
            'totalElements': 1,
            'totalPages': 1,
            'last': true,
          },
        ),
      );
      final service = ProductService(dioClient: dioClient);

      final result = await service.getProducts();

      expect(dioClient.requestedPath, '/products');
      expect(result.content, hasLength(1));
      expect(result.content.first.id, 'product-001');
      expect(result.content.first.name, 'Panadol Extra');
      expect(result.content.first.price, 35000);
      expect(result.totalElements, 1);
      expect(result.last, isTrue);
    });

    test('getProductById parse chi tiet san pham thanh cong', () async {
      final dioClient = _FakeDioClient(
        responseData: _apiResponse(data: _productJson()),
      );
      final service = ProductService(dioClient: dioClient);

      final result = await service.getProductById('product-001');

      expect(dioClient.requestedPath, '/products/product-001');
      expect(result.id, 'product-001');
      expect(result.name, 'Panadol Extra');
      expect(result.unit, 'Hộp');
      expect(result.isActive, isTrue);
      expect(result.requiresPrescription, isFalse);
    });

    test('getProductById nem ApiException khi backend tra loi', () async {
      final dioClient = _FakeDioClient(
        responseData: _apiResponse(
          status: 404,
          message: 'Không tìm thấy sản phẩm',
          data: null,
        ),
      );
      final service = ProductService(dioClient: dioClient);

      expect(
        () => service.getProductById('not-found'),
        throwsA(
          isA<ApiException>()
              .having(
                (error) => error.message,
                'message',
                'Không tìm thấy sản phẩm',
              )
              .having((error) => error.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('PHAN 2 - Kiem thu ProductService bo sung', () {
    test('API tra Panadol Extra thi parse dung ten san pham', () async {
      final dioClient = _FakeDioClient(
        responseData: _apiResponse(data: _productJson()),
      );
      final service = ProductService(dioClient: dioClient);

      final result = await service.getProductById('product-001');

      expect(result.name, 'Panadol Extra');
    });

    test('API tra 1 san pham thi danh sach co 1 phan tu', () async {
      final dioClient = _FakeDioClient(
        responseData: _apiResponse(
          data: {
            'content': [_productJson()],
            'page': 0,
            'size': 10,
            'totalElements': 1,
            'totalPages': 1,
            'last': true,
          },
        ),
      );
      final service = ProductService(dioClient: dioClient);

      final result = await service.getProducts();

      expect(result.content, hasLength(1));
    });
  });
}

class _FakeDioClient extends DioClient {
  _FakeDioClient({required this.responseData}) : super(dio: Dio());

  final Object? responseData;
  String? requestedPath;
  Map<String, dynamic>? requestedQueryParameters;

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requestedPath = path;
    requestedQueryParameters = queryParameters;

    return Response<T>(
      data: responseData as T?,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

Map<String, dynamic> _apiResponse({
  int status = 200,
  String message = 'Thành công',
  Object? data,
}) {
  return {
    'status': status,
    'message': message,
    'data': data,
    'timestamp': '2026-06-09T00:00:00',
  };
}

Map<String, dynamic> _productJson() {
  return {
    'id': 'product-001',
    'categoryId': 'category-001',
    'categoryName': 'Thuốc giảm đau',
    'brandId': 'brand-001',
    'brandName': 'GSK',
    'name': 'Panadol Extra',
    'slug': 'panadol-extra',
    'sku': 'PANADOL-EXTRA-001',
    'shortDescription': 'Thuốc giảm đau, hạ sốt',
    'description': 'Sản phẩm dùng để giảm đau và hạ sốt.',
    'unit': 'Hộp',
    'price': 35000,
    'originalPrice': 40000,
    'requiresPrescription': false,
    'isActive': true,
    'isFeatured': true,
    'thumbnailUrl': 'https://example.com/panadol.png',
    'images': [
      {
        'id': 'image-001',
        'imageUrl': 'https://example.com/panadol.png',
        'isThumbnail': true,
        'sortOrder': 1,
      },
    ],
    'createdAt': '2026-06-09T00:00:00',
    'updatedAt': '2026-06-09T00:00:00',
  };
}
