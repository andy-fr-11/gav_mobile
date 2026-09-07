import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/firebase_constants.dart';
import '../models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  OrderRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  Future<List<OrderModel>> fetchOrders() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final snapshot = await _firestore
        .collection(FirebaseConstants.ordersCollection)
        .where('patientId', isEqualTo: uid)
        .get();

    final orders = snapshot.docs.map((doc) {
      final data = doc.data();
      final createdAt = data['createdAt'] ?? data['date'];
      final updatedAt = data['updatedAt'];

      final itemsList =
          (data['items'] as List?)
              ?.map(
                (item) => OrderItem(
                  productId: item['productId'] as String? ?? '',
                  productName: item['productName'] as String? ?? 'Produit',
                  price: (item['price'] as num?)?.toDouble() ?? 0.0,
                  quantity: item['quantity'] as int? ?? 1,
                ),
              )
              .toList() ??
          [];

      return OrderModel(
        id: doc.id,
        patientId: data['patientId'] as String? ?? uid,
        totalAmount:
            (data['totalAmount'] as num?)?.toDouble() ??
            (data['total'] as num?)?.toDouble() ??
            0.0,
        status: data['status'] as String? ?? 'pending',
        paymentStatus:
            data['paymentStatus'] as String? ??
            data['paiementStatus'] as String? ??
            'pending',
        items: itemsList,
        createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
        updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
        paymentMethod: data['paymentMethod'] as String?,
        description: data['description'] as String?,
      );
    }).toList();

    orders.sort((a, b) {
      final first = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final second = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return second.compareTo(first);
    });
    return orders;
  }

  Future<OrderModel?> fetchOrderById(String orderId) async {
    final doc = await _firestore
        .collection(FirebaseConstants.ordersCollection)
        .doc(orderId)
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    final createdAt = data['createdAt'] ?? data['date'];
    final updatedAt = data['updatedAt'];

    final itemsList =
        (data['items'] as List?)
            ?.map(
              (item) => OrderItem(
                productId: item['productId'] as String? ?? '',
                productName: item['productName'] as String? ?? 'Produit',
                price: (item['price'] as num?)?.toDouble() ?? 0.0,
                quantity: item['quantity'] as int? ?? 1,
              ),
            )
            .toList() ??
        [];

    return OrderModel(
      id: doc.id,
      patientId: data['patientId'] as String? ?? '',
      totalAmount:
          (data['totalAmount'] as num?)?.toDouble() ??
          (data['total'] as num?)?.toDouble() ??
          0.0,
      status: data['status'] as String? ?? 'pending',
      paymentStatus:
          data['paymentStatus'] as String? ??
          data['paiementStatus'] as String? ??
          'pending',
      items: itemsList,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
      paymentMethod: data['paymentMethod'] as String?,
      description: data['description'] as String?,
    );
  }

  Future<void> updateOrderPaymentStatus(
    String orderId,
    String paymentStatus,
    String paymentMethod,
  ) async {
    await _firestore
        .collection(FirebaseConstants.ordersCollection)
        .doc(orderId)
        .update({
          'paymentStatus': paymentStatus,
          'paymentMethod': paymentMethod,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}
