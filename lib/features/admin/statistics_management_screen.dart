import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_colors.dart';

const _statisticsAccent = AppColors.secondary;
const _statisticsBlue = AppColors.primary;

class StatisticsManagementScreen extends StatefulWidget {
  const StatisticsManagementScreen({super.key});

  @override
  State<StatisticsManagementScreen> createState() =>
      _StatisticsManagementScreenState();
}

class _StatisticsManagementScreenState
    extends State<StatisticsManagementScreen> {
  late Future<_StatisticsData> _statistics;

  @override
  void initState() {
    super.initState();
    _statistics = _loadStatistics();
  }

  Future<_StatisticsData> _loadStatistics() async {
    final firestore = FirebaseFirestore.instance;
    final snapshots = await Future.wait([
      firestore.collection(FirebaseConstants.usersCollection).get(),
      firestore.collection(FirebaseConstants.appointmentsCollection).get(),
      firestore.collection(FirebaseConstants.ordersCollection).get(),
      firestore.collection(FirebaseConstants.paymentsCollection).get(),
      firestore.collection(FirebaseConstants.productsCollection).get(),
    ]);

    final users = snapshots[0].docs;
    final appointments = snapshots[1].docs;
    final orders = snapshots[2].docs;
    final payments = snapshots[3].docs;
    final products = snapshots[4].docs;
    final now = DateTime.now();
    final monthLabels = List.generate(6, (index) {
      final date = DateTime(now.year, now.month - 5 + index);
      return _MonthStat(_monthName(date.month), date.year, date.month);
    });

    return _StatisticsData(
      patients: users
          .where(
            (doc) =>
                UserRoleHelper.normalize(doc.data()['role']?.toString()) ==
                UserRole.patient,
          )
          .length,
      staff: users
          .where(
            (doc) =>
                UserRoleHelper.normalize(doc.data()['role']?.toString()) !=
                UserRole.patient,
          )
          .length,
      appointments: appointments.length,
      orders: orders.length,
      paidOrders: orders.where((doc) => _isOrderPaid(doc.data())).length,
      unpaidOrders: orders.where((doc) => !_isOrderPaid(doc.data())).length,
      products: products.length,
      revenue: orders
          .where(
            (doc) =>
                (doc.data()['paymentStatus'] ??
                        doc.data()['paiementStatus'] ??
                        '')
                    .toString()
                    .toLowerCase() ==
                'paid',
          )
          .fold<double>(
            0,
            (total, doc) =>
                total +
                _number(doc.data()['totalAmount'] ?? doc.data()['total']),
          ),
      paidRevenue: payments
          .where((doc) => _status(doc.data()) == 'paid')
          .fold<double>(
            0,
            (total, doc) => total + _number(doc.data()['amount']),
          ),
      completedOrders: orders
          .where((doc) => _status(doc.data()) == 'completed')
          .length,
      paidPayments: payments
          .where((doc) => _status(doc.data()) == 'paid')
          .length,
      orderStatuses: _countStatuses(orders),
      paymentStatuses: _countStatuses(payments),
      monthlyOrders: monthLabels
          .map((month) => _countInMonth(orders, month))
          .toList(),
      monthlyPayments: monthLabels
          .map((month) => _amountInMonth(payments, month))
          .toList(),
      months: monthLabels,
    );
  }

  void _refresh() => setState(() => _statistics = _loadStatistics());

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FB),
    appBar: AppBar(
      title: const Text(
        'Statistiques',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: _statisticsAccent,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _refresh,
          tooltip: 'Actualiser',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_statisticsBlue, _statisticsAccent],
          ),
        ),
      ),
    ),
    body: FutureBuilder<_StatisticsData>(
      future: _statistics,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return _StatisticsMessage(
            text: 'Impossible de charger les statistiques.',
            detail: snapshot.error.toString(),
            onRetry: _refresh,
          );
        final data = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
          children: [
            _StatisticsHeader(data: data),
            const SizedBox(height: 18),
            _KpiGrid(data: data),
            const SizedBox(height: 22),
            _Panel(
              title: 'Activité des commandes',
              icon: Icons.shopping_bag_outlined,
              accent: _statisticsBlue,
              child: _MonthlyBars(
                values: data.monthlyOrders
                    .map((value) => value.toDouble())
                    .toList(),
                labels: data.months.map((month) => month.label).toList(),
                color: _statisticsBlue,
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: 'Répartition des commandes',
              icon: Icons.donut_small_outlined,
              accent: _statisticsBlue,
              child: _StatusBars(
                values: data.orderStatuses,
                color: _statisticsBlue,
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: 'État des paiements',
              icon: Icons.payments_outlined,
              accent: _statisticsAccent,
              child: _StatusBars(
                values: data.paymentStatuses,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              title: 'Revenus encaissés par mois',
              icon: Icons.trending_up_rounded,
              accent: _statisticsAccent,
              child: _MonthlyBars(
                values: data.monthlyPayments,
                labels: data.months.map((month) => month.label).toList(),
                color: AppColors.secondary,
                amount: true,
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _StatisticsData {
  final int patients;
  final int staff;
  final int appointments;
  final int orders;
  final int paidOrders;
  final int unpaidOrders;
  final int products;
  final double revenue;
  final double paidRevenue;
  final int completedOrders;
  final int paidPayments;
  final Map<String, int> orderStatuses;
  final Map<String, int> paymentStatuses;
  final List<int> monthlyOrders;
  final List<double> monthlyPayments;
  final List<_MonthStat> months;

  const _StatisticsData({
    required this.patients,
    required this.staff,
    required this.appointments,
    required this.orders,
    required this.paidOrders,
    required this.unpaidOrders,
    required this.products,
    required this.revenue,
    required this.paidRevenue,
    required this.completedOrders,
    required this.paidPayments,
    required this.orderStatuses,
    required this.paymentStatuses,
    required this.monthlyOrders,
    required this.monthlyPayments,
    required this.months,
  });
}

class _MonthStat {
  final String label;
  final int year;
  final int month;
  const _MonthStat(this.label, this.year, this.month);
}

class _StatisticsHeader extends StatelessWidget {
  final _StatisticsData data;
  const _StatisticsHeader({required this.data});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_statisticsBlue, _statisticsAccent],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24D62828),
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
                'Vue d’ensemble',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Les indicateurs réels de l’activité GAV.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Encaissé',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              '${data.paidRevenue.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _KpiGrid extends StatelessWidget {
  final _StatisticsData data;
  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.45,
    children: [
      _Kpi(
        label: 'Patients',
        value: data.patients,
        icon: Icons.people_alt_outlined,
        color: _statisticsBlue,
      ),
      _Kpi(
        label: 'Rendez-vous',
        value: data.appointments,
        icon: Icons.calendar_month_outlined,
        color: _statisticsBlue,
      ),
      _Kpi(
        label: 'Commandes',
        value: data.orders,
        icon: Icons.shopping_bag_outlined,
        color: _statisticsBlue,
      ),
      _Kpi(
        label: 'Paiements réussis',
        value: data.paidPayments,
        icon: Icons.payments_outlined,
        color: AppColors.secondary,
      ),
      _Kpi(
        label: 'Commandes payées',
        value: data.paidOrders,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _Kpi(
        label: 'Commandes non payées',
        value: data.unpaidOrders,
        icon: Icons.pending_actions_outlined,
        color: AppColors.secondary,
      ),
      _Kpi(
        label: 'Personnel',
        value: data.staff,
        icon: Icons.badge_outlined,
        color: _statisticsBlue,
      ),
      _Kpi(
        label: 'Produits',
        value: data.products,
        icon: Icons.inventory_2_outlined,
        color: _statisticsBlue,
      ),
      _Kpi(
        label: 'Commandes terminées',
        value: data.completedOrders,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
      _Kpi(
        label: 'Chiffre d’affaires',
        value: data.revenue.toStringAsFixed(0),
        suffix: ' FCFA',
        icon: Icons.trending_up_rounded,
        color: AppColors.secondary,
      ),
    ],
  );
}

class _Kpi extends StatelessWidget {
  final String label;
  final dynamic value;
  final String suffix;
  final IconData icon;
  final Color color;
  const _Kpi({
    required this.label,
    required this.value,
    this.suffix = '',
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.22)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
        Text(
          '$value$suffix',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;
  const _Panel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120A3D91),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _MonthlyBars extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final bool amount;
  const _MonthlyBars({
    required this.values,
    required this.labels,
    required this.color,
    this.amount = false,
  });

  @override
  Widget build(BuildContext context) {
    final max = values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(values.length, (index) {
          final height = max == 0 ? 4.0 : (values[index] / max) * 112;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                amount
                    ? '${values[index].toStringAsFixed(0)}'
                    : '${values[index].toInt()}',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: height),
                duration: Duration(milliseconds: 500 + index * 80),
                curve: Curves.easeOutCubic,
                builder: (context, animatedHeight, child) => Container(
                  width: 26,
                  height: animatedHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [color, color.withValues(alpha: 0.58)],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[index],
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatusBars extends StatelessWidget {
  final Map<String, int> values;
  final Color color;
  const _StatusBars({required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    final total = values.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0)
      return const Text(
        'Aucune donnée disponible.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    return Column(
      children: values.entries.map((entry) {
        final ratio = entry.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 105,
                child: Text(
                  _label(entry.key),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 10,
                    color: color,
                    backgroundColor: const Color(0xFFE9EEF6),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${entry.value}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StatisticsMessage extends StatelessWidget {
  final String text;
  final String detail;
  final VoidCallback onRetry;
  const _StatisticsMessage({
    required this.text,
    required this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 44,
            color: _statisticsAccent,
          ),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}

String _status(Map<String, dynamic> data) =>
    data['status']?.toString() ?? data['statut']?.toString() ?? 'pending';

bool _isOrderPaid(Map<String, dynamic> data) =>
    (data['paymentStatus'] ?? data['paiementStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase() ==
    'paid';

double _number(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

Map<String, int> _countStatuses(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final counts = <String, int>{};
  for (final doc in docs) {
    final value = _status(doc.data());
    counts[value] = (counts[value] ?? 0) + 1;
  }
  return counts;
}

int _countInMonth(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  _MonthStat month,
) {
  return docs.where((doc) {
    final value = doc.data()['createdAt'] ?? doc.data()['date'];
    if (value is! Timestamp) return false;
    final date = value.toDate();
    return date.year == month.year && date.month == month.month;
  }).length;
}

double _amountInMonth(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  _MonthStat month,
) {
  return docs.fold<double>(0, (total, doc) {
    final value =
        doc.data()['date'] ?? doc.data()['createdAt'] ?? doc.data()['paidAt'];
    if (value is! Timestamp) return total;
    final date = value.toDate();
    return date.year == month.year && date.month == month.month
        ? total + _number(doc.data()['amount'])
        : total;
  });
}

String _monthName(int month) => const [
  'Jan',
  'Fév',
  'Mar',
  'Avr',
  'Mai',
  'Juin',
  'Juil',
  'Août',
  'Sep',
  'Oct',
  'Nov',
  'Déc',
][month - 1];

String _label(String value) {
  switch (value) {
    case 'pending':
      return 'En attente';
    case 'processing':
      return 'En préparation';
    case 'completed':
      return 'Terminées';
    case 'cancelled':
      return 'Annulées';
    case 'paid':
      return 'Payés';
    case 'failed':
      return 'Échecs';
    case 'refunded':
      return 'Remboursés';
    default:
      return value;
  }
}
