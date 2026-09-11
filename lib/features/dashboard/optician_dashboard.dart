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
  bool _sidebarExpanded = false;

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
        backgroundColor: const Color(0xFFF4F7FB),
        body: Stack(
          children: [
            Positioned.fill(
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
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                      children: [
                        _WelcomeHeader(
                          profile: profile,
                          onToggleMenu: () => setState(
                            () => _sidebarExpanded = !_sidebarExpanded,
                          ),
                        ),
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
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _OpticianSidebar(
                expanded: _sidebarExpanded,
                onToggleMenu: () =>
                    setState(() => _sidebarExpanded = !_sidebarExpanded),
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
                onChatbot: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                ),
                onLogout: _loggingOut ? null : _logout,
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
  final bool expanded;
  final VoidCallback onToggleMenu;
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
    required this.expanded,
    required this.onToggleMenu,
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final expandedWidth = (availableWidth * 0.58).clamp(160.0, 270.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          width: expanded ? expandedWidth : 0.0,
          decoration: BoxDecoration(
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: SafeArea(
            top: true,
            bottom: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: expanded ? 12 : 0,
                    ),
                    child: _SidebarIcon(
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
                              title: 'Patients',
                              description: 'Consulter et suivre les dossiers',
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
                              title: 'Consultations',
                              description: 'Gérer les échanges et suivis',
                              onTap: onConsultation,
                            ),
                            _SidebarEntry(
                              icon: Icons.visibility_outlined,
                              title: 'Examens',
                              description: 'Suivre les examens de vue',
                              onTap: onExamination,
                            ),
                            _SidebarEntry(
                              icon: Icons.description_outlined,
                              title: 'Ordonnances',
                              description:
                                  'Consulter et éditer les prescriptions',
                              onTap: onPrescriptions,
                            ),
                            _SidebarEntry(
                              icon: Icons.inventory_2_outlined,
                              title: 'Équipements',
                              description: 'Gérer les stocks et matériels',
                              onTap: onEquipment,
                            ),
                            _SidebarEntry(
                              icon: Icons.build_circle_outlined,
                              title: 'Fabrications',
                              description:
                                  'Suivre les commandes et préparations',
                              onTap: onOrders,
                            ),
                            _SidebarEntry(
                              icon: Icons.chat_bubble_outline,
                              title: 'Chatbot',
                              description:
                                  'Accéder au support et à l’assistance',
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
                              description: refreshing
                                  ? 'Mise à jour en cours...'
                                  : 'Rafraîchir les données du tableau',
                              onTap: onRefresh ?? () {},
                            ),
                            _SidebarEntry(
                              icon: Icons.logout_rounded,
                              title: 'Déconnexion',
                              description: 'Quitter la session opticien',
                              onTap: onLogout ?? () {},
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

class _SidebarIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final String? label;

  const _SidebarIcon({
    required this.icon,
    this.selected = false,
    this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, color: Colors.white, size: 22);

    if (label == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: IconButton(
          onPressed: onTap,
          tooltip: 'Navigation',
          style: IconButton.styleFrom(
            backgroundColor: selected
                ? Colors.white.withAlpha(45)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: iconWidget,
        ),
      );
    }

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              iconWidget,
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
          ),
        ),
      ),
    );
  }
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

class _WelcomeHeader extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onToggleMenu;

  const _WelcomeHeader({required this.profile, required this.onToggleMenu});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE3EAF4)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x140A3D91),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
            style: TextStyle(color: Colors.black87, height: 1.35),
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
          style: const TextStyle(fontSize: 11, color: Colors.black87),
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
                style: const TextStyle(color: Colors.black87, fontSize: 12),
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
          child: Text(text, style: const TextStyle(color: Colors.black87)),
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
