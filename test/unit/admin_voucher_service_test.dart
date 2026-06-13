import 'package:dio/dio.dart';
import 'package:doan/core/errors/api_exception.dart';
import 'package:doan/core/network/dio_client.dart';
import 'package:doan/features/admin/data/models/admin_voucher_request_model.dart';
import 'package:doan/features/admin/data/services/admin_voucher_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminVoucherService', () {
    test('getVouchers gọi endpoint admin và parse page', () async {
      final dioClient = _FakeDioClient(
        responseData: _apiResponse(
          data: {
            'content': [_voucherJson()],
            'page': 1,
            'size': 5,
            'totalElements': 6,
            'totalPages': 2,
            'last': true,
          },
        ),
      );
      final service = AdminVoucherService(dioClient: dioClient);

      final result = await service.getVouchers(
        page: 1,
        size: 5,
        keyword: 'sale',
        isActive: false,
      );

      expect(dioClient.requestedMethod, 'GET');
      expect(dioClient.requestedPath, '/admin/vouchers');
      expect(dioClient.requestedQueryParameters, {
        'page': 1,
        'size': 5,
        'keyword': 'sale',
        'isActive': false,
      });
      expect(result.content, hasLength(1));
      expect(result.content.first.code, 'SALE10');
      expect(result.page, 1);
      expect(result.totalElements, 6);
    });

    test('getVoucherById dùng resource endpoint /vouchers/{id}', () async {
      final dioClient = _FakeDioClient(responseData: _voucherJson());
      final service = AdminVoucherService(dioClient: dioClient);

      final result = await service.getVoucherById('voucher-001');

      expect(dioClient.requestedMethod, 'GET');
      expect(dioClient.requestedPath, '/admin/vouchers/voucher-001');
      expect(result.id, 'voucher-001');
      expect(result.discountValue, 10);
    });

    test('createVoucher gửi payload lên /vouchers', () async {
      final dioClient = _FakeDioClient(
        responseData: _apiResponse(data: _voucherJson()),
      );
      final service = AdminVoucherService(dioClient: dioClient);

      final result = await service.createVoucher(_voucherRequest());

      expect(dioClient.requestedMethod, 'POST');
      expect(dioClient.requestedPath, '/admin/vouchers');
      expect(dioClient.requestedData, _voucherRequest().toJson());
      expect(result.code, 'SALE10');
    });

    test('updateVoucher gửi payload lên /vouchers/{id}', () async {
      final dioClient = _FakeDioClient(
        responseData: _apiResponse(data: _voucherJson(name: 'Sale cập nhật')),
      );
      final service = AdminVoucherService(dioClient: dioClient);

      final result = await service.updateVoucher(
        'voucher-001',
        _voucherRequest(name: 'Sale cập nhật'),
      );

      expect(dioClient.requestedMethod, 'PUT');
      expect(dioClient.requestedPath, '/admin/vouchers/voucher-001');
      expect(
        dioClient.requestedData,
        _voucherRequest(name: 'Sale cập nhật').toJson(),
      );
      expect(result.name, 'Sale cập nhật');
    });

    test('deleteVoucher gọi /vouchers/{id}', () async {
      final dioClient = _FakeDioClient(responseData: null, statusCode: 204);
      final service = AdminVoucherService(dioClient: dioClient);

      await service.deleteVoucher('voucher-001');

      expect(dioClient.requestedMethod, 'DELETE');
      expect(dioClient.requestedPath, '/admin/vouchers/voucher-001');
    });

    test('fallback sang endpoint cũ khi endpoint admin chưa hỗ trợ', () async {
      final dioClient = _FakeDioClient(
        responseData: _voucherJson(),
        primaryException: const ApiException('Không tìm thấy', statusCode: 404),
      );
      final service = AdminVoucherService(dioClient: dioClient);

      final result = await service.getVoucherById('voucher-001');

      expect(result.id, 'voucher-001');
      expect(dioClient.requestedPaths, [
        '/admin/vouchers/voucher-001',
        '/vouchers/voucher-001',
      ]);
    });

    test('chuẩn hóa lỗi trùng mã voucher', () async {
      final dioClient = _FakeDioClient(
        exception: const ApiException(
          'Voucher code already exists',
          statusCode: 409,
        ),
      );
      final service = AdminVoucherService(dioClient: dioClient);

      expect(
        () => service.createVoucher(_voucherRequest()),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            'Mã voucher đã tồn tại',
          ),
        ),
      );
    });
  });
}

class _FakeDioClient extends DioClient {
  _FakeDioClient({
    this.responseData,
    this.statusCode = 200,
    this.exception,
    this.primaryException,
  }) : super(dio: Dio());

  final Object? responseData;
  final int statusCode;
  final ApiException? exception;
  final ApiException? primaryException;
  String? requestedMethod;
  String? requestedPath;
  Object? requestedData;
  Map<String, dynamic>? requestedQueryParameters;
  final List<String> requestedPaths = [];

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requestedMethod = 'GET';
    requestedPath = path;
    requestedQueryParameters = queryParameters;
    requestedPaths.add(path);

    _throwIfNeeded();

    return _response<T>(path);
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requestedMethod = 'POST';
    requestedPath = path;
    requestedData = data;
    requestedQueryParameters = queryParameters;
    requestedPaths.add(path);

    _throwIfNeeded();

    return _response<T>(path);
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requestedMethod = 'PUT';
    requestedPath = path;
    requestedData = data;
    requestedQueryParameters = queryParameters;
    requestedPaths.add(path);

    _throwIfNeeded();

    return _response<T>(path);
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requestedMethod = 'DELETE';
    requestedPath = path;
    requestedData = data;
    requestedQueryParameters = queryParameters;
    requestedPaths.add(path);

    _throwIfNeeded();

    return _response<T>(path);
  }

  void _throwIfNeeded() {
    if (exception != null) {
      throw exception!;
    }

    if (primaryException != null && requestedPaths.length == 1) {
      throw primaryException!;
    }
  }

  Response<T> _response<T>(String path) {
    return Response<T>(
      data: responseData as T?,
      statusCode: statusCode,
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
    'timestamp': '2026-06-11T00:00:00',
  };
}

Map<String, dynamic> _voucherJson({String name = 'Sale tháng 6'}) {
  return {
    'id': 'voucher-001',
    'code': 'SALE10',
    'name': name,
    'description': 'Giảm 10%',
    'discountType': 'PERCENT',
    'discountTypeLabel': 'Giảm theo phần trăm',
    'discountValue': 10,
    'maxDiscountAmount': 50000,
    'minOrderAmount': 100000,
    'usageLimit': 100,
    'usedCount': 2,
    'startDate': '2026-06-01T00:00:00',
    'endDate': '2026-06-30T23:59:59',
    'isActive': true,
    'createdAt': '2026-06-01T00:00:00',
    'updatedAt': '2026-06-02T00:00:00',
  };
}

AdminVoucherRequestModel _voucherRequest({String name = 'Sale tháng 6'}) {
  return AdminVoucherRequestModel(
    code: 'SALE10',
    name: name,
    description: 'Giảm 10%',
    discountType: 'PERCENT',
    discountValue: 10,
    maxDiscountAmount: 50000,
    minOrderAmount: 100000,
    usageLimit: 100,
    startDate: '2026-06-01T00:00:00',
    endDate: '2026-06-30T23:59:59',
    isActive: true,
  );
}
