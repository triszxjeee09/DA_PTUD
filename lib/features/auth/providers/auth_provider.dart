import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/data/services/file_upload_service.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../account/data/models/update_profile_request_model.dart';
import '../../account/data/services/user_profile_service.dart';
import '../data/models/forgot_password_request_model.dart';
import '../data/models/auth_response_model.dart';
import '../data/models/login_request_model.dart';
import '../data/models/register_request_model.dart';
import '../data/models/reset_password_with_otp_request_model.dart';
import '../data/models/user_model.dart';
import '../data/models/verify_forgot_password_otp_request_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    UserProfileService? userProfileService,
    FileUploadService? fileUploadService,
    GoogleAuthService? googleAuthService,
    TokenStorage? tokenStorage,
    Future<void> Function()? onAuthenticated,
    Future<void> Function()? onBeforeLogout,
  }) : _onAuthenticated = onAuthenticated,
       _onBeforeLogout = onBeforeLogout,
       _authService = authService ?? AuthService(),
       _userProfileService = userProfileService ?? UserProfileService(),
       _fileUploadService = fileUploadService ?? FileUploadService(),
       _googleAuthService = googleAuthService ?? GoogleAuthService(),
       _tokenStorage = tokenStorage ?? const TokenStorage();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final AuthService _authService;
  final UserProfileService _userProfileService;
  final FileUploadService _fileUploadService;
  final GoogleAuthService _googleAuthService;
  final TokenStorage _tokenStorage;
  final Future<void> Function()? _onAuthenticated;
  final Future<void> Function()? _onBeforeLogout;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _isResettingPassword = false;
  bool _isLoadingProfile = false;
  bool _isUpdatingProfile = false;
  bool _isUploadingAvatar = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  String? _googleLoginError;
  String? _profileErrorMessage;
  String? _avatarErrorMessage;
  String? _forgotPasswordUsername;
  int? _otpExpiresInMinutes;
  bool _isOtpVerified = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isGoogleLoading => _isGoogleLoading;
  bool get isSigningInWithGoogle => _isGoogleLoading;
  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  bool get isResettingPassword => _isResettingPassword;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isUpdatingProfile => _isUpdatingProfile;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  String? get googleLoginError => _googleLoginError;
  String? get profileErrorMessage => _profileErrorMessage;
  String? get avatarErrorMessage => _avatarErrorMessage;
  String? get forgotPasswordUsername => _forgotPasswordUsername;
  int? get otpExpiresInMinutes => _otpExpiresInMinutes;
  bool get isOtpVerified => _isOtpVerified;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isPharmacist => _currentUser?.isPharmacist ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  String getHomeRouteForCurrentUser() {
    if (isAdmin) {
      return '/admin';
    }

    if (isPharmacist) {
      return '/pharmacist';
    }

    return '/main';
  }

  @override
  void dispose() {
    unawaited(_googleAuthService.dispose());
    super.dispose();
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);

    try {
      final response = await _authService.login(
        LoginRequestModel(username: username, password: password),
      );

      await _completeAuthentication(
        response,
        deviceTokenErrorMessage: 'Không thể lưu device token sau khi đăng nhập',
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);

    try {
      final response = await _authService.register(
        RegisterRequestModel(
          fullName: fullName,
          email: email,
          phone: phone,
          password: password,
          confirmPassword: confirmPassword,
        ),
      );

      await _completeAuthentication(
        response,
        deviceTokenErrorMessage: 'Không thể lưu device token sau khi đăng ký',
      );
      _errorMessage = null;
      return true;
    } catch (error) {
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    if (_isGoogleLoading) {
      return false;
    }

    _isGoogleLoading = true;
    _googleLoginError = null;
    notifyListeners();

    try {
      final idToken = await _googleAuthService.signInAndGetIdToken();
      if (idToken == null || idToken.trim().isEmpty) {
        _googleLoginError = 'Không lấy được thông tin đăng nhập Google';
        return false;
      }
      final response = await _authService.loginWithGoogle(idToken);
      if (response.accessToken.trim().isEmpty) {
        throw const ApiException('Máy chủ không trả access token');
      }

      await _completeGoogleAuthentication(
        response,
        deviceTokenErrorMessage:
            'Không thể lưu device token sau khi đăng nhập Google',
      );
      _errorMessage = null;
      _googleLoginError = null;
      return true;
    } on GoogleAuthException catch (error) {
      if (!error.canceled && error.message.trim().isNotEmpty) {
        _googleLoginError = error.message;
      }

      return false;
    } on ApiException catch (error) {
      _googleLoginError = error.message.trim().isNotEmpty
          ? error.message
          : _defaultErrorMessage;
      await _runAuthSideEffect(
        _googleAuthService.signOut,
        'Không thể đăng xuất Google sau khi backend từ chối đăng nhập',
      );
      return false;
    } catch (error) {
      _googleLoginError = _readErrorMessage(error);
      return false;
    } finally {
      _isGoogleLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    _setLoading(true);

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        _currentUser = null;
        _isAuthenticated = false;
        _errorMessage = null;
        return;
      }

      _currentUser = await _authService.getCurrentUser();
      _isAuthenticated = true;
      _errorMessage = null;
    } catch (error) {
      await _clearTokenSafely();
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> refreshCurrentUser() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      _isAuthenticated = true;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      notifyListeners();
      return false;
    }
  }

  Future<void> loadMyProfile() async {
    _setLoadingProfile(true);

    try {
      _currentUser = await _userProfileService.getMyProfile();
      _isAuthenticated = true;
      _profileErrorMessage = null;
    } catch (error) {
      _profileErrorMessage = _readErrorMessage(error);
    } finally {
      _setLoadingProfile(false);
    }
  }

  Future<bool> updateMyProfile({
    required String fullName,
    required String email,
    required String phone,
    String? avatarUrl,
    String? gender,
    String? dateOfBirth,
  }) async {
    _setUpdatingProfile(true);

    try {
      final updatedUser = await _userProfileService.updateMyProfile(
        UpdateProfileRequestModel(
          fullName: fullName,
          email: email,
          phone: phone,
          avatarUrl: avatarUrl,
          gender: gender,
          dateOfBirth: dateOfBirth,
        ),
      );
      _currentUser = updatedUser;
      _isAuthenticated = true;
      _profileErrorMessage = null;
      return true;
    } catch (error) {
      _profileErrorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setUpdatingProfile(false);
    }
  }

  Future<bool> uploadAndUpdateAvatar(File file) async {
    _isUploadingAvatar = true;
    _avatarErrorMessage = null;
    notifyListeners();

    try {
      final uploadResponse = await _fileUploadService.uploadImage(
        file: file,
        folder: 'avatars',
      );
      final fileUrl = uploadResponse.fileUrl.trim();
      if (fileUrl.isEmpty) {
        throw const ApiException('Không nhận được đường dẫn ảnh đại diện');
      }

      final updatedUser = await _userProfileService.updateAvatar(fileUrl);
      _currentUser = updatedUser;
      _isAuthenticated = true;
      _avatarErrorMessage = null;
      return true;
    } catch (error) {
      _avatarErrorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setUploadingAvatar(false);
    }
  }

  Future<bool> forgotPassword(String username) async {
    final normalizedUsername = username.trim();
    if (normalizedUsername.isEmpty) {
      _errorMessage = 'Vui lòng nhập email hoặc số điện thoại';
      notifyListeners();
      return false;
    }

    _setSendingOtp(true);

    try {
      final response = await _authService.forgotPassword(
        ForgotPasswordRequestModel(username: normalizedUsername),
      );
      _forgotPasswordUsername = normalizedUsername;
      _otpExpiresInMinutes = response.expiresInMinutes;
      _isOtpVerified = false;
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setSendingOtp(false);
    }
  }

  Future<bool> verifyForgotPasswordOtp(String otpCode) async {
    final username = _forgotPasswordUsername;
    if (username == null || username.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập email hoặc số điện thoại trước';
      notifyListeners();
      return false;
    }

    final normalizedOtpCode = otpCode.trim();
    if (normalizedOtpCode.isEmpty) {
      _errorMessage = 'Vui lòng nhập mã xác thực';
      notifyListeners();
      return false;
    }

    _setVerifyingOtp(true);

    try {
      final response = await _authService.verifyForgotPasswordOtp(
        VerifyForgotPasswordOtpRequestModel(
          username: username,
          otpCode: normalizedOtpCode,
        ),
      );

      if (!response.verified) {
        _isOtpVerified = false;
        _errorMessage = response.message.trim().isNotEmpty
            ? response.message
            : 'Mã xác thực không hợp lệ';
        return false;
      }

      _isOtpVerified = true;
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setVerifyingOtp(false);
    }
  }

  Future<bool> resetPasswordWithOtp({
    required String otpCode,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final username = _forgotPasswordUsername;
    if (username == null || username.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập email hoặc số điện thoại trước';
      notifyListeners();
      return false;
    }

    _setResettingPassword(true);

    try {
      await _authService.resetPasswordWithOtp(
        ResetPasswordWithOtpRequestModel(
          username: username,
          otpCode: otpCode.trim(),
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        ),
      );
      clearForgotPasswordState();
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setResettingPassword(false);
    }
  }

  void clearForgotPasswordState() {
    _forgotPasswordUsername = null;
    _otpExpiresInMinutes = null;
    _isOtpVerified = false;
    _isSendingOtp = false;
    _isVerifyingOtp = false;
    _isResettingPassword = false;
    _errorMessage = null;
    _googleLoginError = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _runAuthSideEffect(
        _onBeforeLogout,
        'Không thể hủy device token khi đăng xuất',
      );
      await _runAuthSideEffect(
        _authService.logout,
        'Không thể đăng xuất trên máy chủ',
      );
      await _runAuthSideEffect(
        _googleAuthService.signOut,
        'Không thể đăng xuất Google',
      );
      await _clearTokenSafely();
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      _errorMessage = null;
      _googleLoginError = null;
      _profileErrorMessage = null;
      _avatarErrorMessage = null;
      _setLoading(false);
    }
  }

  void clearError() {
    if (_errorMessage == null && _googleLoginError == null) {
      return;
    }

    _errorMessage = null;
    _googleLoginError = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setSendingOtp(bool value) {
    if (_isSendingOtp == value) {
      return;
    }

    _isSendingOtp = value;
    notifyListeners();
  }

  void _setVerifyingOtp(bool value) {
    if (_isVerifyingOtp == value) {
      return;
    }

    _isVerifyingOtp = value;
    notifyListeners();
  }

  void _setResettingPassword(bool value) {
    if (_isResettingPassword == value) {
      return;
    }

    _isResettingPassword = value;
    notifyListeners();
  }

  void _setLoadingProfile(bool value) {
    if (_isLoadingProfile == value) {
      return;
    }

    _isLoadingProfile = value;
    notifyListeners();
  }

  void _setUpdatingProfile(bool value) {
    if (_isUpdatingProfile == value) {
      return;
    }

    _isUpdatingProfile = value;
    notifyListeners();
  }

  void _setUploadingAvatar(bool value) {
    if (_isUploadingAvatar == value) {
      return;
    }

    _isUploadingAvatar = value;
    notifyListeners();
  }

  Future<void> _clearTokenSafely() async {
    try {
      await _tokenStorage.clearToken();
    } catch (_) {
      // Ignore storage errors so auth state can still reset safely.
    }
  }

  Future<void> _completeAuthentication(
    AuthResponseModel response, {
    required String deviceTokenErrorMessage,
  }) async {
    await _tokenStorage.saveToken(response.accessToken);
    final refreshToken = response.refreshToken;
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _tokenStorage.saveRefreshToken(refreshToken);
    }

    final authenticatedUser = await _loadUserAfterAuth(response.user);
    await _runAuthSideEffect(_onAuthenticated, deviceTokenErrorMessage);
    _currentUser = authenticatedUser;
    _isAuthenticated = true;
  }

  Future<void> _completeGoogleAuthentication(
    AuthResponseModel response, {
    required String deviceTokenErrorMessage,
  }) async {
    await _tokenStorage.saveToken(response.accessToken);
    final refreshToken = response.refreshToken;
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _tokenStorage.saveRefreshToken(refreshToken);
    }

    await _runAuthSideEffect(_onAuthenticated, deviceTokenErrorMessage);
    _currentUser = response.user;
    _isAuthenticated = true;
  }

  Future<void> _runAuthSideEffect(
    Future<void> Function()? action,
    String message,
  ) async {
    if (action == null) {
      return;
    }

    try {
      await action();
    } catch (error) {
      debugPrint('$message: $error');
    }
  }

  Future<UserModel> _loadUserAfterAuth(UserModel fallbackUser) async {
    try {
      final loadedUser = await _authService.getCurrentUser();
      if (loadedUser.roles.isNotEmpty || fallbackUser.roles.isEmpty) {
        return loadedUser;
      }

      return loadedUser.copyWith(roles: fallbackUser.roles);
    } catch (error) {
      debugPrint('Không thể tải thông tin người dùng sau khi xác thực: $error');
      return fallbackUser;
    }
  }

  String _readErrorMessage(Object error) {
    if (error is GoogleAuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
