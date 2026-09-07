import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_constants.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PaymentRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<List<PaymentModel>> fetchPayments() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection(FirebaseConstants.paymentsCollection)
        .where('patientId', isEqualTo: uid)
        .get();

    final payments = snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = data['date'] ?? data['createdAt'] ?? data['paidAt'];
      return PaymentModel(
        id: doc.id,
        patientId: data['patientId'] as String? ?? uid,
        amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        status:
            data['status'] as String? ?? data['statut'] as String? ?? 'pending',
        description: data['description'] as String? ?? data['motif'] as String?,
        invoiceUrl: data['invoiceUrl'] as String? ?? data['url'] as String?,
        date: timestamp is Timestamp ? timestamp.toDate() : null,
      );
    }).toList();

    payments.sort((a, b) {
      final first = a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final second = b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return second.compareTo(first);
    });
    return payments;
  }
}
