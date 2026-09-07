import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

const _paymentAccent = AppColors.secondary;

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _statusFilter = 'Toutes';
  late Future<Map<String, String>> _patientNames;

  CollectionReference<Map<String, dynamic>> get _payments => FirebaseFirestore
      .instance
      .collection(FirebaseConstants.paymentsCollection);

  @override
  void initState() {
    super.initState();
    _patientNames = _loadPatientNames();
    _searchController.addListener(
      () =>
          setState(() => _search = _searchController.text.trim().toLowerCase()),
    );
  }

  Future<Map<String, String>> _loadPatientNames() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .get();
    return {
      for (final doc in snapshot.docs)
        doc.id: '${doc.data()['prenom'] ?? ''} ${doc.data()['nom'] ?? ''}'
            .trim(),
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Gérer les paiements',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _paymentAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_paymentAccent, Color(0xFFAA1F27)],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _payments.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _PaymentMessage(
              icon: Icons.error_outline,
              text: 'Impossible de charger les paiements.',
              detail: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          return FutureBuilder<Map<String, String>>(
            future: _patientNames,
            builder: (context, namesSnapshot) {
              final names = namesSnapshot.data ?? const <String, String>{};
              final all = [...snapshot.data!.docs]
                ..sort((a, b) {
                  final first = _dateOf(
                    a.data()['date'] ?? a.data()['createdAt'],
                  );
                  final second = _dateOf(
                    b.data()['date'] ?? b.data()['createdAt'],
                  );
                  return (second ?? DateTime(1970)).compareTo(
                    first ?? DateTime(1970),
                  );
                });
              final filtered = all.where((payment) {
                final data = payment.data();
                final status = _statusOf(data);
                final patient =
                    names[data['patientId']?.toString() ?? ''] ?? '';
                final searchable =
                    '${payment.id} $patient ${data['orderId'] ?? ''} ${data['description'] ?? ''}'
                        .toLowerCase();
                return (_statusFilter == 'Toutes' || status == _statusFilter) &&
                    (_search.isEmpty || searchable.contains(_search));
              }).toList();
              final paid = all
                  .where((doc) => _statusOf(doc.data()) == 'paid')
                  .length;
              final total = all.fold<double>(
                0,
                (sum, doc) => sum + _number(doc.data()['amount']),
              );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _PaymentsHeader(total: total, count: all.length, paid: paid),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          'Rechercher une transaction, commande ou patient',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.clear),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PaymentFilters(
                    selected: _statusFilter,
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const _PaymentMessage(
                      icon: Icons.payments_outlined,
                      text: 'Aucun paiement trouvé.',
                    )
                  else
                    ...filtered.map(
                      (payment) => _PaymentCard(
                        payment: payment,
                        patientName:
                            names[payment.data()['patientId']?.toString() ??
                                ''] ??
                            'Patient',
                        onDetails: () => _showDetails(payment, names),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> payment,
    Map<String, String> names,
  ) async {
    final data = payment.data();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PaymentDetails(
        payment: payment,
        patientName: names[data['patientId']?.toString() ?? ''] ?? 'Patient',
      ),
    );
  }
}

class _PaymentsHeader extends StatelessWidget {
  final double total;
  final int count;
  final int paid;
  const _PaymentsHeader({
    required this.total,
    required this.count,
    required this.paid,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_paymentAccent, Color(0xFF9D1C24)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x260A3D91),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paiements GAV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Consultez les transactions et leur état.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.payments_outlined, color: Colors.white, size: 34),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _HeaderMetric(label: 'Transactions', value: '$count'),
            _HeaderMetric(label: 'Payés', value: '$paid'),
            _HeaderMetric(
              label: 'Montant',
              value: '${total.toStringAsFixed(0)} FCFA',
            ),
          ],
        ),
      ],
    ),
  );
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );
}

