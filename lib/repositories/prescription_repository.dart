import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_constants.dart';
import '../models/prescription_model.dart';

class PrescriptionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PrescriptionRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<List<PrescriptionModel>> fetchPrescriptions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection(FirebaseConstants.prescriptionsCollection)
        .where('patientId', isEqualTo: uid)
        .get();

    final prescriptions = snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = data['createdAt'];
      return PrescriptionModel(
        id: doc.id,
        patientId: data['patientId'] as String? ?? uid,
        details: data['details'] as String? ?? '',
        documentUrl: data['documentUrl'] as String? ?? data['url'] as String?,
        createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
      );
    }).toList();

    prescriptions.sort((a, b) {
      final first = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final second = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return second.compareTo(first);
    });
    return prescriptions;
  }
}
