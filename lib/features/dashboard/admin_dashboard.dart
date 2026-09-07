import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes/route_names.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_colors.dart';
import '../admin/patient_management_screen.dart';
import '../admin/personnel_management_screen.dart';
import '../admin/appointment_management_screen.dart';
import '../admin/clinical_management_screen.dart';
import '../admin/chatbot_management_screen.dart';
import '../admin/order_management_screen.dart';
import '../admin/payment_management_screen.dart';
import '../admin/notification_management_screen.dart';
import '../admin/statistics_management_screen.dart';
import '../admin/store_management_screen.dart';
import '../admin/system_settings_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/widgets/role_guard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<_AdminDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<_AdminDashboardData> _loadDashboard() async {
    final firestore = FirebaseFirestore.instance;
    final snapshots = await Future.wait([
      firestore.collection(FirebaseConstants.usersCollection).get(),
      firestore.collection(FirebaseConstants.appointmentsCollection).get(),
      firestore.collection(FirebaseConstants.productsCollection).get(),
      firestore.collection(FirebaseConstants.ordersCollection).get(),
      firestore.collection(FirebaseConstants.paymentsCollection).get(),
    ]);
    final users = snapshots[0];
    final appointments = snapshots[1];
    final products = snapshots[2];
    final orders = snapshots[3];
    final payments = snapshots[4];
    final userNames = <String, String>{};
    for (final user in users.docs) {
      final data = user.data();
      final name = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();
      userNames[user.id] = name.isEmpty ? 'Patient' : name;
    }

    final now = DateTime.now();
    final today =
        appointments.docs.where((doc) {
          final value = doc.data()['date'];
          final date = value is Timestamp ? value.toDate() : null;
          return date != null &&
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList()..sort((first, second) {
          final firstDate = (first.data()['date'] as Timestamp).toDate();
          final secondDate = (second.data()['date'] as Timestamp).toDate();
          return firstDate.compareTo(secondDate);
        });

    return _AdminDashboardData(
      patientCount: users.docs
          .where(
            (doc) =>
                UserRoleHelper.normalize(doc.data()['role']?.toString()) ==
                UserRole.patient,
          )
          .length,
      staffCount: users.docs
          .where(
            (doc) =>
                UserRoleHelper.normalize(doc.data()['role']?.toString()) !=
                UserRole.patient,
          )
          .length,
      appointmentCount: appointments.size,
      productCount: products.size,
      orderCount: orders.size,
      paidOrderCount: orders.docs.where((doc) => _isPaid(doc.data())).length,
      unpaidOrderCount: orders.docs.where((doc) => !_isPaid(doc.data())).length,
      paymentCount: payments.size,
      revenue: orders.docs.where((doc) => _isPaid(doc.data())).fold<double>(0, (
        total,
        doc,
      ) {
        final value = doc.data()['totalAmount'] ?? doc.data()['total'];
        return total + (value is num ? value.toDouble() : 0);
      }),
      todayAppointments: today
          .map(
            (doc) => _AdminAppointment(
              time: _formatTime((doc.data()['date'] as Timestamp).toDate()),
              patientName: userNames[doc.data()['patientId']] ?? 'Patient',
              reason: doc.data()['reason']?.toString() ?? 'Consultation',
              status: doc.data()['status']?.toString() ?? 'Enregistré',
            ),
          )
          .toList(),
      recentActivities: [
        ...orders.docs
            .take(3)
            .map(
              (doc) => _RecentActivity(
                Icons.shopping_bag_outlined,
                'Commande enregistrée',
                doc.data()['status']?.toString() ?? 'Statut non renseigné',
              ),
            ),
        ...appointments.docs
            .take(3)
            .map(
              (doc) => _RecentActivity(
                Icons.event_outlined,
                'Rendez-vous enregistré',
                doc.data()['reason']?.toString() ?? 'Consultation',
              ),
            ),
      ],
    );
  }

  static String _formatTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  void _refresh() => setState(() => _dashboardFuture = _loadDashboard());

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().userProfile;

    return RoleGuard(
      allowedRoles: const [UserRole.admin],
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: AppBar(
          title: const Text('Tableau administrateur'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Se déconnecter',
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) context.goNamed(RouteNames.login);
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: FutureBuilder<_AdminDashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _DashboardError(onRetry: _refresh);
            }

            final data = snapshot.data!;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminSidebar(
                  onLogout: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.goNamed(RouteNames.login);
                  },
                  onPersonnel: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PersonnelManagementScreen(),
                      ),
                    );
                  },
                  onPatients: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PatientManagementScreen(),
                      ),
                    );
                  },
                  onAppointments: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AppointmentManagementScreen(),
                      ),
                    );
                  },
                  onClinical: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ClinicalManagementScreen(),
                      ),
                    );
                  },
                  onStore: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StoreManagementScreen(),
                      ),
                    );
                  },
                  onOrders: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OrderManagementScreen(),
                      ),
                    );
                  },
                  onPayments: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PaymentManagementScreen(),
                      ),
                    );
                  },
                  onNotifications: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationManagementScreen(),
                      ),
                    );
                  },
                  onChatbot: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ChatbotManagementScreen(),
                      ),
                    );
                  },
                  onStatistics: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const StatisticsManagementScreen(),
                      ),
                    );
                  },
                  onSettings: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SystemSettingsScreen(),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                    children: [
                      _AdminHeader(profile: profile, onRefresh: _refresh),
                      const SizedBox(height: 22),
                      _KpiGrid(data: data),
                      const SizedBox(height: 24),
                      _SectionTitle(
                        title: 'Rendez-vous du jour',
                        action: 'Voir tout',
                      ),
                      const SizedBox(height: 10),
                      if (data.todayAppointments.isEmpty)
                        const _EmptyPanel(
                          text: 'Aucun rendez-vous prévu aujourd’hui.',
                        )
                      else
                        _AppointmentTable(
                          appointments: data.todayAppointments.take(5).toList(),
                        ),
                      const SizedBox(height: 24),
                      const _SectionTitle(title: 'Activités récentes'),
                      const SizedBox(height: 10),
                      if (data.recentActivities.isEmpty)
                        const _EmptyPanel(
                          text: 'Aucune activité récente enregistrée.',
                        )
                      else
                        ...data.recentActivities.map(
                          (activity) => _ActivityTile(activity),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

bool _isPaid(Map<String, dynamic> data) {
  final status = (data['paymentStatus'] ?? data['paiementStatus'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  return status == 'paid';
}

class _AdminDashboardData {
  final int patientCount;
  final int staffCount;
  final int appointmentCount;
  final int productCount;
  final int orderCount;
  final int paidOrderCount;
  final int unpaidOrderCount;
  final int paymentCount;
  final double revenue;
  final List<_AdminAppointment> todayAppointments;
  final List<_RecentActivity> recentActivities;

  const _AdminDashboardData({
    required this.patientCount,
    required this.staffCount,
    required this.appointmentCount,
    required this.productCount,
    required this.orderCount,
    required this.paidOrderCount,
    required this.unpaidOrderCount,
    required this.paymentCount,
    required this.revenue,
    required this.todayAppointments,
    required this.recentActivities,
  });
}

class _AdminAppointment {
  final String time;
  final String patientName;
  final String reason;
  final String status;

  const _AdminAppointment({
    required this.time,
    required this.patientName,
    required this.reason,
    required this.status,
  });
}

class _RecentActivity {
  final IconData icon;
  final String title;
  final String detail;

  const _RecentActivity(this.icon, this.title, this.detail);
}

class _KpiGrid extends StatelessWidget {
  final _AdminDashboardData data;

  const _KpiGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final revenue = NumberFormatUtils.currency(data.revenue);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _ReferenceMetric(
          label: 'Patients',
          value: '${data.patientCount}',
          icon: Icons.people_alt_outlined,
          color: AppColors.primary,
        ),
        _ReferenceMetric(
          label: 'Rendez-vous',
          value: '${data.todayAppointments.length}',
          caption: 'Aujourd’hui',
          icon: Icons.calendar_month_outlined,
          color: AppColors.primary,
        ),
        _ReferenceMetric(
          label: 'Consultations',
          value: '${data.appointmentCount}',
          icon: Icons.assignment_outlined,
          color: AppColors.primary,
        ),
        _ReferenceMetric(
          label: 'Commandes',
          value: '${data.orderCount}',
          caption: 'Total',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.primary,
        ),
        _ReferenceMetric(
          label: 'Commandes payées',
          value: '${data.paidOrderCount}',
          caption: 'Réglées',
          icon: Icons.check_circle_outline,
          color: AppColors.success,
        ),
        _ReferenceMetric(
          label: 'Commandes non payées',
          value: '${data.unpaidOrderCount}',
          caption: 'À régler',
          icon: Icons.pending_actions_outlined,
          color: AppColors.secondary,
        ),
        _ReferenceMetric(
          label: "Chiffre d'affaires",
          value: revenue,
          icon: Icons.trending_up_rounded,
          color: AppColors.primary,
        ),
        _ReferenceMetric(
          label: 'Équipements disponibles',
          value: '${data.productCount}',
          caption: 'Dans la boutique',
          icon: Icons.inventory_2_outlined,
          color: AppColors.primary,
        ),
      ],
    );
  }
}

class _ReferenceMetric extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color color;

  const _ReferenceMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.caption,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE3EAF4)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0A3D91),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFFEAF1FF)),
              child: Icon(icon, size: 19, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Color(0xFF163B75),
          ),
        ),
        Text(
          caption ?? 'Données réelles',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _AdminSidebar extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onPersonnel;
  final VoidCallback onPatients;
  final VoidCallback onAppointments;
  final VoidCallback onClinical;
  final VoidCallback onStore;
  final VoidCallback onOrders;
  final VoidCallback onPayments;
  final VoidCallback onNotifications;
  final VoidCallback onChatbot;
  final VoidCallback onStatistics;
  final VoidCallback onSettings;

  const _AdminSidebar({
    required this.onLogout,
    required this.onPersonnel,
    required this.onPatients,
    required this.onAppointments,
    required this.onClinical,
    required this.onStore,
    required this.onOrders,
    required this.onPayments,
    required this.onNotifications,
    required this.onChatbot,
    required this.onStatistics,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    color: const Color(0xFF0B3DDB),
    child: SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
          ),
          const SizedBox(height: 16),
          _SidebarButton(
            icon: Icons.home_rounded,
            selected: true,
            onTap: () {},
          ),
          _SidebarButton(icon: Icons.people_alt_outlined, onTap: onPersonnel),
          _SidebarButton(icon: Icons.person_search_outlined, onTap: onPatients),
          _SidebarButton(
            icon: Icons.calendar_month_outlined,
            onTap: onAppointments,
          ),
          _SidebarButton(icon: Icons.assignment_outlined, onTap: onClinical),
          _SidebarButton(icon: Icons.shopping_bag_outlined, onTap: onOrders),
          _SidebarButton(icon: Icons.payments_outlined, onTap: onPayments),
          _SidebarButton(
            icon: Icons.notifications_active_outlined,
            onTap: onNotifications,
          ),
          _SidebarButton(icon: Icons.smart_toy_outlined, onTap: onChatbot),
          _SidebarButton(icon: Icons.shopping_cart_outlined, onTap: onStore),
          _SidebarButton(icon: Icons.bar_chart_rounded, onTap: onStatistics),
          const Spacer(),
          _SidebarButton(icon: Icons.settings_outlined, onTap: onSettings),
          _SidebarButton(icon: Icons.logout_rounded, onTap: onLogout),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: IconButton(
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: selected
            ? Colors.white.withAlpha(45)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      icon: Icon(icon, color: Colors.white, size: 22),
    ),
  );
}

