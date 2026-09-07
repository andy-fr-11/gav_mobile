class ExaminationModel {
  final String id;
  final String patientId;
  final String type;
  final String details;
  final String? result;
  final String? status;
  final String? documentUrl;
  final DateTime? performedAt;

  const ExaminationModel({
    required this.id,
    required this.patientId,
    required this.type,
    required this.details,
    this.result,
    this.status,
    this.documentUrl,
    this.performedAt,
  });
}
