import 'package:flutter/foundation.dart';

import '../models/order_model.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository;
  List<OrderModel> _orders = const [];
  OrderModel? _selectedOrder;
  bool _loading = false;

  OrderProvider({OrderRepository? repository})
    : _repository = repository ?? OrderRepository();

  List<OrderModel> get orders => List.unmodifiable(_orders);
  List<OrderModel> get paidOrders => List.unmodifiable(
    _orders.where((order) => order.paymentStatus.toLowerCase() == 'paid'),
  );
  int get paidOrderCount => paidOrders.length;
  OrderModel? get selectedOrder => _selectedOrder;
  bool get loading => _loading;

  Future<void> loadOrders() async {
    _loading = true;
    notifyListeners();
    try {
      _orders = await _repository.fetchOrders();
    } catch (error, stackTrace) {
      debugPrint('Failed to load orders: $error');
      debugPrint('$stackTrace');
      _orders = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectOrderById(String orderId) async {
    _loading = true;
    notifyListeners();
    try {
      _selectedOrder = await _repository.fetchOrderById(orderId);
    } catch (error, stackTrace) {
      debugPrint('Failed to load order: $error');
      debugPrint('$stackTrace');
      _selectedOrder = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderPaymentStatus(
    String orderId,
    String paymentStatus,
    String paymentMethod,
  ) async {
    try {
      await _repository.updateOrderPaymentStatus(
        orderId,
        paymentStatus,
        paymentMethod,
      );
      // Refresh orders list
      await loadOrders();
      // Refresh selected order if it matches
      if (_selectedOrder?.id == orderId) {
        await selectOrderById(orderId);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to update order payment status: $error');
      debugPrint('$stackTrace');
    }
  }
}
