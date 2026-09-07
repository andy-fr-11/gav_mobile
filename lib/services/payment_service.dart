import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_constants.dart';

class PaymentService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PaymentService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Process payment and create payment record in Firestore
  /// Returns: {success, message, paymentId}
  Future<Map<String, dynamic>> processPayment({
    required String orderId,
    required double amount,
    required String paymentMethod,
    required Map<String, String> paymentDetails, // cardNumber, cardHolder, etc.
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return {'success': false, 'message': 'Utilisateur non authentifié'};
    }

    try {
      // Simulate payment processing (in real app, call external payment API)
      await Future.delayed(const Duration(seconds: 2));

      // Validate payment info
      if (paymentDetails.isEmpty) {
        return {
          'success': false,
          'message': 'VEUILLEZ VÉRIFIER LES INFORMATIONS SAISIES',
        };
      }

      // Simulate random failure (10% chance)
      final random = DateTime.now().millisecond % 10;
      if (random == 0) {
        return {
          'success': false,
          'message': 'PAIEMENT REFUSÉ ; SOLDE INSUFFISANT',
        };
      }

      // Simulate service unavailable (very rare)
      if (random == 1) {
        return {
          'success': false,
          'message':
              'SERVICE DE PAIEMENT INDISPONIBLE, VEUILLEZ RÉESSAYER PLUS TARD',
        };
      }

      // Create payment record in Firestore
      final paymentRef = _firestore
          .collection(FirebaseConstants.paymentsCollection)
          .doc();

      await paymentRef.set({
        'id': paymentRef.id,
        'patientId': uid,
        'orderId': orderId,
        'amount': amount,
        'status': 'paid',
        'paymentMethod': paymentMethod,
        'paymentDetails': {
          'method': paymentMethod,
          'cardLast4':
              paymentDetails['cardNumber']?.substring(
                paymentDetails['cardNumber']!.length - 4,
              ) ??
              'XXXX',
          'cardHolder': paymentDetails['cardHolder'] ?? 'N/A',
        },
        'date': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'description': 'Paiement pour commande $orderId',
        'invoiceUrl': null,
      });

      // Update order payment status
      await _firestore
          .collection(FirebaseConstants.ordersCollection)
          .doc(orderId)
          .update({
            'paymentStatus': 'paid',
            'paymentMethod': paymentMethod,
            'status': 'completed',
            'updatedAt': FieldValue.serverTimestamp(),
          });

      return {
        'success': true,
        'message': 'PAIEMENT EFFECTUÉ AVEC SUCCÈS',
        'paymentId': paymentRef.id,
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Erreur lors du traitement du paiement: $error',
      };
    }
  }
}
