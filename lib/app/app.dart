import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/firebase/firebase_messaging_config.dart';
import '../core/navigation/app_navigator.dart';
import '../core/network/dio_client.dart';
import '../features/account/data/services/user_address_service.dart';
import '../features/account/providers/user_address_provider.dart';
import '../features/admin/data/services/admin_activity_log_service.dart';
import '../features/admin/data/services/admin_brand_service.dart';
import '../features/admin/data/services/admin_category_service.dart';
import '../features/admin/data/services/admin_dashboard_service.dart';
import '../features/admin/data/services/admin_inventory_service.dart';
import '../features/admin/data/services/admin_order_service.dart';
import '../features/admin/data/services/admin_pharmacy_service.dart';
import '../features/admin/data/services/admin_product_service.dart';
import '../features/admin/data/services/admin_prescription_service.dart';
import '../features/admin/data/services/admin_user_service.dart';
import '../features/admin/data/services/admin_voucher_service.dart';
import '../features/admin/providers/admin_activity_log_provider.dart';
import '../features/admin/providers/admin_brand_provider.dart';
import '../features/admin/providers/admin_category_provider.dart';
import '../features/admin/providers/admin_dashboard_provider.dart';
import '../features/admin/providers/admin_inventory_provider.dart';
import '../features/admin/providers/admin_order_provider.dart';
import '../features/admin/providers/admin_pharmacy_provider.dart';
import '../features/admin/providers/admin_product_provider.dart';
import '../features/admin/providers/admin_prescription_provider.dart';
import '../features/admin/providers/admin_user_provider.dart';
import '../features/admin/providers/admin_voucher_provider.dart';
import '../features/auth/data/services/auth_service.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/brand/data/services/brand_service.dart';
import '../features/brand/providers/brand_provider.dart';
import '../features/cart/data/services/cart_service.dart';
import '../features/cart/providers/cart_provider.dart';
import '../features/category/data/services/category_service.dart';
import '../features/category/providers/category_provider.dart';
import '../features/device_token/data/models/save_device_token_request_model.dart';
import '../features/device_token/data/services/device_token_service.dart';
import '../features/device_token/providers/device_token_provider.dart';
import '../features/inventory/data/services/inventory_service.dart';
import '../features/inventory/providers/inventory_provider.dart';
import '../features/notification/data/services/notification_service.dart';
import '../features/notification/providers/notification_provider.dart';
import '../features/order/data/services/order_service.dart';
import '../features/order/providers/order_provider.dart';
import '../features/payment/data/services/payment_service.dart';
import '../features/payment/providers/payment_provider.dart';
import '../features/pharmacy/data/services/pharmacy_service.dart';
import '../features/pharmacy/providers/pharmacy_provider.dart';
import '../features/prescription/data/services/prescription_service.dart';
import '../features/prescription/providers/prescription_provider.dart';
import '../features/product/data/services/product_service.dart';
import '../features/product/providers/product_provider.dart';
import '../features/review/data/services/review_service.dart';
import '../features/review/providers/review_provider.dart';
import '../features/voucher/data/services/voucher_service.dart';
import '../features/voucher/providers/voucher_provider.dart';
import 'routes.dart';
import 'theme.dart';

class PharmaApp extends StatelessWidget {
  const PharmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();
    final deviceTokenService = DeviceTokenService(dioClient: dioClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            authService: AuthService(dioClient: dioClient),
            onAuthenticated: () => _saveCurrentDeviceToken(deviceTokenService),
            onBeforeLogout: () =>
                _deactivateCurrentDeviceToken(deviceTokenService),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminDashboardProvider(
            adminDashboardService: AdminDashboardService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProductProvider(
            adminProductService: AdminProductService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminCategoryProvider(
            adminCategoryService: AdminCategoryService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminBrandProvider(
            adminBrandService: AdminBrandService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminVoucherProvider(
            adminVoucherService: AdminVoucherService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminPharmacyProvider(
            adminPharmacyService: AdminPharmacyService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminInventoryProvider(
            adminInventoryService: AdminInventoryService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminUserProvider(
            adminUserService: AdminUserService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminActivityLogProvider(
            adminActivityLogService: AdminActivityLogService(
              dioClient: dioClient,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminOrderProvider(
            adminOrderService: AdminOrderService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminPrescriptionProvider(
            adminPrescriptionService: AdminPrescriptionService(
              dioClient: dioClient,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(
            categoryService: CategoryService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              BrandProvider(brandService: BrandService(dioClient: dioClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(
            productService: ProductService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              CartProvider(cartService: CartService(dioClient: dioClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => UserAddressProvider(
            userAddressService: UserAddressService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              OrderProvider(orderService: OrderService(dioClient: dioClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider(
            paymentService: PaymentService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PrescriptionProvider(
            prescriptionService: PrescriptionService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewProvider(
            reviewService: ReviewService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            notificationService: NotificationService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              DeviceTokenProvider(deviceTokenService: deviceTokenService),
        ),
        ChangeNotifierProvider(
          create: (_) => VoucherProvider(
            voucherService: VoucherService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => PharmacyProvider(
            pharmacyService: PharmacyService(dioClient: dioClient),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => InventoryProvider(
            inventoryService: InventoryService(dioClient: dioClient),
          ),
        ),
      ],
      child: _FirebaseMessagingTokenRefreshListener(
        child: MaterialApp(
          navigatorKey: AppNavigator.navigatorKey,
          scaffoldMessengerKey: AppNavigator.scaffoldMessengerKey,
          title: 'An Tâm Pharma',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
  }
}

class _FirebaseMessagingTokenRefreshListener extends StatefulWidget {
  const _FirebaseMessagingTokenRefreshListener({required this.child});

  final Widget child;

  @override
  State<_FirebaseMessagingTokenRefreshListener> createState() =>
      _FirebaseMessagingTokenRefreshListenerState();
}

class _FirebaseMessagingTokenRefreshListenerState
    extends State<_FirebaseMessagingTokenRefreshListener> {
  @override
  void initState() {
    super.initState();

    FirebaseMessagingConfig.listenTokenRefresh((_) async {
      if (!mounted) {
        return;
      }

      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isAuthenticated) {
        return;
      }

      try {
        final deviceTokenProvider = context.read<DeviceTokenProvider>();
        final success = await deviceTokenProvider.saveCurrentDeviceToken();
        if (!success) {
          final message = deviceTokenProvider.errorMessage;
          if (message != null && message.trim().isNotEmpty) {
            debugPrint('Không thể lưu FCM token mới: $message');
          }
        }
      } catch (error) {
        debugPrint('Không thể lưu FCM token mới: $error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Future<void> _saveCurrentDeviceToken(
  DeviceTokenService deviceTokenService,
) async {
  final token = await FirebaseMessagingConfig.getFcmToken();
  if (token == null || token.trim().isEmpty) {
    return;
  }

  await deviceTokenService.saveDeviceToken(
    SaveDeviceTokenRequestModel(token: token, platform: _currentPlatform()),
  );
}

Future<void> _deactivateCurrentDeviceToken(
  DeviceTokenService deviceTokenService,
) async {
  final token = await FirebaseMessagingConfig.getFcmToken();
  if (token == null || token.trim().isEmpty) {
    return;
  }

  await deviceTokenService.deactivateDeviceToken(token);
}

String _currentPlatform() {
  if (kIsWeb) {
    return 'WEB';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'ANDROID';
    case TargetPlatform.iOS:
      return 'IOS';
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
      return 'UNKNOWN';
  }
}
