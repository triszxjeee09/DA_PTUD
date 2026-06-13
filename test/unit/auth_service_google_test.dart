import 'package:dio/dio.dart';
import 'package:doan/core/network/dio_client.dart';
import 'package:doan/features/auth/data/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService.loginWithGoogle', () {
    test('gui idToken len backend va parse AuthResponse thanh cong', () async {
      final dioClient = _FakeDioClient(
        responseData: {
          'status': 200,
          'message': 'Dang nhap Google thanh cong',
          'data': {
            'accessToken': 'access-token-001',
            'refreshToken': 'refresh-token-001',
            'tokenType': 'Bearer',
            'user': {
              'id': 'user-001',
              'fullName': 'Nguyen Van A',
              'email': 'user@example.com',
              'phone': null,
              'avatarUrl': 'https://example.com/avatar.png',
              'status': 'ACTIVE',
              'roles': ['CUSTOMER'],
            },
          },
        },
      );
      final service = AuthService(dioClient: dioClient);

      final result = await service.loginWithGoogle('google-id-token-001');

      expect(dioClient.requestedPath, '/auth/google');
      expect(dioClient.requestedData, {'idToken': 'google-id-token-001'});
      expect(dioClient.skipAuth, isTrue);
      expect(result.accessToken, 'access-token-001');
      expect(result.refreshToken, 'refresh-token-001');
      expect(result.tokenType, 'Bearer');
      expect(result.user.id, 'user-001');
      expect(result.user.email, 'user@example.com');
      expect(result.user.isCustomer, isTrue);
    });
  });
}

class _FakeDioClient extends DioClient {
  _FakeDioClient({required this.responseData}) : super(dio: Dio());

  final Object? responseData;
  String? requestedPath;
  Object? requestedData;
  bool? skipAuth;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    requestedPath = path;
    requestedData = data;
    final extra = options?.extra;
    skipAuth = extra != null && extra['skipAuth'] == true;

    return Response<T>(
      data: responseData as T?,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}
