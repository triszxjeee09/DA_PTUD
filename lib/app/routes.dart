import 'package:flutter/material.dart';

import 'main_navigation_screen.dart';
import '../core/widgets/require_admin.dart';
import '../features/account/data/models/user_address_model.dart';
import '../features/account/presentation/screens/add_edit_address_screen.dart';
import '../features/account/presentation/screens/edit_profile_screen.dart';
import '../features/account/presentation/screens/select_address_screen.dart';
import '../features/admin/presentation/screens/admin_activity_log_screen.dart';
import '../features/admin/presentation/screens/admin_brand_screen.dart';
import '../features/admin/presentation/screens/admin_brand_form_screen.dart';
import '../features/admin/presentation/screens/admin_category_screen.dart';
import '../features/admin/presentation/screens/admin_category_form_screen.dart';
import '../features/admin/presentation/screens/admin_inventory_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_main_screen.dart';
import '../features/admin/presentation/screens/admin_more_screen.dart';
import '../features/admin/presentation/screens/admin_order_screen.dart';
import '../features/admin/presentation/screens/admin_pharmacy_form_screen.dart';
import '../features/admin/presentation/screens/admin_pharmacy_screen.dart';
import '../features/admin/presentation/screens/admin_prescription_screen.dart';
import '../features/admin/presentation/screens/admin_product_form_screen.dart';
import '../features/admin/presentation/screens/admin_product_images_screen.dart';
import '../features/admin/presentation/screens/admin_product_screen.dart';
import '../features/admin/presentation/screens/admin_send_notification_screen.dart';
import '../features/admin/presentation/screens/admin_user_detail_screen.dart';
import '../features/admin/presentation/screens/admin_user_screen.dart';
import '../features/admin/presentation/screens/admin_voucher_form_screen.dart';
import '../features/admin/presentation/screens/admin_voucher_screen.dart';
import '../features/auth/data/models/user_model.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/reset_password_with_otp_screen.dart';
import '../features/auth/presentation/screens/verify_forgot_password_otp_screen.dart';
import '../features/cart/presentation/screens/cart_screen.dart';
import '../features/notification/presentation/screens/notification_screen.dart';
import '../features/order/data/models/order_detail_model.dart';
import '../features/order/presentation/screens/checkout_screen.dart';
import '../features/order/presentation/screens/order_detail_screen.dart';
import '../features/order/presentation/screens/order_history_screen.dart';
import '../features/order/presentation/screens/order_success_screen.dart';
import '../features/order/presentation/screens/order_tracking_screen.dart';
import '../features/payment/data/models/payment_model.dart';
import '../features/payment/presentation/screens/payment_processing_screen.dart';
import '../features/payment/presentation/screens/payment_result_screen.dart';
import '../features/payment/presentation/screens/vnpay_webview_screen.dart';
import '../features/pharmacy/data/models/pharmacy_model.dart';
import '../features/pharmacy/presentation/screens/pharmacy_detail_screen.dart';
import '../features/pharmacy/presentation/screens/pharmacy_near_me_screen.dart';
import '../features/prescription/presentation/screens/prescription_detail_screen.dart';
import '../features/prescription/presentation/screens/prescription_list_screen.dart';
import '../features/prescription/presentation/screens/select_prescription_screen.dart';
import '../features/prescription/presentation/screens/upload_prescription_screen.dart';
import '../features/product/presentation/screens/product_detail_screen.dart';
import '../features/product/presentation/screens/product_list_screen.dart';
import '../features/product/presentation/screens/product_search_screen.dart';
import '../features/review/presentation/screens/product_review_list_screen.dart';
import '../features/review/presentation/screens/write_review_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/voucher/presentation/screens/apply_voucher_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String forgotPasswordVerifyOtp = '/forgot-password/verify-otp';
  static const String forgotPasswordResetPassword =
      '/forgot-password/reset-password';
  static const String register = '/register';
  static const String main = '/main';
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminProducts = '/admin/products';
  static const String adminOrders = '/admin/orders';
  static const String adminOrderDetail = '/admin/orders/detail';
  static const String adminPrescriptions = '/admin/prescriptions';
  static const String adminCategories = '/admin/categories';
  static const String adminBrands = '/admin/brands';
  static const String adminVouchers = '/admin/vouchers';
  static const String adminPharmacies = '/admin/pharmacies';
  static const String adminInventory = '/admin/inventory';
  static const String adminUsers = '/admin/users';
  static const String adminActivityLogs = '/admin/activity-logs';
  static const String adminMore = '/admin/more';
  static const String adminNotificationSend = '/admin/notifications/send';
  static const String adminProductForm = '/admin/products/form';
  static const String adminProductImages = '/admin/products/images';
  static const String adminCategoryForm = '/admin/categories/form';
  static const String adminBrandForm = '/admin/brands/form';
  static const String adminVoucherForm = '/admin/vouchers/form';
  static const String adminPharmacyForm = '/admin/pharmacies/form';
  static const String adminUserDetail = '/admin/users/detail';
  static const String pharmacist = '/pharmacist';
  static const String home = '/home';
  static const String productList = '/products';
  static const String productSearch = '/products/search';
  static const String productDetail = '/products/detail';
  static const String cart = '/cart';
  static const String accountProfile = '/account/profile';
  static const String notifications = '/notifications';
  static const String vouchers = '/vouchers';
  static const String applyVoucher = '/vouchers/apply';
  static const String selectAddress = '/addresses/select';
  static const String addressForm = '/addresses/form';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String orderSuccess = '/order-success';
  static const String orderDetail = '/orders/detail';
  static const String orderTracking = '/orders/tracking';
  static const String paymentProcessing = '/payment/processing';
  static const String paymentResult = '/payment/result';
  static const String paymentVnPay = '/payment/vnpay';
  static const String pharmacies = '/pharmacies';
  static const String pharmacyDetail = '/pharmacies/detail';
  static const String prescriptions = '/prescriptions';
  static const String prescriptionUpload = '/prescriptions/upload';
  static const String prescriptionDetail = '/prescriptions/detail';
  static const String prescriptionSelect = '/prescriptions/select';
  static const String writeReview = '/reviews/write';
  static const String productReviews = '/reviews/product';

  static String authenticatedHomeForUser(UserModel? user) {
    if (user?.isAdmin ?? false) {
      return admin;
    }

    if (user?.isPharmacist ?? false) {
      return pharmacist;
    }

    return main;
  }

  static Widget _requireAdmin(Widget child) {
    return RequireAdmin(child: child);
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case forgotPasswordVerifyOtp:
        return MaterialPageRoute(
          builder: (_) => const VerifyForgotPasswordOtpScreen(),
          settings: settings,
        );
      case forgotPasswordResetPassword:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => ResetPasswordWithOtpScreen(
            otpCode: arguments?['otpCode']?.toString() ?? '',
          ),
          settings: settings,
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case main:
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
          settings: settings,
        );
      case admin:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminMainScreen()),
          settings: settings,
        );
      case adminDashboard:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminDashboardScreen()),
          settings: settings,
        );
      case adminProducts:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminProductScreen()),
          settings: settings,
        );
      case adminOrders:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminOrderScreen()),
          settings: settings,
        );
      case adminOrderDetail:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(
            const PlaceholderRouteScreen(
              title: 'Chi tiết đơn hàng Admin',
              message: 'Màn hình chi tiết đơn hàng Admin đang được cập nhật.',
            ),
          ),
          settings: settings,
        );
      case adminPrescriptions:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminPrescriptionScreen()),
          settings: settings,
        );
      case adminCategories:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminCategoryScreen()),
          settings: settings,
        );
      case adminBrands:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminBrandScreen()),
          settings: settings,
        );
      case adminVouchers:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminVoucherScreen()),
          settings: settings,
        );
      case adminPharmacies:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminPharmacyScreen()),
          settings: settings,
        );
      case adminInventory:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminInventoryScreen()),
          settings: settings,
        );
      case adminUsers:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminUserScreen()),
          settings: settings,
        );
      case adminActivityLogs:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminActivityLogScreen()),
          settings: settings,
        );
      case adminMore:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminMoreScreen()),
          settings: settings,
        );
      case adminNotificationSend:
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(const AdminSendNotificationScreen()),
          settings: settings,
        );
      case adminProductForm:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(
            AdminProductFormScreen(
              productId: arguments?['productId']?.toString(),
            ),
          ),
          settings: settings,
        );
      case adminProductImages:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(
            AdminProductImagesScreen(
              productId: arguments?['productId']?.toString() ?? '',
            ),
          ),
          settings: settings,
        );
      case adminCategoryForm:
        final arguments = _readArguments(settings.arguments);
        final rawCategoryId = arguments?['categoryId'];
        final categoryId = rawCategoryId?.toString().trim();
        return MaterialPageRoute<bool>(
          builder: (_) => _requireAdmin(
            AdminCategoryFormScreen(
              categoryId: categoryId == null || categoryId.isEmpty
                  ? null
                  : categoryId,
            ),
          ),
          settings: settings,
        );
      case adminBrandForm:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(
            AdminBrandFormScreen(brandId: arguments?['brandId']?.toString()),
          ),
          settings: settings,
        );
      case adminVoucherForm:
        final arguments = _readArguments(settings.arguments);
        final rawVoucherId = arguments?['voucherId'];
        final voucherId = rawVoucherId?.toString().trim();
        return MaterialPageRoute<bool>(
          builder: (_) => _requireAdmin(
            AdminVoucherFormScreen(
              voucherId: voucherId == null || voucherId.isEmpty
                  ? null
                  : voucherId,
            ),
          ),
          settings: settings,
        );
      case adminPharmacyForm:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => _requireAdmin(
            AdminPharmacyFormScreen(
              pharmacyId: arguments?['pharmacyId']?.toString(),
              pharmacy: arguments?['pharmacy'] is PharmacyModel
                  ? arguments!['pharmacy'] as PharmacyModel
                  : null,
            ),
          ),
          settings: settings,
        );
      case adminUserDetail:
        final arguments = _readArguments(settings.arguments);
        final rawUserId = arguments?['userId'];
        final userId = rawUserId?.toString().trim() ?? '';
        return MaterialPageRoute<bool>(
          builder: (_) => _requireAdmin(AdminUserDetailScreen(userId: userId)),
          settings: settings,
        );
      case pharmacist:
        return MaterialPageRoute(
          builder: (_) => const PharmacistMainScreen(),
          settings: settings,
        );
      case productList:
        return MaterialPageRoute(
          builder: (_) =>
              ProductListScreen(arguments: _readArguments(settings.arguments)),
          settings: settings,
        );
      case productSearch:
        return MaterialPageRoute(
          builder: (_) => const ProductSearchScreen(),
          settings: settings,
        );
      case productDetail:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            productId: arguments?['id']?.toString() ?? '',
          ),
          settings: settings,
        );
      case cart:
        return MaterialPageRoute(
          builder: (_) => const CartScreen(),
          settings: settings,
        );
      case accountProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfileScreen(),
          settings: settings,
        );
      case notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationScreen(),
          settings: settings,
        );
      case vouchers:
        return MaterialPageRoute(
          builder: (_) => const PlaceholderRouteScreen(
            title: 'Khuyến mãi',
            message: 'Chức năng khuyến mãi đang được cập nhật.',
          ),
          settings: settings,
        );
      case applyVoucher:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => ApplyVoucherScreen(
            orderAmount: _readDouble(arguments?['orderAmount']),
          ),
          settings: settings,
        );
      case selectAddress:
        return MaterialPageRoute(
          builder: (_) => const SelectAddressScreen(),
          settings: settings,
        );
      case addressForm:
        final arguments = _readArguments(settings.arguments);
        final address = settings.arguments is UserAddressModel
            ? settings.arguments! as UserAddressModel
            : arguments?['address'] is UserAddressModel
            ? arguments!['address'] as UserAddressModel
            : null;
        return MaterialPageRoute(
          builder: (_) => AddEditAddressScreen(
            addressId: arguments?['addressId']?.toString(),
            address: address,
          ),
          settings: settings,
        );
      case checkout:
        return MaterialPageRoute(
          builder: (_) => const CheckoutScreen(),
          settings: settings,
        );
      case orders:
        return MaterialPageRoute(
          builder: (_) => const OrderHistoryScreen(),
          settings: settings,
        );
      case orderSuccess:
        final arguments = _readArguments(settings.arguments);
        final order = settings.arguments is OrderDetailModel
            ? settings.arguments! as OrderDetailModel
            : arguments?['order'] is OrderDetailModel
            ? arguments!['order'] as OrderDetailModel
            : null;
        return MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            order: order,
            orderId: arguments?['orderId']?.toString(),
          ),
          settings: settings,
        );
      case orderDetail:
        final arguments = _readArguments(settings.arguments);
        final order = settings.arguments is OrderDetailModel
            ? settings.arguments! as OrderDetailModel
            : arguments?['order'] is OrderDetailModel
            ? arguments!['order'] as OrderDetailModel
            : null;
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: arguments?['orderId']?.toString(),
            order: order,
          ),
          settings: settings,
        );
      case orderTracking:
        final arguments = _readArguments(settings.arguments);
        final order = settings.arguments is OrderDetailModel
            ? settings.arguments! as OrderDetailModel
            : arguments?['order'] is OrderDetailModel
            ? arguments!['order'] as OrderDetailModel
            : null;
        return MaterialPageRoute(
          builder: (_) => OrderTrackingScreen(
            orderId: arguments?['orderId']?.toString(),
            order: order,
          ),
          settings: settings,
        );
      case paymentProcessing:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => PaymentProcessingScreen(
            orderId: arguments?['orderId']?.toString() ?? '',
            orderCode: arguments?['orderCode']?.toString(),
            paymentMethod: arguments?['paymentMethod']?.toString() ?? 'COD',
            amount: _readDouble(arguments?['amount']),
          ),
          settings: settings,
        );
      case paymentResult:
        final arguments = _readArguments(settings.arguments);
        final payment = settings.arguments is PaymentModel
            ? settings.arguments! as PaymentModel
            : arguments?['payment'] is PaymentModel
            ? arguments!['payment'] as PaymentModel
            : null;
        return MaterialPageRoute(
          builder: (_) => PaymentResultScreen(
            success: arguments?['success'] == true,
            payment: payment,
            orderId: arguments?['orderId']?.toString(),
            orderCode: arguments?['orderCode']?.toString(),
            paymentMethod: arguments?['paymentMethod']?.toString(),
            amount: _readNullableDouble(arguments?['amount']),
            transactionCode: arguments?['transactionCode']?.toString(),
            message: arguments?['message']?.toString(),
          ),
          settings: settings,
        );
      case paymentVnPay:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => VnPayWebViewScreen(
            paymentUrl: arguments?['paymentUrl']?.toString() ?? '',
            orderId: arguments?['orderId']?.toString() ?? '',
            orderCode: arguments?['orderCode']?.toString() ?? '',
          ),
          settings: settings,
        );
      case pharmacies:
        return MaterialPageRoute(
          builder: (_) => const PharmacyNearMeScreen(),
          settings: settings,
        );
      case pharmacyDetail:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => PharmacyDetailScreen(
            pharmacyId: arguments?['pharmacyId']?.toString(),
          ),
          settings: settings,
        );
      case prescriptions:
        return MaterialPageRoute(
          builder: (_) => const PrescriptionListScreen(),
          settings: settings,
        );
      case prescriptionUpload:
        return MaterialPageRoute(
          builder: (_) => const UploadPrescriptionScreen(),
          settings: settings,
        );
      case prescriptionDetail:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => PrescriptionDetailScreen(
            prescriptionId: arguments?['id']?.toString(),
          ),
          settings: settings,
        );
      case prescriptionSelect:
        return MaterialPageRoute(
          builder: (_) => const SelectPrescriptionScreen(),
          settings: settings,
        );
      case writeReview:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => WriteReviewScreen(
            productId: arguments?['productId']?.toString() ?? '',
            productName: arguments?['productName']?.toString() ?? '',
            productImage: arguments?['productImage']?.toString(),
            orderId: arguments?['orderId']?.toString(),
            unitPrice: _readNullableDouble(arguments?['unitPrice']),
          ),
          settings: settings,
        );
      case productReviews:
        final arguments = _readArguments(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => ProductReviewListScreen(
            productId: arguments?['productId']?.toString() ?? '',
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const UnknownRouteScreen(),
          settings: settings,
        );
    }
  }

  static Map<String, dynamic>? _readArguments(Object? arguments) {
    if (arguments is Map<String, dynamic>) {
      return arguments;
    }

    if (arguments is Map) {
      return arguments.map((key, value) => MapEntry(key.toString(), value));
    }

    return null;
  }

  static double _readDouble(Object? value, {double fallback = 0}) {
    return _readNullableDouble(value) ?? fallback;
  }

  static double? _readNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}

class PharmacistMainScreen extends StatelessWidget {
  const PharmacistMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderRouteScreen(
      title: 'Dược sĩ',
      message: 'Màn hình dược sĩ đang được cập nhật.',
    );
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Không tìm thấy trang')),
      body: const Center(child: Text('Trang bạn yêu cầu không tồn tại.')),
    );
  }
}

class PlaceholderRouteScreen extends StatelessWidget {
  const PlaceholderRouteScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
