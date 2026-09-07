class OrderModel {
  final String id;
  final String patientId;
  final double totalAmount;
  final String status; // pending, completed, cancelled
  final String paymentStatus; // pending, paid, failed, refunded
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? paymentMethod;
  final String? description;

  const OrderModel({
    required this.id,
    required this.patientId,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.items,
    this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.description,
  });
}

class OrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
  });
}

class PaymentMethod {
  final String id;
  final String name;
  final String icon; // 'card', 'mobile_money', 'bank', etc.
  final bool isAvailable;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    this.isAvailable = true,
  });
}

const availablePaymentMethods = [
  PaymentMethod(
    id: 'card',
    name: 'Carte bancaire',
    icon: 'card',
    isAvailable: true,
  ),
  PaymentMethod(
    id: 'mobile_money',
    name: 'Mobile Money',
    icon: 'mobile_money',
    isAvailable: true,
  ),
  PaymentMethod(
    id: 'bank_transfer',
    name: 'Virement bancaire',
    icon: 'bank',
    isAvailable: true,
  ),
];