class _AdminHeader extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onRefresh;

  const _AdminHeader({required this.profile, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${profile?.prenom ?? 'Administrateur'} 👋',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Voici un aperçu de votre activité aujourd’hui.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      Image.asset(
        'assets/images/logo_gav.png',
        width: 66,
        height: 42,
        fit: BoxFit.contain,
      ),
      IconButton(
        onPressed: onRefresh,
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.primary,
        ),
      ),
    ],
  );
}

class _AppointmentTable extends StatelessWidget {
  final List<_AdminAppointment> appointments;

  const _AppointmentTable({required this.appointments});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE3EAF4)),
    ),
    child: Column(
      children: [
        for (var index = 0; index < appointments.length; index++) ...[
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            leading: SizedBox(
              width: 42,
              child: Text(
                appointments[index].time,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF163B75),
                ),
              ),
            ),
            title: Text(
              appointments[index].patientName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              appointments[index].reason,
              style: const TextStyle(fontSize: 11),
            ),
            trailing: _StatusPill(appointments[index].status),
          ),
          if (index != appointments.length - 1)
            const Divider(height: 1, indent: 12, endIndent: 12),
        ],
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill(this.status);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F7EE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status,
      style: const TextStyle(
        fontSize: 10,
        color: Color(0xFF198754),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class NumberFormatUtils {
  static String currency(double value) => '${value.toStringAsFixed(0)} FCFA';
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? action;

  const _SectionTitle({required this.title, this.action});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      if (action != null)
        Text(
          action!,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );
}

class _EmptyPanel extends StatelessWidget {
  final String text;

  const _EmptyPanel({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
  );
}

class _ActivityTile extends StatelessWidget {
  final _RecentActivity activity;

  const _ActivityTile(this.activity);

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(activity.icon, color: AppColors.secondary),
      title: Text(activity.title),
      subtitle: Text(activity.detail),
    ),
  );
}

class _DashboardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 12),
          const Text('Impossible de charger les statistiques.'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    ),
  );
}
