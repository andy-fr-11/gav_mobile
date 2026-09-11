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
  bool _sidebarExpanded = false;

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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B3DDB),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      tooltip: 'Retour',
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Administrateur',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Panneau de contrôle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          tooltip: 'Actualiser',
                          onPressed: _refresh,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
            return Stack(
              children: [
                Positioned.fill(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                    children: [
                      _AdminHeader(
                        profile: profile,
                        onRefresh: _refresh,
                        onToggleMenu: () => setState(
                          () => _sidebarExpanded = !_sidebarExpanded,
                        ),
                      ),
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
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _AdminSidebar(
                    expanded: _sidebarExpanded,
                    onToggleMenu: () =>
                        setState(() => _sidebarExpanded = !_sidebarExpanded),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;

        if (width >= 1200) {
          crossAxisCount = 4;
          childAspectRatio = 1.45;
        } else if (width >= 900) {
          crossAxisCount = 3;
          childAspectRatio = 1.35;
        } else {
          crossAxisCount = 2;
          childAspectRatio = 1.2;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
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
      },
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
  final bool expanded;
  final VoidCallback onToggleMenu;
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
    required this.expanded,
    required this.onToggleMenu,
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final expandedWidth = (availableWidth * 0.58).clamp(160.0, 270.0);
        final marginLeft = expanded ? 12.0 : 0.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: expanded ? expandedWidth : 0.0,
          margin: EdgeInsets.fromLTRB(marginLeft, 10, 0, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B3DDB),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: expanded ? 12 : 0,
                    ),
                    child: _SidebarButton(
                      icon: Icons.menu_rounded,
                      selected: true,
                      onTap: onToggleMenu,
                      label: expanded ? 'Menu' : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (expanded) ...[
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _SidebarEntry(
                              icon: Icons.home_rounded,
                              title: 'Accueil',
                              description: 'Vue d’ensemble du tableau de bord',
                              onTap: () {},
                            ),
                            _SidebarEntry(
                              icon: Icons.people_alt_outlined,
                              title: 'Personnel',
                              description: 'Gérer les agents et équipes',
                              onTap: onPersonnel,
                            ),
                            _SidebarEntry(
                              icon: Icons.person_search_outlined,
                              title: 'Patients',
                              description: 'Consulter et suivre les patients',
                              onTap: onPatients,
                            ),
                            _SidebarEntry(
                              icon: Icons.calendar_month_outlined,
                              title: 'Rendez-vous',
                              description:
                                  'Planifier et suivre les consultations',
                              onTap: onAppointments,
                            ),
                            _SidebarEntry(
                              icon: Icons.assignment_outlined,
                              title: 'Clinique',
                              description:
                                  'Suivi des dossiers et interventions',
                              onTap: onClinical,
                            ),
                            _SidebarEntry(
                              icon: Icons.shopping_bag_outlined,
                              title: 'Commandes',
                              description: 'Gérer les commandes et livraisons',
                              onTap: onOrders,
                            ),
                            _SidebarEntry(
                              icon: Icons.payments_outlined,
                              title: 'Paiements',
                              description: 'Suivre les paiements et règlements',
                              onTap: onPayments,
                            ),
                            _SidebarEntry(
                              icon: Icons.notifications_active_outlined,
                              title: 'Notifications',
                              description: 'Envoyer et consulter les messages',
                              onTap: onNotifications,
                            ),
                            _SidebarEntry(
                              icon: Icons.smart_toy_outlined,
                              title: 'Chatbot',
                              description: 'Gérer le chatbot et les réponses',
                              onTap: onChatbot,
                            ),
                            _SidebarEntry(
                              icon: Icons.shopping_cart_outlined,
                              title: 'Boutique',
                              description: 'Gestion des produits et stocks',
                              onTap: onStore,
                            ),
                            _SidebarEntry(
                              icon: Icons.bar_chart_rounded,
                              title: 'Statistiques',
                              description:
                                  'Analyser le rendement et les indicateurs',
                              onTap: onStatistics,
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.18),
                              indent: 12,
                              endIndent: 12,
                            ),
                            const SizedBox(height: 8),
                            _SidebarEntry(
                              icon: Icons.settings_outlined,
                              title: 'Paramètres',
                              description:
                                  'Configurer le système et l’application',
                              onTap: onSettings,
                            ),
                            _SidebarEntry(
                              icon: Icons.logout_rounded,
                              title: 'Déconnexion',
                              description: 'Quitter la session administrateur',
                              onTap: onLogout,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  const _SidebarButton({
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    decoration: BoxDecoration(
      color: selected ? Colors.white.withAlpha(45) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: label != null
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (label != null) ...[
              const SizedBox(width: 12),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SidebarEntry extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SidebarEntry({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdminHeader extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onRefresh;
  final VoidCallback onToggleMenu;

  const _AdminHeader({
    required this.profile,
    required this.onRefresh,
    required this.onToggleMenu,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onToggleMenu,
          borderRadius: BorderRadius.circular(12),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${profile?.prenom ?? 'Administrateur'} 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
