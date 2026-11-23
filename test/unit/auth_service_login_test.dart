import 'dart:convert';
import 'dart:typed_data';

import 'package:an_tam_pharma/core/errors/api_exception.dart';
import 'package:an_tam_pharma/core/network/dio_client.dart';
import 'package:an_tam_pharma/core/storage/token_storage.dart';
import 'package:an_tam_pharma/features/auth/data/models/login_request_model.dart';
import 'package:an_tam_pharma/features/auth/data/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'invalid credentials keep the login error and ignore stale tokens',
    () async {
      final adapter = _UnauthorizedAdapter();
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://localhost:8082/api/v1',
          headers: const {'Authorization': 'Bearer stale-token'},
        ),
      )..httpClientAdapter = adapter;
      final tokenStorage = _SpyTokenStorage();
      final service = AuthService(
        dioClient: DioClient(dio: dio, tokenStorage: tokenStorage),
      );

      await expectLater(
        service.login(
          const LoginRequestModel(
            username: 'ductri@antam.local',
            password: 'wrong-password',
          ),
        ),
        throwsA(
          isA<ApiException>()
              .having(
                (error) => error.message,
                'message',
                'Email/tài khoản hoặc mật khẩu không đúng',
              )
              .having((error) => error.statusCode, 'statusCode', 401),
        ),
      );

      expect(adapter.requestOptions?.extra['skipAuth'], isTrue);
      expect(
        adapter.requestHeaders?.toLowerCase().contains('authorization'),
        isFalse,
      );
      expect(tokenStorage.readCount, 0);
      expect(tokenStorage.clearCount, 0);
    },
  );
}

class _UnauthorizedAdapter implements HttpClientAdapter {
  RequestOptions? requestOptions;
  String? requestHeaders;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestOptions = options;
    requestHeaders = options.headers.toString();
    return ResponseBody.fromString(
      jsonEncode({
        'status': 401,
        'message': 'Email/tài khoản hoặc mật khẩu không đúng',
        'data': null,
      }),
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _SpyTokenStorage extends TokenStorage {
  int readCount = 0;
  int clearCount = 0;

  @override
  Future<String?> getToken() async {
    readCount++;
    return 'expired-token';
  }

  @override
  Future<void> clearToken() async {
    clearCount++;
  }
}
