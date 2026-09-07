class PrescriptionModel {
  final String id;
  final String patientId;
  final String details;
  final String? documentUrl;
  final DateTime? createdAt;

  const PrescriptionModel({
    required this.id,
    required this.patientId,
    required this.details,
    this.documentUrl,
    this.createdAt,
  });
}
