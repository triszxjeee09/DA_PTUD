import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../data/models/add_to_cart_request_model.dart';
import '../data/models/cart_model.dart';
import '../data/models/update_cart_item_request_model.dart';
import '../data/services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  CartProvider({CartService? cartService})
    : _cartService = cartService ?? CartService();

  static const String _defaultErrorMessage =
      'Đã có lỗi xảy ra, vui lòng thử lại';

  final CartService _cartService;

  CartModel? _cart;
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;

  CartModel? get cart => _cart;
  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;

  Future<void> loadCart() async {
    _setLoading(true);

    try {
      _cart = await _cartService.getMyCart();
      _errorMessage = null;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addToCart(String productId, {int quantity = 1}) {
    return _updateCart(
      () => _cartService.addToCart(
        AddToCartRequestModel(productId: productId, quantity: quantity),
      ),
    );
  }

  Future<bool> updateQuantity(String cartItemId, int quantity) {
    return _updateCart(
      () => _cartService.updateCartItem(
        cartItemId,
        UpdateCartItemRequestModel(quantity: quantity),
      ),
    );
  }

  Future<bool> increaseItem(String cartItemId) {
    return _updateCart(() => _cartService.increaseCartItem(cartItemId));
  }

  Future<bool> decreaseItem(String cartItemId) {
    return _updateCart(() => _cartService.decreaseCartItem(cartItemId));
  }

  Future<bool> removeItem(String cartItemId) async {
    return _runVoidUpdate(() async {
      await _cartService.removeCartItem(cartItemId);
      await loadCart();
    });
  }

  Future<bool> clearCart() async {
    return _runVoidUpdate(() async {
      await _cartService.clearCart();
      await loadCart();
    });
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _updateCart(Future<CartModel> Function() action) async {
    _setUpdating(true);

    try {
      _cart = await action();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  Future<bool> _runVoidUpdate(Future<void> Function() action) async {
    _setUpdating(true);

    try {
      await action();
      _errorMessage = null;
      return true;
    } catch (error) {
      _errorMessage = _readErrorMessage(error);
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) {
      return;
    }

    _isLoading = value;
    notifyListeners();
  }

  void _setUpdating(bool value) {
    if (_isUpdating == value) {
      return;
    }

    _isUpdating = value;
    notifyListeners();
  }

  String _readErrorMessage(Object error) {
    if (error is ApiException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return _defaultErrorMessage;
  }
}
