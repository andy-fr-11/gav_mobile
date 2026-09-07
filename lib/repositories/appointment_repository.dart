import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/appointment_model.dart';
import '../core/constants/firebase_constants.dart';

class AppointmentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AppointmentRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<List<AppointmentModel>> fetchAppointments() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      debugPrint('fetchAppointments: no current user');
      return [];
    }

    try {
      debugPrint('fetchAppointments: querying for patientId=$uid');
      final snapshot = await _firestore
          .collection(FirebaseConstants.appointmentsCollection)
          .where('patientId', isEqualTo: uid)
          .get();

      debugPrint('fetchAppointments: snapshot size=${snapshot.size}');
      for (final d in snapshot.docs) {
        debugPrint('doc ${d.id} => ${d.data()}');
      }

      final appointments = snapshot.docs.map((d) {
        final data = d.data();
        final ts = data['date'] as Timestamp?;
        final date = ts?.toDate() ?? DateTime.now();
        return AppointmentModel(
          id: d.id,
          patientId: data['patientId'] as String? ?? '',
          date: date,
          reason: data['reason'] as String?,
        );
      }).toList();

      appointments.sort((a, b) => a.date.compareTo(b.date));
      return appointments;
    } catch (e, st) {
      debugPrint('fetchAppointments failed: $e');
      debugPrint('$st');
      // In debug mode, rethrow so the developer sees Firestore exceptions
      if (kDebugMode) rethrow;
      return [];
    }
  }

  /// Creates an appointment. Throws Exception('slot_taken') if a document
  /// already exists for the exact same timestamp.
  Future<void> createAppointment({
    String? patientId,
    required DateTime date,
    String? reason,
  }) async {
    final pid = patientId ?? _auth.currentUser?.uid;
    if (pid == null) throw Exception('Utilisateur non authentifié');

    final targetTs = Timestamp.fromDate(date);
    // Check for exact matching slot
    final conflict = await _firestore
        .collection(FirebaseConstants.appointmentsCollection)
        .where('date', isEqualTo: targetTs)
        .limit(1)
        .get();

    if (conflict.docs.isNotEmpty) {
      throw Exception('slot_taken');
    }

    try {
      debugPrint(
        'Creating appointment for $pid at $targetTs with reason: $reason',
      );
      final docRef = await _firestore
          .collection(FirebaseConstants.appointmentsCollection)
          .add({
            'patientId': pid,
            'date': targetTs,
            'reason': reason ?? '',
            'createdAt': Timestamp.fromDate(DateTime.now()),
          });
      debugPrint('Appointment created with id ${docRef.id}');
    } catch (e, st) {
      debugPrint('Failed to create appointment: $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// Updates an appointment while preventing a conflict with another slot.
  Future<void> updateAppointment({
    required String appointmentId,
    required DateTime date,
    String? reason,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Utilisateur non authentifié');

    final appointmentRef = _firestore
        .collection(FirebaseConstants.appointmentsCollection)
        .doc(appointmentId);
    final existing = await appointmentRef.get();
    if (!existing.exists || existing.data()?['patientId'] != uid) {
      throw Exception('Rendez-vous introuvable');
    }

    final targetTs = Timestamp.fromDate(date);
    final conflict = await _firestore
        .collection(FirebaseConstants.appointmentsCollection)
        .where('date', isEqualTo: targetTs)
        .limit(2)
        .get();
    final hasOtherConflict = conflict.docs.any(
      (doc) => doc.id != appointmentId,
    );
    if (hasOtherConflict) throw Exception('slot_taken');

    await appointmentRef.update({
      'date': targetTs,
      'reason': reason ?? '',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
