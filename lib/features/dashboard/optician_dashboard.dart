import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/routes/route_names.dart';
import '../../core/constants/firebase_constants.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_colors.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/widgets/role_guard.dart';
import '../consultation/consultation_screen.dart';
import '../admin/order_management_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../optician/optician_appointment_management_screen.dart';
import '../optician/optician_equipment_screen.dart';
import '../optician/optician_examination_screen.dart';
import '../optician/optician_patient_records_screen.dart';
import '../optician/optician_prescription_screen.dart';

class OpticianDashboard extends StatefulWidget {
  const OpticianDashboard({super.key});

  @override
  State<OpticianDashboard> createState() => _OpticianDashboardState();
}

class _OpticianDashboardState extends State<OpticianDashboard> {
  late Future<_OpticianData> _data;
  bool _refreshing = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _data = _loadData();
  }

  Future<_OpticianData> _loadData() async {
    final uid = context.read<AuthProvider>().userProfile?.uid;
    final firestore = FirebaseFirestore.instance;
    final snapshots = await Future.wait([
      firestore.collection(FirebaseConstants.appointmentsCollection).get(),
      firestore.collection(FirebaseConstants.examinationsCollection).get(),
      firestore.collection(FirebaseConstants.ordersCollection).get(),
      firestore.collection(FirebaseConstants.prescriptionsCollection).get(),
      firestore.collection(FirebaseConstants.usersCollection).get(),
      firestore.collection(FirebaseConstants.consultationsCollection).get(),
    ]);

    final patientNames = <String, String>{
      for (final doc in snapshots[4].docs)
        doc.id: '${doc.data()['prenom'] ?? ''} ${doc.data()['nom'] ?? ''}'
            .trim(),
    };
    final appointments = snapshots[0].docs
        .where((doc) => _belongsToOptician(doc.data(), uid))
        .toList();
    final examinations = snapshots[1].docs
        .where((doc) => _belongsToOptician(doc.data(), uid))
        .toList();
    final orders = snapshots[2].docs
        .where((doc) => _needsOptician(doc.data(), uid))
        .toList();
    final prescriptions = snapshots[3].docs
        .where((doc) => _belongsToOptician(doc.data(), uid))
        .toList();
    final consultations = snapshots[5].docs
        .where((doc) => _belongsToOptician(doc.data(), uid))
        .toList();
    final now = DateTime.now();
    final today =
        appointments.where((doc) {
          final date = _dateOf(doc.data());
          return date != null &&
              date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList()..sort(
          (a, b) =>
              (_dateOf(a.data()) ?? now).compareTo(_dateOf(b.data()) ?? now),
        );

    return _OpticianData(
      todayAppointments: today.take(5).toList(),
      appointmentCount: appointments.length,
      consultationCount: consultations.length,
      examinationCount: examinations.length,
      orderCount: orders.length,
      prescriptionCount: prescriptions.length,
      patientNames: patientNames,
      pendingOrders: orders.take(5).toList(),
    );
  }

  Future<void> _refresh() async {
    if (_refreshing || !mounted) return;
    setState(() => _refreshing = true);
    try {
      final data = _loadData();
      setState(() => _data = data);
      await data;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tableau de bord actualisé.')),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Optician dashboard refresh failed: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Actualisation impossible : ${_friendlyError(error)}',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await context.read<AuthProvider>().logout();
      if (mounted) context.goNamed(RouteNames.login);
    } catch (_) {
      if (mounted) {
        setState(() => _loggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Déconnexion impossible. Réessayez.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().userProfile;
    return RoleGuard(
      allowedRoles: const [UserRole.optician],
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OpticianSidebar(
              onRefresh: _refreshing ? null : _refresh,
              refreshing: _refreshing,
              onPatients: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OpticianPatientRecordsScreen(),
                ),
              ),
              onAppointments: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OpticianAppointmentManagementScreen(),
                ),
              ),
              onConsultation: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConsultationScreen()),
              ),
              onExamination: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OpticianExaminationScreen(),
                ),
              ),
              onPrescriptions: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OpticianPrescriptionScreen(),
                ),
              ),
              onEquipment: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OpticianEquipmentScreen(),
                ),
              ),
              onOrders: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const OrderManagementScreen(),
                ),
              ),
              onChatbot: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ChatbotScreen())),
              onLogout: _loggingOut ? null : _logout,
            ),
            Expanded(
              child: SafeArea(
                top: true,
                bottom: true,
                child: FutureBuilder<_OpticianData>(
                  future: _data,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _DashboardError(
                        error: snapshot.error.toString(),
                        onRetry: _refresh,
                      );
                    }
                    final data = snapshot.data!;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
                      children: [
                        _WelcomeHeader(profile: profile),
                        const SizedBox(height: 16),
                        _SummaryGrid(data: data),
                        const SizedBox(height: 22),
                        _SectionHeader(
                          title: 'Prochains rendez-vous',
                          icon: Icons.calendar_month_outlined,
                        ),
                        const SizedBox(height: 10),
                        if (data.todayAppointments.isEmpty)
                          const _EmptyPanel(
                            text: 'Aucun rendez-vous prévu aujourd’hui.',
                          )
                        else
                          ...data.todayAppointments.map(
                            (doc) => _AppointmentTile(
                              doc: doc,
                              patientName:
                                  data.patientNames[doc
                                      .data()['patientId']
                                      ?.toString()] ??
                                  'Patient',
                            ),
                          ),
                        const SizedBox(height: 22),
                        _SectionHeader(
                          title: 'Fabrications à suivre',
                          icon: Icons.build_outlined,
                        ),
                        const SizedBox(height: 10),
                        if (data.pendingOrders.isEmpty)
                          const _EmptyPanel(
                            text:
                                'Aucune fabrication ne nécessite votre intervention.',
                          )
                        else
                          ...data.pendingOrders.map(
                            (doc) => _ActivityTile(doc: doc),
                          ),
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

String _friendlyError(Object error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'accès Firestore refusé';
      case 'unavailable':
        return 'Firestore est momentanément indisponible';
      case 'network-request-failed':
        return 'connexion réseau indisponible';
    }
    return error.code;
  }
  return error.toString();
}

class _OpticianData {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> todayAppointments;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingOrders;
  final Map<String, String> patientNames;
  final int appointmentCount;
  final int consultationCount;
  final int examinationCount;
  final int orderCount;
  final int prescriptionCount;

  const _OpticianData({
    required this.todayAppointments,
    required this.pendingOrders,
    required this.patientNames,
    required this.appointmentCount,
    required this.consultationCount,
    required this.examinationCount,
    required this.orderCount,
    required this.prescriptionCount,
  });
}

class _OpticianSidebar extends StatelessWidget {
  final VoidCallback? onRefresh;
  final bool refreshing;
  final VoidCallback onPatients;
  final VoidCallback onAppointments;
  final VoidCallback onConsultation;
  final VoidCallback onExamination;
  final VoidCallback onPrescriptions;
  final VoidCallback onEquipment;
  final VoidCallback onOrders;
  final VoidCallback onChatbot;
  final VoidCallback? onLogout;

  const _OpticianSidebar({
    required this.onRefresh,
    this.refreshing = false,
    required this.onPatients,
    required this.onAppointments,
    required this.onConsultation,
    required this.onExamination,
    required this.onPrescriptions,
    required this.onEquipment,
    required this.onOrders,
    required this.onChatbot,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    top: true,
    bottom: true,
    child: Container(
      width: 58,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
          const SizedBox(height: 22),
          _SidebarIcon(icon: Icons.home_rounded, selected: true),
          _SidebarIcon(icon: Icons.people_alt_outlined, onTap: onPatients),
          _SidebarIcon(
            icon: Icons.calendar_month_outlined,
            onTap: onAppointments,
          ),
          _SidebarIcon(icon: Icons.assignment_outlined, onTap: onConsultation),
          _SidebarIcon(icon: Icons.visibility_outlined, onTap: onExamination),
          _SidebarIcon(
            icon: Icons.description_outlined,
            onTap: onPrescriptions,
          ),
          _SidebarIcon(icon: Icons.inventory_2_outlined, onTap: onEquipment),
          _SidebarIcon(icon: Icons.build_circle_outlined, onTap: onOrders),
          _SidebarIcon(icon: Icons.chat_bubble_outline, onTap: onChatbot),
          const Spacer(),
          _SidebarIcon(
            icon: Icons.refresh_rounded,
            onTap: onRefresh,
            loading: refreshing,
          ),
          _SidebarIcon(icon: Icons.logout_rounded, onTap: onLogout),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final bool loading;

  const _SidebarIcon({
    required this.icon,
    this.selected = false,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: IconButton(
      onPressed: onTap,
      tooltip: 'Navigation',
      style: IconButton.styleFrom(
        backgroundColor: selected
            ? Colors.white.withAlpha(45)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, color: Colors.white, size: 22),
    ),
  );
}

class _WelcomeHeader extends StatelessWidget {
  final dynamic profile;
  const _WelcomeHeader({required this.profile});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE3EAF4)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120A3D91),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                height: 62,
                padding: const EdgeInsets.all(4),
                alignment: Alignment.centerLeft,
                child: Image.asset('assets/images/logo_gav.png'),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () {},
                  tooltip: 'Notifications',
                  icon: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 17,
                    height: 17,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          'Bonjour, ${profile?.prenom ?? 'Opticien'} ${profile?.nom ?? ''}'
              .trim(),
          textAlign: TextAlign.left,
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Voici votre planning du jour.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _SummaryGrid extends StatelessWidget {
  final _OpticianData data;
  const _SummaryGrid({required this.data});

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: 1.35,
    children: [
      _SummaryCard(
        label: 'Consultations',
        value: data.consultationCount,
        icon: Icons.people_alt_outlined,
        color: AppColors.primary,
      ),
      _SummaryCard(
        label: 'Examens de vue',
        value: data.examinationCount,
        icon: Icons.visibility_outlined,
        color: AppColors.primary,
      ),
      _SummaryCard(
        label: 'Ordonnances',
        value: data.prescriptionCount,
        icon: Icons.description_outlined,
        color: AppColors.primary,
      ),
      _SummaryCard(
        label: 'Fabrications',
        value: data.orderCount,
        icon: Icons.build_outlined,
        color: AppColors.secondary,
      ),
    ],
  );
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE3EAF4)),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.10),
          blurRadius: 10,
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
          child: Icon(icon, color: color, size: 20),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ],
  );
}

