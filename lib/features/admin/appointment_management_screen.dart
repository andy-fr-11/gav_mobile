import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  State<AppointmentManagementScreen> createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen> {
  String _filter = 'Tous';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(
    QueryDocumentSnapshot<Map<String, dynamic>> appointment,
    String status,
  ) async {
    await appointment.reference.update({
      'status': status,
      'statut': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final appointments = FirebaseFirestore.instance
        .collection(FirebaseConstants.appointmentsCollection)
        .snapshots();
    final users = FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Gestion des rendez-vous',
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
        stream: appointments,
        builder: (context, appointmentSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: users,
            builder: (context, userSnapshot) {
              if (appointmentSnapshot.hasError || userSnapshot.hasError) {
                return const Center(
                  child: Text('Impossible de charger les rendez-vous.'),
                );
              }
              if (!appointmentSnapshot.hasData || !userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final names = <String, String>{};
              for (final user in userSnapshot.data!.docs) {
                final data = user.data();
                final name = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'
                    .trim();
                names[user.id] = name.isEmpty ? 'Patient' : name;
              }

              final now = DateTime.now();
              final all = appointmentSnapshot.data!.docs;
              final todayCount = all.where((doc) {
                final date = _dateOf(doc);
                return date != null &&
                    date.year == now.year &&
                    date.month == now.month &&
                    date.day == now.day;
              }).length;
              final visible =
                  all.where((doc) {
                    final data = doc.data();
                    final status = _statusOf(data);
                    final date = _dateOf(doc);
                    final patient =
                        names[data['patientId']?.toString()] ?? 'Patient';
                    final searchable = '$patient ${data['reason'] ?? ''}'
                        .toLowerCase();
                    final matchesSearch =
                        _search.isEmpty || searchable.contains(_search);
                    final matchesFilter =
                        _filter == 'Tous' ||
                        (_filter == 'Aujourd’hui' &&
                            date != null &&
                            date.year == now.year &&
                            date.month == now.month &&
                            date.day == now.day) ||
                        status == _filter.toLowerCase();
                    return matchesSearch && matchesFilter;
                  }).toList()..sort(
                    (a, b) => (_dateOf(a) ?? DateTime(2100)).compareTo(
                      _dateOf(b) ?? DateTime(2100),
                    ),
                  );

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                children: [
                  Container(
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
                                'Agenda GAV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Suivez les rendez-vous et leur état en temps réel.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  height: 1.35,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _AppointmentSummary(
                          label: 'Total',
                          value: all.length,
                          icon: Icons.event_note_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AppointmentSummary(
                          label: "Aujourd'hui",
                          value: todayCount,
                          icon: Icons.today_outlined,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un patient ou un motif',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                      ),
                      suffixIcon: IconButton(
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.clear),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'Tous',
                          "Aujourd'hui",
                          'enregistré',
                          'confirmé',
                          'terminé',
                          'annulé',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(_displayStatus(filter)),
                              selected: _filter == filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    const _EmptyAppointments()
                  else
                    ...visible.map(
                      (appointment) => _AppointmentCard(
                        appointment: appointment,
                        patientName:
                            names[appointment
                                .data()['patientId']
                                ?.toString()] ??
                            'Patient',
                        onStatusChanged: (status) =>
                            _updateStatus(appointment, status),
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

  static DateTime? _dateOf(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final value = doc.data()['date'];
    return value is Timestamp ? value.toDate() : null;
  }

  static String _statusOf(Map<String, dynamic> data) =>
      (data['status'] ?? data['statut'] ?? 'enregistré')
          .toString()
          .toLowerCase();

  static String _displayStatus(String value) {
    if (value == "Aujourd'hui") return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _AppointmentCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> appointment;
  final String patientName;
  final ValueChanged<String> onStatusChanged;

  const _AppointmentCard({
    required this.appointment,
    required this.patientName,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final data = appointment.data();
    final date = _AppointmentManagementScreenState._dateOf(appointment);
    final status = _AppointmentManagementScreenState._statusOf(data);
    final activeColor = status == 'annulé'
        ? AppColors.secondary
        : AppColors.success;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    date == null
                        ? '--:--'
                        : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        data['reason']?.toString() ?? 'Consultation',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: onStatusChanged,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'enregistré',
                      child: Text('Enregistré'),
                    ),
                    PopupMenuItem(value: 'confirmé', child: Text('Confirmé')),
                    PopupMenuItem(value: 'terminé', child: Text('Terminé')),
                    PopupMenuItem(value: 'annulé', child: Text('Annulé')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  'État : ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _displayStatus(status),
                  style: TextStyle(
                    fontSize: 12,
                    color: activeColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _displayStatus(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

class _AppointmentSummary extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _AppointmentSummary({
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
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    ),
  );
}

class _EmptyAppointments extends StatelessWidget {
  const _EmptyAppointments();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Column(
      children: [
        Icon(Icons.event_busy_outlined, size: 46, color: AppColors.primary),
        SizedBox(height: 10),
        Text('Aucun rendez-vous trouvé.'),
      ],
    ),
  );
}
