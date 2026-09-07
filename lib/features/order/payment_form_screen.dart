import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/order_model.dart';
import '../../shared/widgets/gav_logo_title.dart';
import '../../providers/order_provider.dart';
import '../../services/payment_service.dart';
import '../order/order_list_screen.dart';

class PaymentFormScreen extends StatefulWidget {
  final dynamic order;

  const PaymentFormScreen({super.key, required this.order});

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  late PageController _pageController;
  String? _selectedPaymentMethod;
  bool _isProcessing = false;

  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _phoneController = TextEditingController();

  late PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _paymentService = PaymentService();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  Future<void> _processPayment() async {
    // Validate form
    if (_selectedPaymentMethod == null) {
      _showErrorDialog('VEUILLEZ SÉLECTIONNER UN MOYEN DE PAIEMENT');
      return;
    }

    final paymentDetails = _getPaymentDetails();
    if (paymentDetails.isEmpty) {
      _showErrorDialog('VEUILLEZ VÉRIFIER LES INFORMATIONS SAISIES');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result = await _paymentService.processPayment(
        orderId: widget.order.id,
        amount: widget.order.totalAmount,
        paymentMethod: _selectedPaymentMethod!,
        paymentDetails: paymentDetails,
      );

      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (result['success']) {
        // Update order provider with new payment status
        await context.read<OrderProvider>().updateOrderPaymentStatus(
          widget.order.id,
          'paid',
          _selectedPaymentMethod!,
        );

        // Show success and navigate
        _showSuccessDialog(result['message']);
      } else {
        _showErrorDialog(result['message']);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorDialog('Erreur: $error');
    }
  }

  Map<String, String> _getPaymentDetails() {
    if (_selectedPaymentMethod == 'card') {
      if (_cardNumberController.text.length < 13 ||
          _cardHolderController.text.isEmpty ||
          _expiryController.text.isEmpty ||
          _cvvController.text.length < 3) {
        return {};
      }
      return {
        'cardNumber': _cardNumberController.text,
        'cardHolder': _cardHolderController.text,
        'expiry': _expiryController.text,
        'cvv': _cvvController.text,
      };
    } else if (_selectedPaymentMethod == 'mobile_money') {
      if (_phoneController.text.length < 9) {
        return {};
      }
      return {'phone': _phoneController.text};
    } else if (_selectedPaymentMethod == 'bank_transfer') {
      return {'method': 'bank_transfer'};
    }
    return {};
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Icon(
          Icons.check_circle,
          color: Color(0xFF27AE60),
          size: 48,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const OrderListScreen()),
              );
            },
            child: const Text('Voir mes commandes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'fr_FR');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: GavLogoTitle(
          title: 'Paiement',
          titleColor: Colors.white,
          logoSize: 28,
          textSize: 18,
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1976D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0A3D91),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Montant à payer',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currency.format(widget.order.totalAmount),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payment_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Payment method selection
            const Text(
              'Sélectionner le moyen de paiement',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...availablePaymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method.id;
              return GestureDetector(
                onTap: () => _selectPaymentMethod(method.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEAF2FF) : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D0A3D91),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            _getMethodIcon(method.id),
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          method.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 28),

            // Payment details based on selected method
            if (_selectedPaymentMethod == 'card') ...[
              const Text(
                'Informations de la carte',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Numéro de carte',
                  hintText: '0000 0000 0000 0000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _cardNumberController.clear(),
                  ),
                ),
                maxLength: 19,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _cardHolderController,
                decoration: InputDecoration(
                  labelText: 'Titulaire de la carte',
                  hintText: 'Nom Complet',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _cardHolderController.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Expiration',
                        hintText: 'MM/YY',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _expiryController.clear(),
                        ),
                      ),
                      maxLength: 5,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _cvvController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '***',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _cvvController.clear(),
                        ),
                      ),
                      maxLength: 3,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
            ] else if (_selectedPaymentMethod == 'mobile_money') ...[
              const Text(
                'Informations Mobile Money',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: '+237 6XX XXX XXX',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => _phoneController.clear(),
                  ),
                ),
              ),
            ] else if (_selectedPaymentMethod == 'bank_transfer') ...[
              const Text(
                'Virement Bancaire',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27AE60), width: 1),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coordonnées bancaires',
                      style: TextStyle(
                        color: Color(0xFF27AE60),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Les coordonnées de virement seront envoyées par email après confirmation.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'CONFIRMER LE PAIEMENT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Vos données sont sécurisées par chiffrement SSL',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(String methodId) {
    switch (methodId) {
      case 'card':
        return Icons.credit_card_outlined;
      case 'mobile_money':
        return Icons.phone_android_outlined;
      case 'bank_transfer':
        return Icons.account_balance_outlined;
      default:
        return Icons.payment_outlined;
    }
  }
}