class _AppointmentTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final String patientName;
  const _AppointmentTile({required this.doc, required this.patientName});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final date = _dateOf(data);
    return _DashboardTile(
      icon: Icons.calendar_today_outlined,
      color: AppColors.primary,
      title: patientName,
      subtitle:
          '${_formatTime(date)} - ${data['reason']?.toString() ?? 'Consultation'}',
      trailing: _statusLabel(
        data['status']?.toString() ?? data['statut']?.toString() ?? 'prévu',
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _ActivityTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    return _DashboardTile(
      icon: Icons.build_circle_outlined,
      color: AppColors.secondary,
      title:
          'Commande #${doc.id.length > 7 ? doc.id.substring(0, 7).toUpperCase() : doc.id.toUpperCase()}',
      subtitle:
          data['description']?.toString() ?? 'Équipement optique à préparer',
      trailing: _statusLabel(data['status']?.toString() ?? 'à traiter'),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String trailing;
  const _DashboardTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x100A3D91),
          blurRadius: 9,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            trailing,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
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
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline, color: AppColors.success),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    ),
  );
}

class _DashboardError extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _DashboardError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.secondary, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Impossible de charger le tableau opticien.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            error,
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

bool _belongsToOptician(Map<String, dynamic> data, String? uid) {
  if (uid == null) return false;
  return [
    data['opticianId'],
    data['opticienId'],
    data['assignedTo'],
    data['assignedOpticianId'],
  ].any((value) => value?.toString() == uid);
}

bool _needsOptician(Map<String, dynamic> data, String? uid) {
  final assigned = [
    data['opticianId'],
    data['opticienId'],
    data['assignedTo'],
    data['assignedOpticianId'],
  ];
  final assignedToCurrent =
      uid != null && assigned.any((value) => value?.toString() == uid);
  final status = data['status']?.toString().toLowerCase() ?? '';
  return assignedToCurrent ||
      (assigned.every((value) => value == null || value.toString().isEmpty) &&
          status != 'completed' &&
          status != 'cancelled');
}

DateTime? _dateOf(Map<String, dynamic> data) {
  final value = data['date'] ?? data['scheduledAt'] ?? data['createdAt'];
  return value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : null;
}

String _formatTime(DateTime? date) => date == null
    ? 'Heure non définie'
    : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'En attente';
    case 'processing':
      return 'En préparation';
    case 'completed':
      return 'Terminé';
    case 'cancelled':
      return 'Annulé';
    case 'confirmed':
      return 'Confirmé';
    default:
      return status;
  }
}
