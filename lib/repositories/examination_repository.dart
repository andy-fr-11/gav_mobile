import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_constants.dart';
import '../models/examination_model.dart';

class ExaminationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ExaminationRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<List<ExaminationModel>> fetchExaminations() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection(FirebaseConstants.examinationsCollection)
        .where('patientId', isEqualTo: uid)
        .get();

    final examinations = snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp =
          data['performedAt'] ?? data['date'] ?? data['createdAt'];
      return ExaminationModel(
        id: doc.id,
        patientId: data['patientId'] as String? ?? uid,
        type:
            data['type'] as String? ??
            data['title'] as String? ??
            'Examen visuel',
        details:
            data['details'] as String? ?? data['description'] as String? ?? '',
        result: data['result'] as String? ?? data['resultat'] as String?,
        status: data['status'] as String? ?? data['statut'] as String?,
        documentUrl: data['documentUrl'] as String? ?? data['url'] as String?,
        performedAt: timestamp is Timestamp ? timestamp.toDate() : null,
      );
    }).toList();

    examinations.sort((a, b) {
      final first = a.performedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final second = b.performedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return second.compareTo(first);
    });
    return examinations;
  }
}
