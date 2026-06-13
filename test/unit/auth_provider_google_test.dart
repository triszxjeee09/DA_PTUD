import 'dart:async';

import 'package:doan/core/errors/api_exception.dart';
import 'package:doan/core/storage/token_storage.dart';
import 'package:doan/features/auth/data/models/auth_response_model.dart';
import 'package:doan/features/auth/data/models/user_model.dart';
import 'package:doan/features/auth/data/services/auth_service.dart';
import 'package:doan/features/auth/data/services/google_auth_service.dart';
import 'package:doan/features/auth/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthProvider.loginWithGoogle', () {
    test(
      'lưu token, cập nhật user và authenticated khi backend thành công',
      () async {
        final googleService = _FakeGoogleAuthService(
          idToken: 'google-id-token',
        );
        final authService = _FakeAuthService(
          response: _authResponse(
            accessToken: 'access-token',
            refreshToken: 'refresh-token',
            user: const UserModel(id: 'customer-1', roles: ['CUSTOMER']),
          ),
        );
        final tokenStorage = _FakeTokenStorage();
        var deviceTokenSaved = false;
        final provider = AuthProvider(
          authService: authService,
          googleAuthService: googleService,
          tokenStorage: tokenStorage,
          onAuthenticated: () async {
            deviceTokenSaved = true;
          },
        );

        final success = await provider.loginWithGoogle();

        expect(success, isTrue);
        expect(googleService.signInCallCount, 1);
        expect(authService.idTokens, ['google-id-token']);
        expect(tokenStorage.accessToken, 'access-token');
        expect(tokenStorage.refreshToken, 'refresh-token');
        expect(provider.currentUser?.id, 'customer-1');
        expect(provider.isAuthenticated, isTrue);
        expect(provider.isGoogleLoading, isFalse);
        expect(provider.googleLoginError, isNull);
        expect(deviceTokenSaved, isTrue);
      },
    );

    test('canceled không tạo error và luôn reset loading', () async {
      final provider = AuthProvider(
        authService: _FakeAuthService(),
        googleAuthService: _FakeGoogleAuthService(
          exception: const GoogleAuthException('Đã hủy', canceled: true),
        ),
        tokenStorage: _FakeTokenStorage(),
      );

      final success = await provider.loginWithGoogle();

      expect(success, isFalse);
      expect(provider.googleLoginError, isNull);
      expect(provider.isGoogleLoading, isFalse);
    });

    test('backend 401 trả false, set message và reset loading', () async {
      final googleService = _FakeGoogleAuthService(idToken: 'google-id-token');
      final authService = _FakeAuthService(
        exception: const ApiException(
          'Tài khoản Google không hợp lệ hoặc đã hết hạn',
          statusCode: 401,
        ),
      );
      final provider = AuthProvider(
        authService: authService,
        googleAuthService: googleService,
        tokenStorage: _FakeTokenStorage(),
      );

      final success = await provider.loginWithGoogle();

      expect(success, isFalse);
      expect(
        provider.googleLoginError,
        'Tài khoản Google không hợp lệ hoặc đã hết hạn',
      );
      expect(provider.isAuthenticated, isFalse);
      expect(provider.isGoogleLoading, isFalse);
      expect(googleService.signOutCallCount, 1);
    });

    test('finally reset isGoogleLoading khi backend lỗi bất ngờ', () async {
      final provider = AuthProvider(
        authService: _FakeAuthService(exception: StateError('boom')),
        googleAuthService: _FakeGoogleAuthService(idToken: 'google-id-token'),
        tokenStorage: _FakeTokenStorage(),
      );

      final success = await provider.loginWithGoogle();

      expect(success, isFalse);
      expect(provider.isGoogleLoading, isFalse);
      expect(provider.googleLoginError, 'Đã có lỗi xảy ra, vui lòng thử lại');
    });

    test('không chạy request trùng khi đang loading', () async {
      final googleCompleter = Completer<String?>();
      final googleService = _FakeGoogleAuthService(completer: googleCompleter);
      final authService = _FakeAuthService(
        response: _authResponse(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          user: const UserModel(id: 'customer-1', roles: ['CUSTOMER']),
        ),
      );
      final provider = AuthProvider(
        authService: authService,
        googleAuthService: googleService,
        tokenStorage: _FakeTokenStorage(),
      );

      final firstLogin = provider.loginWithGoogle();
      await Future<void>.delayed(Duration.zero);

      final secondLogin = await provider.loginWithGoogle();
      googleCompleter.complete('google-id-token');
      final firstResult = await firstLogin;

      expect(secondLogin, isFalse);
      expect(firstResult, isTrue);
      expect(googleService.signInCallCount, 1);
      expect(authService.idTokens, ['google-id-token']);
      expect(provider.isGoogleLoading, isFalse);
    });
  });
}

AuthResponseModel _authResponse({
  required String accessToken,
  required String refreshToken,
  required UserModel user,
}) {
  return AuthResponseModel(
    accessToken: accessToken,
    refreshToken: refreshToken,
    tokenType: 'Bearer',
    expiresIn: 3600,
    user: user,
  );
}

class _FakeGoogleAuthService extends GoogleAuthService {
  _FakeGoogleAuthService({this.idToken, this.exception, this.completer});

  final String? idToken;
  final Object? exception;
  final Completer<String?>? completer;
  int signInCallCount = 0;
  int signOutCallCount = 0;

  @override
  Future<String?> signInAndGetIdToken() async {
    signInCallCount++;
    final error = exception;
    if (error != null) {
      throw error;
    }

    final pending = completer;
    if (pending != null) {
      return pending.future;
    }

    return idToken;
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeAuthService extends AuthService {
  _FakeAuthService({this.response, this.exception});

  final AuthResponseModel? response;
  final Object? exception;
  final List<String> idTokens = [];

  @override
  Future<AuthResponseModel> loginWithGoogle(String idToken) async {
    idTokens.add(idToken);
    final error = exception;
    if (error != null) {
      throw error;
    }

    return response ??
        _authResponse(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          user: const UserModel(id: 'user-1', roles: ['CUSTOMER']),
        );
  }
}

class _FakeTokenStorage extends TokenStorage {
  String? accessToken;
  String? refreshToken;
  var clearCallCount = 0;

  @override
  Future<void> saveToken(String token) async {
    accessToken = token;
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    refreshToken = token;
  }

  @override
  Future<String?> getToken() async => accessToken;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> clearToken() async {
    clearCallCount++;
    accessToken = null;
    refreshToken = null;
  }
}
