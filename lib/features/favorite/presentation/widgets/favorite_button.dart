import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../product/data/models/product_model.dart';
import '../../providers/favorite_provider.dart';

/// Nút trái tim thêm/bỏ sản phẩm khỏi danh sách yêu thích.
class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.product,
    this.compact = false,
  });

  final ProductModel product;

  /// Dạng nhỏ có nền tròn trắng, dùng đè lên ảnh sản phẩm.
  final bool compact;

  Future<void> _toggle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    final owner = auth.currentUser?.id;
    if (owner == null) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Đăng nhập để lưu sản phẩm yêu thích'),
          action: SnackBarAction(
            label: 'Đăng nhập',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
          ),
        ),
      );
      return;
    }

    final nowFavorite = await context.read<FavoriteProvider>().toggle(
      owner,
      product,
    );
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          nowFavorite ? 'Đã thêm vào yêu thích' : 'Đã bỏ khỏi yêu thích',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoriteProvider, bool>(
      (provider) => provider.isFavorite(product.id),
    );
    final icon = Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
      color: isFavorite ? AppTheme.error : AppTheme.textSecondary,
      size: compact ? 20 : 24,
    );

    if (compact) {
      return Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _toggle(context),
          child: Padding(padding: const EdgeInsets.all(6), child: icon),
        ),
      );
    }

    return IconButton(
      tooltip: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
      onPressed: () => _toggle(context),
      icon: icon,
    );
  }
}
