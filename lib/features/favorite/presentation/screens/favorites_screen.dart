import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../providers/favorite_provider.dart';
import '../widgets/favorite_button.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final owner = context.read<AuthProvider>().currentUser?.id;
    if (owner != null && mounted) {
      await context.read<FavoriteProvider>().load(owner);
    }
  }

  Future<void> _addToCart(String productId) async {
    final messenger = ScaffoldMessenger.of(context);
    final cart = context.read<CartProvider>();
    final ok = await cart.addToCart(productId, quantity: 1);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã thêm vào giỏ hàng'
              : (cart.errorMessage ?? 'Không thể thêm vào giỏ hàng'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoriteProvider>();
    final items = provider.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Sản phẩm yêu thích')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: provider.isLoading && items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 140),
                  Icon(
                    Icons.favorite_border,
                    size: 56,
                    color: AppTheme.primaryBlue,
                  ),
                  SizedBox(height: 12),
                  Center(child: Text('Bạn chưa có sản phẩm yêu thích')),
                  SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Bấm vào trái tim để nhận thông báo khi giảm giá hoặc có hàng lại',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final product = items[index];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.productDetail,
                        arguments: {'id': product.id},
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 76,
                                height: 76,
                                color: AppTheme.lightBlue,
                                child: product.thumbnailUrl == null
                                    ? const Icon(
                                        Icons.medication_liquid_outlined,
                                        color: AppTheme.primaryBlue,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: product.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const Icon(
                                          Icons.medication_liquid_outlined,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(product.price),
                                    style: const TextStyle(
                                      color: AppTheme.darkBlue,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (product.requiresPrescription)
                                    const Text(
                                      'Cần đơn thuốc',
                                      style: TextStyle(
                                        color: AppTheme.error,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                FavoriteButton(product: product),
                                IconButton(
                                  tooltip: 'Thêm vào giỏ',
                                  onPressed: () => _addToCart(product.id),
                                  icon: const Icon(
                                    Icons.add_shopping_cart,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
