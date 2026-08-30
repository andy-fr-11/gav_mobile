import 'package:flutter/foundation.dart';

import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class AppointmentProvider extends ChangeNotifier {
  final AppointmentRepository _repository;
  List<AppointmentModel> _appointments = const [];

  AppointmentProvider({AppointmentRepository? repository})
    : _repository = repository ?? AppointmentRepository();

  List<AppointmentModel> get appointments => List.unmodifiable(_appointments);

  Future<void> loadAppointments() async {
    _appointments = await _repository.fetchAppointments();
    notifyListeners();
  }
}
