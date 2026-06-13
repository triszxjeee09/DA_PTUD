import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/config/google_auth_config.dart';

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.message, {this.canceled = false});

  final String message;
  final bool canceled;

  @override
  String toString() => message;
}

class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn, Duration? timeout})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
      _timeout = timeout ?? const Duration(seconds: 45);

  static const List<String> _scopes = ['email', 'profile'];
  static const String _configurationErrorMessage = '''
Cấu hình Google Sign-In chưa chính xác. Vui lòng kiểm tra applicationId Android, SHA-1 debug/release, OAuth Android Client cùng Google Cloud project với Web Client, Web Client ID đang dùng làm serverClientId, backend xác minh đúng Web Client ID, chờ Google Cloud cập nhật nếu vừa tạo, sau đó chạy flutter clean, flutter pub get, gỡ app khỏi emulator và cài lại. Không thay Web Client ID bằng Android Client ID.''';

  final GoogleSignIn _googleSignIn;
  final Duration _timeout;

  bool _initialized = false;
  Future<void>? _initializeFuture;
  StreamSubscription<GoogleSignInAuthenticationEvent>?
  _authenticationEventsSubscription;
  Completer<GoogleSignInAccount>? _signInCompleter;

  Future<void> initialize() {
    if (_initialized) {
      return Future<void>.value();
    }

    return _initializeFuture ??= _initializeGoogleSignIn();
  }

  Future<String?> signInAndGetIdToken() async {
    try {
      await initialize();

      if (!_googleSignIn.supportsAuthenticate()) {
        throw const GoogleAuthException(
          'Thiết bị hiện tại chưa hỗ trợ đăng nhập Google trong ứng dụng.',
        );
      }

      debugPrint('Bắt đầu đăng nhập Google');

      final account = await _authenticateAndWaitForEvent();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.trim().isEmpty) {
        throw const GoogleAuthException(
          'Không lấy được Google ID Token. Vui lòng kiểm tra Web Client ID.',
        );
      }

      debugPrint('Thành công lấy được Google ID Token');
      return idToken;
    } on GoogleSignInException catch (error) {
      throw _toGoogleAuthException(error);
    } on GoogleAuthException {
      rethrow;
    } on TimeoutException {
      throw const GoogleAuthException(
        'Đăng nhập Google quá thời gian chờ. Vui lòng thử lại.',
      );
    } catch (_) {
      throw const GoogleAuthException('Đăng nhập Google không thành công');
    }
  }

  Future<void> signOut() async {
    await initialize();

    try {
      await _googleSignIn.signOut();
    } on GoogleSignInException catch (error) {
      debugPrint('Mã lỗi GoogleSignInException: ${error.code.name}');
    }
  }

  Future<void> dispose() async {
    await _authenticationEventsSubscription?.cancel();
    _authenticationEventsSubscription = null;
    _signInCompleter = null;
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: GoogleAuthConfig.serverClientId,
      );
      _authenticationEventsSubscription ??= _googleSignIn.authenticationEvents
          .listen(
            _handleAuthenticationEvent,
            onError: _handleAuthenticationError,
          );
      _initialized = true;
    } catch (_) {
      _initializeFuture = null;
      rethrow;
    }
  }

  Future<GoogleSignInAccount> _authenticateAndWaitForEvent() {
    final existingCompleter = _signInCompleter;
    if (existingCompleter != null && !existingCompleter.isCompleted) {
      return existingCompleter.future.timeout(_timeout);
    }

    final completer = Completer<GoogleSignInAccount>();
    _signInCompleter = completer;

    unawaited(_runAuthenticate(completer));

    return completer.future.timeout(_timeout).whenComplete(() {
      if (identical(_signInCompleter, completer)) {
        _signInCompleter = null;
      }
    });
  }

  Future<void> _runAuthenticate(
    Completer<GoogleSignInAccount> completer,
  ) async {
    try {
      await _googleSignIn.authenticate(scopeHint: _scopes);
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    }
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn():
        final completer = _signInCompleter;
        if (completer != null && !completer.isCompleted) {
          completer.complete(event.user);
        }
      case GoogleSignInAuthenticationEventSignOut():
        break;
    }
  }

  void _handleAuthenticationError(Object error, StackTrace stackTrace) {
    final completer = _signInCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(error, stackTrace);
    }
  }

  GoogleAuthException _toGoogleAuthException(GoogleSignInException error) {
    debugPrint('Mã lỗi GoogleSignInException: ${error.code.name}');

    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
      case GoogleSignInExceptionCode.interrupted:
        debugPrint('Người dùng hủy đăng nhập Google');
        return const GoogleAuthException(
          'Bạn đã hủy đăng nhập Google',
          canceled: true,
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
        return const GoogleAuthException(_configurationErrorMessage);
      case GoogleSignInExceptionCode.providerConfigurationError:
        return const GoogleAuthException(_configurationErrorMessage);
      case GoogleSignInExceptionCode.uiUnavailable:
        return const GoogleAuthException(
          'Không thể mở giao diện đăng nhập Google',
        );
      case GoogleSignInExceptionCode.userMismatch:
        return const GoogleAuthException(
          'Tài khoản Google không khớp. Vui lòng chọn lại tài khoản.',
        );
      case GoogleSignInExceptionCode.unknownError:
        return const GoogleAuthException('Đăng nhập Google không thành công');
    }
  }
}
