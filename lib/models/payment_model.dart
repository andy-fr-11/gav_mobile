class PaymentModel {
  final String id;
  final String patientId;
  final double amount;
  final String status;
  final String? description;
  final String? invoiceUrl;
  final DateTime? date;

  const PaymentModel({
    required this.id,
    required this.patientId,
    required this.amount,
    required this.status,
    this.description,
    this.invoiceUrl,
    this.date,
  });
}