class _PaymentFilters extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _PaymentFilters({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: ['Toutes', 'paid', 'pending', 'failed', 'refunded']
          .map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_statusLabel(status)),
                selected: selected == status,
                onSelected: (_) => onChanged(status),
                selectedColor: _paymentAccent,
                labelStyle: TextStyle(
                  color: selected == status
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> payment;
  final String patientName;
  final VoidCallback onDetails;
  const _PaymentCard({
    required this.payment,
    required this.patientName,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final data = payment.data();
    final status = _statusOf(data);
    final date = _dateOf(data['date'] ?? data['createdAt']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1E3A73),
            blurRadius: 9,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: _paymentAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${payment.id.length > 8 ? payment.id.substring(0, 8).toUpperCase() : payment.id.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientName.isEmpty ? 'Patient' : patientName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_number(data['amount']).toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  date == null ? 'Date non renseignée' : _formatDate(date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                _methodLabel(data['paymentMethod']?.toString()),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              _PaymentStatus(status: status),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDetails,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Voir la transaction'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDetails extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> payment;
  final String patientName;
  const _PaymentDetails({required this.payment, required this.patientName});

  @override
  Widget build(BuildContext context) {
    final data = payment.data();
    final details = data['paymentDetails'] is Map
        ? Map<String, dynamic>.from(data['paymentDetails'] as Map)
        : const <String, dynamic>{};
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Informations de la transaction',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                payment.id,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              _PaymentLine(label: 'Patient', value: patientName),
              _PaymentLine(
                label: 'Commande',
                value: data['orderId']?.toString() ?? 'Non renseignée',
              ),
              _PaymentLine(
                label: 'Montant',
                value: '${_number(data['amount']).toStringAsFixed(0)} FCFA',
                bold: true,
              ),
              _PaymentLine(label: 'État', value: _statusLabel(_statusOf(data))),
              _PaymentLine(
                label: 'Méthode',
                value: _methodLabel(data['paymentMethod']?.toString()),
              ),
              _PaymentLine(
                label: 'Date',
                value: _dateOf(data['date'] ?? data['createdAt']) == null
                    ? 'Non renseignée'
                    : _formatDate(_dateOf(data['date'] ?? data['createdAt'])!),
              ),
              const Divider(height: 26),
              const Text(
                'Données de paiement',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _PaymentLine(
                label: 'Carte',
                value: details['cardLast4']?.toString() ?? 'Non renseignée',
              ),
              _PaymentLine(
                label: 'Titulaire',
                value: details['cardHolder']?.toString() ?? 'Non renseigné',
              ),
              _PaymentLine(
                label: 'Description',
                value: data['description']?.toString() ?? 'Paiement',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _PaymentLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PaymentStatus extends StatelessWidget {
  final String status;
  const _PaymentStatus({required this.status});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: _statusColor(status).withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      _statusLabel(status),
      style: TextStyle(
        color: _statusColor(status),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _PaymentMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? detail;
  const _PaymentMessage({required this.icon, required this.text, this.detail});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _paymentAccent, size: 42),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

String _statusOf(Map<String, dynamic> data) =>
    data['status']?.toString() ?? data['statut']?.toString() ?? 'pending';

double _number(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

DateTime? _dateOf(dynamic value) => value is Timestamp
    ? value.toDate()
    : value is DateTime
    ? value
    : null;

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _statusLabel(String status) {
  switch (status) {
    case 'paid':
      return 'Payé';
    case 'failed':
      return 'Échec';
    case 'refunded':
      return 'Remboursé';
    default:
      return status == 'Toutes' ? 'Toutes' : 'En attente';
  }
}

String _methodLabel(String? method) {
  switch (method) {
    case 'card':
      return 'Carte bancaire';
    case 'mobile_money':
      return 'Mobile Money';
    case 'bank_transfer':
      return 'Virement';
    default:
      return method ?? 'Non renseignée';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'paid':
      return AppColors.success;
    case 'failed':
    case 'refunded':
      return AppColors.secondary;
    default:
      return _paymentAccent;
  }
}
