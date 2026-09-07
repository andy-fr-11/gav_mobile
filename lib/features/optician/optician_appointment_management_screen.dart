import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class OpticianAppointmentManagementScreen extends StatefulWidget {
  const OpticianAppointmentManagementScreen({super.key});

  @override
  State<OpticianAppointmentManagementScreen> createState() =>
      _OpticianAppointmentManagementScreenState();
}

class _OpticianAppointmentManagementScreenState
    extends State<OpticianAppointmentManagementScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _filter = 'À venir';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () =>
          setState(() => _search = _searchController.text.trim().toLowerCase()),
    );
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
    try {
      await appointment.reference.update({
        'status': status,
        'statut': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _message('État du rendez-vous mis à jour.');
    } catch (error) {
      if (mounted) _message('Mise à jour impossible : $error');
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

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
          'Rendez-vous',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
        builder: (context, appointmentSnapshot) =>
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                final names = <String, String>{
                  for (final doc in userSnapshot.data!.docs)
                    doc.id:
                        '${doc.data()['prenom'] ?? ''} ${doc.data()['nom'] ?? ''}'
                            .trim(),
                };
                final now = DateTime.now();
                final items =
                    appointmentSnapshot.data!.docs.where((appointment) {
                      final data = appointment.data();
                      final patient =
                          names[data['patientId']?.toString() ?? ''] ??
                          'Patient';
                      final date = _dateOf(data);
                      final status = _statusOf(data);
                      final searchable =
                          '$patient ${data['reason'] ?? ''} $status'
                              .toLowerCase();
                      final upcoming = date == null || date.isAfter(now);
                      final matchesFilter =
                          _filter == 'Tous' ||
                          (_filter == 'À venir' && upcoming) ||
                          status == _filter.toLowerCase();
                      return matchesFilter &&
                          (_search.isEmpty || searchable.contains(_search));
                    }).toList()..sort(
                      (a, b) => (_dateOf(a.data()) ?? DateTime(2100)).compareTo(
                        _dateOf(b.data()) ?? DateTime(2100),
                      ),
                    );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  children: [
                    _AppointmentHeader(count: items.length),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher un patient ou un motif',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.primary,
                        ),
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
                    _AppointmentFilters(
                      selected: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                    const SizedBox(height: 14),
                    if (items.isEmpty)
                      const _AppointmentEmpty()
                    else
                      ...items.map(
                        (appointment) => _AppointmentCard(
                          appointment: appointment,
                          patientName:
                              names[appointment
                                      .data()['patientId']
                                      ?.toString() ??
                                  ''] ??
                              'Patient',
                          onStatusChanged: (status) =>
                              _updateStatus(appointment, status),
                          onDetails: () =>
                              _showPatientDetails(appointment, names),
                        ),
                      ),
                  ],
                );
              },
            ),
      ),
    );
  }

  Future<void> _showPatientDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> appointment,
    Map<String, String> names,
  ) async {
    final data = appointment.data();
    final patientId = data['patientId']?.toString() ?? '';
    final patient = await FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .doc(patientId)
        .get();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _AppointmentDetails(
        appointment: appointment,
        patient: patient.data(),
        patientName: names[patientId] ?? 'Patient',
      ),
    );
  }
}

class _AppointmentHeader extends StatelessWidget {
  final int count;
  const _AppointmentHeader({required this.count});

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
                'Agenda opticien',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Consultez les patients et suivez chaque rendez-vous.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: Colors.white24,
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AppointmentFilters extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _AppointmentFilters({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children:
          ['À venir', 'Tous', 'confirmed', 'pending', 'completed', 'cancelled']
              .map(
                (value) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_statusLabel(value)),
                    selected: selected == value,
                    onSelected: (_) => onChanged(value),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: selected == value
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

class _AppointmentCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> appointment;
  final String patientName;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDetails;
  const _AppointmentCard({
    required this.appointment,
    required this.patientName,
    required this.onStatusChanged,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final data = appointment.data();
    final date = _dateOf(data);
    final status = _statusOf(data);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName.isEmpty ? 'Patient' : patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  _formatDateTime(date),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Modifier le statut',
                  onSelected: onStatusChanged,
                  itemBuilder: (_) =>
                      ['confirmed', 'pending', 'completed', 'cancelled']
                          .map(
                            (value) => PopupMenuItem(
                              value: value,
                              child: Text(_statusLabel(value)),
                            ),
                          )
                          .toList(),
                ),
                TextButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('Patient'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentDetails extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> appointment;
  final Map<String, dynamic>? patient;
  final String patientName;
  const _AppointmentDetails({
    required this.appointment,
    required this.patient,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final data = appointment.data();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Informations du rendez-vous',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            _InfoLine(label: 'Patient', value: patientName),
            _InfoLine(
              label: 'Email',
              value: patient?['email']?.toString() ?? 'Non renseigné',
            ),
            _InfoLine(
              label: 'Téléphone',
              value: patient?['telephone']?.toString() ?? 'Non renseigné',
            ),
            _InfoLine(label: 'Date', value: _formatDateTime(_dateOf(data))),
            _InfoLine(
              label: 'Motif',
              value: data['reason']?.toString() ?? 'Consultation',
            ),
            _InfoLine(label: 'État', value: _statusLabel(_statusOf(data))),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine({required this.label, required this.value});

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
            style: const TextStyle(fontWeight: FontWeight.w600),
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

class _AppointmentEmpty extends StatelessWidget {
  const _AppointmentEmpty();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(28),
    child: Column(
      children: [
        Icon(
          Icons.event_available_outlined,
          color: AppColors.primary,
          size: 42,
        ),
        SizedBox(height: 10),
        Text(
          'Aucun rendez-vous trouvé.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

DateTime? _dateOf(Map<String, dynamic> data) {
  final value = data['date'] ?? data['scheduledAt'] ?? data['createdAt'];
  return value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : null;
}

String _statusOf(Map<String, dynamic> data) =>
    data['status']?.toString() ?? data['statut']?.toString() ?? 'pending';

String _formatDateTime(DateTime? date) => date == null
    ? 'Date non renseignée'
    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _statusLabel(String value) {
  switch (value) {
    case 'À venir':
      return 'À venir';
    case 'Tous':
      return 'Tous';
    case 'confirmed':
      return 'Confirmé';
    case 'completed':
      return 'Terminé';
    case 'cancelled':
      return 'Annulé';
    default:
      return 'En attente';
  }
}

Color _statusColor(String value) {
  switch (value) {
    case 'confirmed':
      return AppColors.success;
    case 'completed':
      return AppColors.primary;
    case 'cancelled':
      return AppColors.secondary;
    default:
      return const Color(0xFFE08A00);
  }
}
