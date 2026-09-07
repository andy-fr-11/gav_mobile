import 'package:flutter/foundation.dart';

import '../models/prescription_model.dart';
import '../repositories/prescription_repository.dart';

class PrescriptionProvider extends ChangeNotifier {
  final PrescriptionRepository _repository;
  List<PrescriptionModel> _prescriptions = const [];
  bool _loading = false;

  PrescriptionProvider({PrescriptionRepository? repository})
    : _repository = repository ?? PrescriptionRepository();

  List<PrescriptionModel> get prescriptions =>
      List.unmodifiable(_prescriptions);
  bool get loading => _loading;

  Future<void> loadPrescriptions() async {
    _loading = true;
    notifyListeners();
    try {
      _prescriptions = await _repository.fetchPrescriptions();
    } catch (error, stackTrace) {
      debugPrint('Failed to load prescriptions: $error');
      debugPrint('$stackTrace');
      _prescriptions = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
