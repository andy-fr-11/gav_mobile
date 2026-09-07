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
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ReceptionRail(
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
            Expanded(
              child: SafeArea(
                top: true,
                bottom: true,
                child: FutureBuilder<_ReceptionData>(
                  future: _data,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final data = snapshot.data!;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                      children: [
                        _ReceptionTopBar(profile: profile),
                        const SizedBox(height: 12),
                        _Welcome(profile: profile),
                        const SizedBox(height: 16),
                        _ReceptionActionGrid(onOpen: _open),
                        const SizedBox(height: 22),
                        _DaySchedule(data: data),
                        const SizedBox(height: 16),
                        _ReceptionStatusStrip(data: data, onOpen: _open),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
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

class _ReceptionRail extends StatelessWidget {
  final VoidCallback onPatients;
  final VoidCallback onAppointments;
  final VoidCallback onReception;
  final VoidCallback onOrders;
  final VoidCallback onNotifications;
  final VoidCallback onChatbot;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const _ReceptionRail({
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
    final viewPadding = MediaQuery.viewPaddingOf(context);
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          SizedBox(height: viewPadding.top),
          Expanded(
            child: Container(
              color: AppColors.secondary,
              padding: EdgeInsets.only(top: 8, bottom: viewPadding.bottom + 8),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const Icon(Icons.menu_rounded, color: Colors.white, size: 25),
                  const SizedBox(height: 22),
                  const _RailIcon(Icons.home_rounded, selected: true),
                  _RailIcon(Icons.people_alt_outlined, onTap: onPatients),
                  _RailIcon(
                    Icons.calendar_month_outlined,
                    onTap: onAppointments,
                  ),
                  _RailIcon(Icons.how_to_reg_outlined, onTap: onReception),
                  _RailIcon(Icons.shopping_bag_outlined, onTap: onOrders),
                  _RailIcon(
                    Icons.notifications_none_outlined,
                    onTap: onNotifications,
                  ),
                  _RailIcon(Icons.smart_toy_outlined, onTap: onChatbot),
                  const Spacer(),
                  _RailIcon(Icons.refresh_rounded, onTap: onRefresh),
                  _RailIcon(Icons.logout_rounded, onTap: onLogout),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  const _RailIcon(this.icon, {this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onTap,
    tooltip: 'Navigation',
    style: IconButton.styleFrom(
      backgroundColor: selected ? Colors.white.withAlpha(38) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    icon: Icon(icon, color: Colors.white, size: 22),
  );
}

class _ReceptionTopBar extends StatelessWidget {
  final dynamic profile;
  const _ReceptionTopBar({required this.profile});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Image.asset(
          'assets/images/logo_gav.png',
          height: 62,
          alignment: Alignment.centerLeft,
        ),
      ),
      IconButton(
        onPressed: () {},
        tooltip: 'Notifications',
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.textPrimary,
          size: 28,
        ),
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

class _Welcome extends StatelessWidget {
  final dynamic profile;
  const _Welcome({required this.profile});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, Color(0xFF1764C0)],
      ),
      borderRadius: BorderRadius.circular(20),
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
        Text(
          'Bonjour ${profile?.prenom ?? ''} ${profile?.nom ?? ''}'.trim(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pilotez l’accueil et le suivi administratif des patients.',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}
