import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _statusFilter = 'Toutes';

  CollectionReference<Map<String, dynamic>> get _orders =>
      FirebaseFirestore.instance.collection(FirebaseConstants.ordersCollection);

  late Future<Map<String, String>> _patientNames;

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

  Future<void> _updateStatus(
    QueryDocumentSnapshot<Map<String, dynamic>> order,
    String status,
  ) async {
    try {
      await order.reference.update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statut de la commande mis à jour.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mise à jour impossible : $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Gérer les commandes',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1764C0)],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _orders.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _MessagePanel(
              icon: Icons.error_outline,
              text: 'Impossible de charger les commandes.',
              detail: snapshot.error.toString(),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return FutureBuilder<Map<String, String>>(
            future: _patientNames,
            builder: (context, namesSnapshot) {
              final names = namesSnapshot.data ?? const <String, String>{};
              final all = snapshot.data!.docs;
              final filtered = all.where((order) {
                final data = order.data();
                final status = _statusOf(data);
                final patient =
                    names[data['patientId']?.toString() ?? ''] ?? '';
                final searchable =
                    '${order.id} $patient ${data['description'] ?? ''}'
                        .toLowerCase();
                return (_statusFilter == 'Toutes' || status == _statusFilter) &&
                    (_search.isEmpty || searchable.contains(_search));
              }).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _OrdersHeader(total: all.length),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une commande ou un patient',
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
                  _StatusFilters(
                    selected: _statusFilter,
                    onChanged: (value) => setState(() => _statusFilter = value),
                  ),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    const _MessagePanel(
                      icon: Icons.shopping_bag_outlined,
                      text: 'Aucune commande trouvée.',
                    )
                  else
                    ...filtered.map(
                      (order) => _OrderCard(
                        order: order,
                        patientName:
                            names[order.data()['patientId']?.toString() ??
                                ''] ??
                            'Patient',
                        onStatusChanged: (status) =>
                            _updateStatus(order, status),
                        onDetails: () => _showDetails(order, names),
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
    QueryDocumentSnapshot<Map<String, dynamic>> order,
    Map<String, String> names,
  ) async {
    final data = order.data();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OrderDetails(
        order: order,
        patientName: names[data['patientId']?.toString() ?? ''] ?? 'Patient',
        onStatusChanged: (status) => _updateStatus(order, status),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  final int total;
  const _OrdersHeader({required this.total});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, Color(0xFF174F9B)],
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
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commandes GAV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Suivez les commandes et leur progression.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white24,
          child: Text(
            '$total',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
      ],
    ),
  );
}

class _StatusFilters extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _StatusFilters({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: ['Toutes', 'pending', 'processing', 'completed', 'cancelled']
          .map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_statusLabel(status)),
                selected: selected == status,
                onSelected: (_) => onChanged(status),
                selectedColor: AppColors.primary,
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

class _OrderCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> order;
  final String patientName;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDetails;
  const _OrderCard({
    required this.order,
    required this.patientName,
    required this.onStatusChanged,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final data = order.data();
    final status = _statusOf(data);
    final amount = _number(data['totalAmount'] ?? data['total']);
    final date = _dateOf(data['createdAt'] ?? data['date']);
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
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase()}',
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
                '${amount.toStringAsFixed(0)} FCFA',
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
              _StatusBadge(status: status),
              PopupMenuButton<String>(
                tooltip: 'Modifier le statut',
                onSelected: onStatusChanged,
                itemBuilder: (_) =>
                    ['pending', 'processing', 'completed', 'cancelled']
                        .map(
                          (value) => PopupMenuItem(
                            value: value,
                            child: Text(_statusLabel(value)),
                          ),
                        )
                        .toList(),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onDetails,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Voir les détails'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> order;
  final String patientName;
  final ValueChanged<String> onStatusChanged;
  const _OrderDetails({
    required this.order,
    required this.patientName,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final data = order.data();
    final items =
        (data['items'] as List?)?.whereType<Map>().toList() ?? const [];
    final status = _statusOf(data);
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
                'Détail de la commande',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '#${order.id}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              _DetailLine(label: 'Patient', value: patientName),
              _DetailLine(label: 'Statut', value: _statusLabel(status)),
              _DetailLine(
                label: 'Paiement',
                value: _statusLabel(
                  data['paymentStatus']?.toString() ??
                      data['paiementStatus']?.toString() ??
                      'pending',
                ),
              ),
              _DetailLine(
                label: 'Méthode',
                value: data['paymentMethod']?.toString() ?? 'Non renseignée',
              ),
              const Divider(height: 26),
              const Text(
                'Articles',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty) const Text('Aucun article détaillé.'),
              ...items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item['productName']?.toString() ?? 'Produit'),
                  subtitle: Text('Quantité : ${item['quantity'] ?? 1}'),
                  trailing: Text(
                    '${_number(item['price']).toStringAsFixed(0)} FCFA',
                  ),
                ),
              ),
              const Divider(height: 22),
              _DetailLine(
                label: 'Total',
                value:
                    '${_number(data['totalAmount'] ?? data['total']).toStringAsFixed(0)} FCFA',
                bold: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    [
                      'pending',
                      'processing',
                      'completed',
                      'cancelled',
                    ].contains(status)
                    ? status
                    : 'pending',
                decoration: const InputDecoration(
                  labelText: 'Modifier le statut',
                ),
                items: ['pending', 'processing', 'completed', 'cancelled']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(_statusLabel(value)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onStatusChanged(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _DetailLine({
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

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

class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? detail;
  const _MessagePanel({required this.icon, required this.text, this.detail});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 42),
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
    case 'processing':
      return 'En préparation';
    case 'completed':
      return 'Terminée';
    case 'cancelled':
      return 'Annulée';
    case 'paid':
      return 'Payé';
    case 'failed':
      return 'Échec';
    default:
      return status == 'Toutes' ? 'Toutes' : 'En attente';
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'processing':
      return const Color(0xFFE08A00);
    case 'completed':
    case 'paid':
      return AppColors.success;
    case 'cancelled':
    case 'failed':
      return AppColors.secondary;
    default:
      return AppColors.primary;
  }
}
