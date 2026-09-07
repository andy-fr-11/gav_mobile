class AppointmentModel {
  final String id;
  final String patientId;
  final DateTime date;
  final String? reason;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.date,
    this.reason,
  });
}
