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
    try {
      _appointments = await _repository.fetchAppointments();
    } catch (e, st) {
      debugPrint('Failed to load appointments: $e');
      debugPrint('$st');
      _appointments = [];
    }
    debugPrint('Loaded ${_appointments.length} appointments from repository');

    notifyListeners();
  }

  // exposed for debugging
  void debugPrintCount() {
    debugPrint(
      'AppointmentProvider: ${_appointments.length} appointments loaded',
    );
  }

  Future<void> createAppointment(DateTime date, {String? reason}) async {
    await _repository.createAppointment(date: date, reason: reason);
    await loadAppointments();
  }

  Future<void> updateAppointment(
    String appointmentId,
    DateTime date, {
    String? reason,
  }) async {
    await _repository.updateAppointment(
      appointmentId: appointmentId,
      date: date,
      reason: reason,
    );
    await loadAppointments();
  }
}
