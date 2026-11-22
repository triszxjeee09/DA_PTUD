import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/routes.dart';
import '../../../../app/theme.dart';
import '../../../../core/network/json_api.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../product/data/models/product_model.dart';

/// Thuốc/sản phẩm thường dùng và gợi ý mua lại định kỳ.
class FrequentProductsScreen extends StatefulWidget {
  const FrequentProductsScreen({super.key});

  @override
  State<FrequentProductsScreen> createState() => _FrequentProductsScreenState();
}

class _FrequentProductsScreenState extends State<FrequentProductsScreen> {
  final JsonApi _api = JsonApi();
  List<Map<String, dynamic>> _items = const [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = JsonApi.asList(await _api.get('/orders/frequent-products'));
    } catch (error) {
      _error = JsonApi.message(error);
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _date(String? iso) {
    final date = DateTime.tryParse(iso ?? '')?.toLocal();
    if (date == null) {
      return '-';
    }
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _reorder(ProductModel product) async {
    final messenger = ScaffoldMessenger.of(context);
    final cart = context.read<CartProvider>();
    final ok = await cart.addToCart(product.id, quantity: 1);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã thêm vào giỏ hàng' : (cart.errorMessage ?? 'Không thể thêm vào giỏ hàng')),
        action: ok
            ? SnackBarAction(label: 'Xem giỏ', onPressed: () => Navigator.of(context).pushNamed(AppRoutes.cart))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      appBar: AppBar(title: const Text('Thuốc thường dùng')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(children: [const SizedBox(height: 140), Center(child: Text(_error!))])
            : _items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 140),
                  Icon(Icons.history, size: 56, color: AppTheme.primaryBlue),
                  SizedBox(height: 12),
                  Center(child: Text('Chưa có lịch sử mua hàng')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final product = ProductModel.fromJson(JsonApi.asMap(item['product']));
                  final isDue = item['isDue'] == true;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  color: AppTheme.lightBlue,
                                  child: product.thumbnailUrl == null
                                      ? const Icon(Icons.medication_outlined, color: AppTheme.primaryBlue)
                                      : CachedNetworkImage(
                                          imageUrl: product.thumbnailUrl!,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              const Icon(Icons.medication_outlined, color: AppTheme.primaryBlue),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                    Text(
                                      'Đã mua ${item['timesPurchased']} lần • gần nhất ${_date(item['lastPurchasedAt']?.toString())}',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12.5),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(product.price),
                                      style: const TextStyle(color: AppTheme.darkBlue, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isDue
                                      ? 'Đã đến lúc mua lại (chu kỳ ~${item['averageIntervalDays']} ngày)'
                                      : 'Gợi ý mua lại: ${_date(item['nextSuggestedAt']?.toString())}',
                                  style: TextStyle(
                                    color: isDue ? AppTheme.warning : AppTheme.textSecondary,
                                    fontWeight: isDue ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              FilledButton.tonal(
                                onPressed: () => _reorder(product),
                                child: const Text('Mua lại'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
