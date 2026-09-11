import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes/route_names.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_colors.dart';
import '../admin/notification_management_screen.dart';
import '../admin/order_management_screen.dart';
import '../admin/patient_management_screen.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/widgets/role_guard.dart';
import '../chatbot/chatbot_screen.dart';
import '../optician/optician_appointment_management_screen.dart';
import '../reception/reception_screen.dart';

class ReceptionDashboard extends StatefulWidget {
  const ReceptionDashboard({super.key});

  @override
  State<ReceptionDashboard> createState() => _ReceptionDashboardState();
}

class _ReceptionDashboardState extends State<ReceptionDashboard> {
  late Future<_ReceptionData> _data;
  bool _sidebarExpanded = false;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<_ReceptionData> _loadData() async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore.collection(FirebaseConstants.appointmentsCollection).get(),
      firestore.collection(FirebaseConstants.usersCollection).get(),
      firestore.collection(FirebaseConstants.ordersCollection).get(),
      firestore.collection(FirebaseConstants.notificationsCollection).get(),
    ]);
    final now = DateTime.now();
    final appointments = results[0].docs;
    final today = appointments.where((doc) {
      final value = doc.data()['date'];
      if (value is! Timestamp) return false;
      final date = value.toDate();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();
    final waiting = today.where((doc) {
      final status = (doc.data()['status'] ?? doc.data()['statut'] ?? '')
          .toString()
          .toLowerCase();
      return status == 'arrivé' ||
          status == 'arrive' ||
          status == 'en attente' ||
          status == 'waiting';
    }).length;
    final patients = results[1].docs
        .where(
          (doc) =>
              (doc.data()['role']?.toString().toLowerCase() ?? 'patient') ==
              'patient',
        )
        .length;
    final patientNames = <String, String>{
      for (final doc in results[1].docs)
        doc.id: '${doc.data()['prenom'] ?? ''} ${doc.data()['nom'] ?? ''}'
            .trim(),
    };
    final ordersInProgress = results[2].docs
        .where(
          (doc) =>
              (doc.data()['status']?.toString().toLowerCase() ?? 'pending') !=
              'completed',
        )
        .length;
    return _ReceptionData(
      todayAppointments: today.length,
      todayItems: today
          .map(
            (doc) => _ReceptionAppointment(
              time: (doc.data()['date'] as Timestamp).toDate(),
              patientName:
                  patientNames[doc.data()['patientId']?.toString() ?? ''] ??
                  'Patient',
              reason: doc.data()['reason']?.toString() ?? 'Consultation',
              status:
                  doc.data()['status']?.toString() ??
                  doc.data()['statut']?.toString() ??
                  'En attente',
            ),
          )
          .toList(),
      waitingPatients: waiting,
      patients: patients,
      ordersInProgress: ordersInProgress,
      notifications: results[3].docs.length,
    );
  }

  void _refresh() => setState(() => _data = _loadData());

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().userProfile;
    return RoleGuard(
      allowedRoles: const [UserRole.receptionist],
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.22),
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
                          'Réceptionniste',
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
                          'Accueil et suivi administratif',
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
        body: FutureBuilder<_ReceptionData>(
          future: _data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            return Stack(
              children: [
                Positioned.fill(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                    children: [
                      _ReceptionHeader(
                        profile: profile,
                        onToggleMenu: () => setState(
                          () => _sidebarExpanded = !_sidebarExpanded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ReceptionActionGrid(onOpen: _open),
                      const SizedBox(height: 22),
                      _DaySchedule(data: data),
                      const SizedBox(height: 16),
                      _ReceptionStatusStrip(data: data, onOpen: _open),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: _ReceptionSidebar(
                    expanded: _sidebarExpanded,
                    onToggleMenu: () =>
                        setState(() => _sidebarExpanded = !_sidebarExpanded),
                    onPatients: () => _open(const PatientManagementScreen()),
                    onAppointments: () =>
                        _open(const OpticianAppointmentManagementScreen()),
                    onReception: () => _open(const ReceptionScreen()),
                    onOrders: () => _open(const OrderManagementScreen()),
                    onNotifications: () =>
                        _open(const NotificationManagementScreen()),
                    onChatbot: () => _open(const ChatbotScreen()),
                    onRefresh: _refresh,
                    onLogout: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.goNamed(RouteNames.login);
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

class _ReceptionData {
  final int todayAppointments;
  final List<_ReceptionAppointment> todayItems;
  final int waitingPatients;
  final int patients;
  final int ordersInProgress;
  final int notifications;
  const _ReceptionData({
    required this.todayAppointments,
    required this.todayItems,
    required this.waitingPatients,
    required this.patients,
    required this.ordersInProgress,
    required this.notifications,
  });
}

class _ReceptionAppointment {
  final DateTime time;
  final String patientName;
  final String reason;
  final String status;

  const _ReceptionAppointment({
    required this.time,
    required this.patientName,
    required this.reason,
    required this.status,
  });
}

class _ReceptionSidebar extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggleMenu;
  final VoidCallback onPatients;
  final VoidCallback onAppointments;
  final VoidCallback onReception;
  final VoidCallback onOrders;
  final VoidCallback onNotifications;
  final VoidCallback onChatbot;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _ReceptionSidebar({
    required this.expanded,
    required this.onToggleMenu,
    required this.onPatients,
    required this.onAppointments,
    required this.onReception,
    required this.onOrders,
    required this.onNotifications,
    required this.onChatbot,
    required this.onRefresh,
    required this.onLogout,
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
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withValues(alpha: 0.22),
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
                  if (expanded)
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
                              title: 'Patients',
                              description:
                                  'Consulter et gérer les dossiers patients',
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
                              icon: Icons.how_to_reg_outlined,
                              title: 'Accueil patient',
                              description: 'Valider les arrivées et l’accueil',
                              onTap: onReception,
                            ),
                            _SidebarEntry(
                              icon: Icons.shopping_bag_outlined,
                              title: 'Commandes',
                              description:
                                  'Suivre les commandes et les factures',
                              onTap: onOrders,
                            ),
                            _SidebarEntry(
                              icon: Icons.notifications_active_outlined,
                              title: 'Notifications',
                              description: 'Consulter les messages et alertes',
                              onTap: onNotifications,
                            ),
                            _SidebarEntry(
                              icon: Icons.smart_toy_outlined,
                              title: 'Chatbot',
                              description: 'Accéder au support conversationnel',
                              onTap: onChatbot,
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.18),
                              indent: 12,
                              endIndent: 12,
                            ),
                            const SizedBox(height: 8),
                            _SidebarEntry(
                              icon: Icons.refresh_rounded,
                              title: 'Actualiser',
                              description:
                                  'Mettre à jour les informations du dashboard',
                              onTap: onRefresh,
                            ),
                            _SidebarEntry(
                              icon: Icons.logout_rounded,
                              title: 'Déconnexion',
                              description: 'Quitter la session réceptionniste',
                              onTap: onLogout,
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _ReceptionHeader extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onToggleMenu;

  const _ReceptionHeader({required this.profile, required this.onToggleMenu});

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
              'Bonjour, ${profile?.prenom ?? 'Réceptionniste'} 👋',
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
              'Voici un aperçu rapide de l’accueil et du suivi du jour.',
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
    ],
  );
}

class _ReceptionActionGrid extends StatelessWidget {
  final Future<void> Function(Widget) onOpen;
  const _ReceptionActionGrid({required this.onOpen});

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.2,
    children: [
      _ReceptionAction(
        'Nouveau patient',
        'Enregistrer',
        Icons.people_alt_outlined,
        const Color(0xFFEAF1FF),
        AppColors.primary,
        () => onOpen(const PatientManagementScreen()),
      ),
      _ReceptionAction(
        'Nouveau rendez-vous',
        'Programmer',
        Icons.calendar_month_outlined,
        const Color(0xFFFFE8E8),
        AppColors.secondary,
        () => onOpen(const OpticianAppointmentManagementScreen()),
      ),
      _ReceptionAction(
        'Accueil patient',
        'Enregistrer arrivée',
        Icons.how_to_reg_outlined,
        const Color(0xFFE9F8F0),
        AppColors.success,
        () => onOpen(const ReceptionScreen()),
      ),
      _ReceptionAction(
        'Factures',
        'Historique',
        Icons.receipt_long_outlined,
        const Color(0xFFFFF1DF),
        const Color(0xFFE88716),
        () => onOpen(const OrderManagementScreen()),
      ),
    ],
  );
}

class _ReceptionAction extends StatelessWidget {
  final String title;
  final String caption;
  final IconData icon;
  final Color background;
  final Color color;
  final VoidCallback onTap;
  const _ReceptionAction(
    this.title,
    this.caption,
    this.icon,
    this.background,
    this.color,
    this.onTap,
  );

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          Text(
            caption,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DaySchedule extends StatelessWidget {
  final _ReceptionData data;
  const _DaySchedule({required this.data});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Rendez-vous du jour',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          Text(
            '${data.todayAppointments} au total',
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      if (data.todayItems.isEmpty)
        const _ScheduleEmpty()
      else
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: data.todayItems
                .take(6)
                .map((item) => _ScheduleRow(item: item))
                .toList(),
          ),
        ),
    ],
  );
}

class _ScheduleRow extends StatelessWidget {
  final _ReceptionAppointment item;
  const _ScheduleRow({required this.item});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFE9EDF4))),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
        Container(width: 1, height: 34, color: AppColors.border),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.patientName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.reason,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        _StatusBadge(item.status),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);
  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final done = normalized.contains('confirm') || normalized.contains('pris');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: (done ? AppColors.success : const Color(0xFFE88716)).withAlpha(
          24,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: done ? AppColors.success : const Color(0xFFE88716),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScheduleEmpty extends StatelessWidget {
  const _ScheduleEmpty();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: const Text(
      'Aucun rendez-vous prévu aujourd’hui.',
      style: TextStyle(color: AppColors.textSecondary),
    ),
  );
}

class _ReceptionStatusStrip extends StatelessWidget {
  final _ReceptionData data;
  final Future<void> Function(Widget) onOpen;
  const _ReceptionStatusStrip({required this.data, required this.onOpen});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1F1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFF4CACA)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.notifications_active_outlined,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '${data.waitingPatients} patient${data.waitingPatients > 1 ? 's' : ''} en attente • ${data.ordersInProgress} commande${data.ordersInProgress > 1 ? 's' : ''} en cours',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
        TextButton(
          onPressed: () => onOpen(const NotificationManagementScreen()),
          child: const Text('Gérer'),
        ),
      ],
    ),
  );
}
