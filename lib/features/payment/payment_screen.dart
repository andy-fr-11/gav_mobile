import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../appointment/appointment_screen.dart';
import '../boutique/boutique_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../dashboard/patient_bottom_navigation_bar.dart';
import '../dashboard/patient_dashboard.dart';
import '../order/order_list_screen.dart';
import '../patient/profile_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PaymentProvider>();
    final count = provider.payments.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: provider.loading && provider.payments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.loadPayments,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(count)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                    sliver: provider.payments.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildPaymentCard(provider.payments[index]),
                              childCount: provider.payments.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: PatientBottomNavigationBar(
        selectedIndex: 0,
        onSelected: _handleNavigation,
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A3D91), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paiements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count paiement${count > 1 ? 's' : ''} disponible${count > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.payments_outlined, color: Colors.white, size: 32),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    final date = payment.date;
    final statusColor = _getStatusColor(payment.status);
    final statusLabel = _getStatusLabel(payment.status);
    final currency = NumberFormat.simpleCurrency(locale: 'fr_FR');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A3D91),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.description ?? 'Paiement',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(payment.amount),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 12),
            Text(
              'Payé le ${date.day}/${date.month}/${date.year}',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
          ],
          if (payment.invoiceUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _openInvoice(payment.invoiceUrl!),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Télécharger facture'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucun paiement disponible',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos paiements apparaîtront ici',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrderListScreen()),
                ),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Effectuer un paiement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    if (normalizedStatus == 'paid' || normalizedStatus == 'completed') {
      return const Color(0xFF27AE60);
    } else if (normalizedStatus == 'pending') {
      return const Color(0xFFF39C12);
    } else if (normalizedStatus == 'failed' ||
        normalizedStatus == 'cancelled') {
      return const Color(0xFFE74C3C);
    }
    return AppColors.mutedText;
  }

  String _getStatusLabel(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    switch (normalizedStatus) {
      case 'paid':
        return 'Payé';
      case 'completed':
        return 'Complété';
      case 'pending':
        return 'En attente';
      case 'failed':
        return 'Échoué';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Future<void> _openInvoice(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir la facture')),
      );
    }
  }

  void _handleNavigation(int index) {
    final screens = [
      const PatientDashboard(),
      const AppointmentScreen(),
      const BoutiqueScreen(),
      const ChatbotScreen(),
      const ProfileScreen(),
    ];

    if (index < screens.length) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => screens[index]));
    }
  }
}
