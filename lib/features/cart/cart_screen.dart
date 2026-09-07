import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../shared/widgets/gav_logo_title.dart';
import '../order/order_list_screen.dart';

class CartScreen extends StatefulWidget {
  final List<CartItem> initialItems;

  const CartScreen({super.key, this.initialItems = const []});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late final List<CartItem> _items = List.of(widget.initialItems);
  bool _submitting = false;

  double get _total =>
      _items.fold(0, (subtotal, item) => subtotal + item.total);

  Future<void> _placeOrder() async {
    final patientId = FirebaseAuth.instance.currentUser?.uid;
    if (patientId == null) {
      _message('Votre session a expiré. Reconnectez-vous.');
      return;
    }
    if (_items.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.ordersCollection)
          .add({
            'patientId': patientId,
            'items': _items
                .map(
                  (item) => {
                    'productId': item.id,
                    'productName': item.name,
                    'price': item.price,
                    'quantity': item.quantity,
                  },
                )
                .toList(),
            'totalAmount': _total,
            'status': 'pending',
            'paymentStatus': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OrderListScreen()),
      );
    } on FirebaseException catch (error) {
      _message('Commande impossible : ${error.message ?? error.code}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD62F2F),
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: GavLogoTitle(
          title: 'Panier',
          titleColor: Colors.white,
          logoSize: 28,
          textSize: 18,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Expanded(
                child: _items.isEmpty
                    ? const Center(child: Text('Votre panier est vide.'))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _itemCard(_items[index]),
                      ),
              ),
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 18),
                _summary(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD62F2F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Commander',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemCard(CartItem item) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.remove_red_eye_outlined,
            size: 36,
            color: Color(0xFF1F2D3D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2D3D),
                ),
              ),
              if (item.subtitle.isNotEmpty)
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _formatPrice(item.price),
                style: const TextStyle(
                  color: Color(0xFF1A5276),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: item.quantity > 1
                  ? () => setState(() => item.quantity--)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              onPressed: () => setState(() => item.quantity++),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _summary() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sous-total',
              style: TextStyle(color: Color(0xFF4B5563)),
            ),
            Text(
              _formatPrice(_total),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Livraison', style: TextStyle(color: Color(0xFF4B5563))),
            Text('Gratuite', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const Divider(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              _formatPrice(_total),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A5276),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class CartItem {
  final String id;
  final String name;
  final double price;
  final String subtitle;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.subtitle = '',
    this.quantity = 1,
  });

  double get total => price * quantity;
}

String _formatPrice(double value) => '${value.toStringAsFixed(0)} FCFA';
