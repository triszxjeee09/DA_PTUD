import 'package:flutter/foundation.dart';

class ApiConstants {
  const ApiConstants._();

  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:8080/api/v1';
  static const String localBaseUrl = 'http://localhost:8080/api/v1';

  static String get baseUrl {
    if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) {
      return androidEmulatorBaseUrl;
    }

    return localBaseUrl;
  }

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleLogin = '/auth/google';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyForgotPasswordOtp =
      '/auth/verify-forgot-password-otp';
  static const String resetPasswordWithOtp = '/auth/reset-password-with-otp';
  static const String me = '/auth/me';

  static const String categories = '/categories';
  static const String adminCategories = '/categories/admin';
  static const String categoryAdmin = '/categories/admin';
  static const String brands = '/brands';
  static const String brandAdmin = '/brands/admin';
  static const String products = '/products';

  static const String cart = '/cart';
  static const String cartItems = '/cart/items';

  static const String addresses = '/users/addresses';
  static const String userProfile = '/users/profile';
  static const String updateAvatar = '/users/avatar';

  static const String orders = '/orders';
  static const String myOrders = '/orders/my-orders';
  static const String adminOrders = '/orders/admin';

  static const String payments = '/payments';
  static const String myPayments = '/payments/my-payments';
  static const String vnpayCreatePayment = '/payments/vnpay/create-payment';
  static const String vnpayReturn = '/payments/vnpay-return';

  static const String prescriptions = '/prescriptions';
  static const String myPrescriptions = '/prescriptions/my-prescriptions';
  static const String uploadPrescription = '/prescriptions/upload';
  static const String adminPrescriptions = '/prescriptions/admin';

  static const String reviews = '/reviews';
  static const String myReviews = '/reviews/my-reviews';

  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';

  static const String deviceTokens = '/device-tokens';

  static const String uploadFile = '/files/upload';

  static const String vouchers = '/vouchers';
  static const String adminVouchers = '/admin/vouchers';
  static const String legacyAdminVouchers = '/vouchers/admin';
  static const String applyVoucher = '/vouchers/apply';

  static const String pharmacies = '/pharmacies';
  static const String adminPharmacies = '/pharmacies/admin';

  static const String inventory = '/inventory';
  static const String adminInventory = '/inventory/admin';

  // Admin APIs
  static const String adminDashboardOverview = '/admin/dashboard/overview';
  static const String adminDashboardOrderStatus =
      '/admin/dashboard/order-status';
  static const String adminDashboardRevenueLast7Days =
      '/admin/dashboard/revenue/last-7-days';
  static const String adminUsers = '/admin/users';
  static const String adminActivityLogs = '/admin/activity-logs';
  static const String adminSendNotification = '/admin/notifications/send';
}
