import 'package:flutter/foundation.dart';

import '../models/patient_model.dart';
import '../repositories/patient_repository.dart';

class PatientProvider extends ChangeNotifier {
  final PatientRepository _repository;
  List<PatientModel> _patients = const [];

  PatientProvider({PatientRepository? repository})
    : _repository = repository ?? PatientRepository();

  List<PatientModel> get patients => List.unmodifiable(_patients);

  Future<void> loadPatients() async {
    _patients = await _repository.fetchPatients();
    notifyListeners();
  }
}
