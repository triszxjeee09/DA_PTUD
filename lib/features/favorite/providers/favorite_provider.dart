import 'package:flutter/foundation.dart';

import '../../../core/sync/synced_collection.dart';
import '../../product/data/models/product_model.dart';

/// Sản phẩm yêu thích: lưu SQLite trên máy, đồng bộ API. Backend sẽ gửi FCM khi
/// sản phẩm yêu thích giảm giá hoặc có hàng lại.
class FavoriteProvider extends ChangeNotifier {
  FavoriteProvider({SyncedCollection? collection})
    : _collection =
          collection ??
          SyncedCollection(
            kind: 'favorites',
            listPath: '/favorites',
            createPath: (_) => '/favorites',
            deletePath: (id) => '/favorites/$id',
            bodyOf: (item) => {'productId': item['id']},
          );

  final SyncedCollection _collection;

  String? _owner;
  List<ProductModel> _items = const [];
  bool _isLoading = false;

  List<ProductModel> get items => _items;
  bool get isLoading => _isLoading;

  bool isFavorite(String productId) {
    for (final item in _items) {
      if (item.id == productId) {
        return true;
      }
    }
    return false;
  }

  Future<void> load(String owner) async {
    if (_owner != owner) {
      _owner = owner;
      _items = const [];
    }
    _isLoading = true;
    notifyListeners();
    await _reloadLocal(owner);
    _isLoading = false;
    notifyListeners();

    await _collection.sync(owner);
    await _reloadLocal(owner);
    notifyListeners();
  }

  /// Đổi trạng thái yêu thích. Trả về trạng thái mới (`true` = đã thích).
  Future<bool> toggle(String owner, ProductModel product) async {
    _owner = owner;
    final wasFavorite = isFavorite(product.id);
    if (wasFavorite) {
      _items = _items.where((item) => item.id != product.id).toList();
      notifyListeners();
      await _collection.remove(owner, product.id);
    } else {
      _items = [product, ..._items];
      notifyListeners();
      await _collection.save(owner, product.toJson());
    }
    return !wasFavorite;
  }

  /// Gọi khi tài khoản đăng nhập thay đổi để không lộ dữ liệu của người khác.
  void resetIfUserChanged(String? userId) {
    if (_owner != null && _owner != userId) {
      _owner = null;
      _items = const [];
    }
  }

  void clear() {
    _owner = null;
    _items = const [];
    notifyListeners();
  }

  Future<void> _reloadLocal(String owner) async {
    final rows = await _collection.load(owner);
    _items = rows.map(ProductModel.fromJson).toList().reversed.toList();
  }
}
