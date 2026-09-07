import 'package:flutter/foundation.dart';

import '../models/payment_model.dart';
import '../repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository;
  List<PaymentModel> _payments = const [];
  bool _loading = false;

  PaymentProvider({PaymentRepository? repository})
    : _repository = repository ?? PaymentRepository();

  List<PaymentModel> get payments => List.unmodifiable(_payments);
  bool get loading => _loading;

  Future<void> loadPayments() async {
    _loading = true;
    notifyListeners();
    try {
      _payments = await _repository.fetchPayments();
    } catch (error, stackTrace) {
      debugPrint('Failed to load payments: $error');
      debugPrint('$stackTrace');
      _payments = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
