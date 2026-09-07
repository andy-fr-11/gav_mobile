import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class ReceptionScreen extends StatefulWidget {
  const ReceptionScreen({super.key});
  @override
  State<ReceptionScreen> createState() => _ReceptionScreenState();
}

class _ReceptionScreenState extends State<ReceptionScreen> {
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
          'Accueil des patients',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: appointments,
        builder: (context, appointmentSnapshot) =>
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: users,
              builder: (context, userSnapshot) {
                if (!appointmentSnapshot.hasData || !userSnapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final names = {
                  for (final doc in userSnapshot.data!.docs)
                    doc.id:
                        '${doc.data()['prenom'] ?? ''} ${doc.data()['nom'] ?? ''}'
                            .trim(),
                };
                final today = DateTime.now();
                final items =
                    appointmentSnapshot.data!.docs.where((doc) {
                      final data = doc.data();
                      final timestamp = data['date'];
                      if (timestamp is! Timestamp) return false;
                      final date = timestamp.toDate();
                      final status =
                          (data['status'] ?? data['statut'] ?? 'prévu')
                              .toString()
                              .toLowerCase();
                      return date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day &&
                          status != 'annulé' &&
                          status != 'cancelled' &&
                          status != 'completed';
                    }).toList()..sort(
                      (a, b) => (a.data()['date'] as Timestamp).compareTo(
                        b.data()['date'] as Timestamp,
                      ),
                    );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  children: [
                    _ReceptionHeader(count: items.length),
                    const SizedBox(height: 16),
                    if (items.isEmpty)
                      const _EmptyReception()
                    else
                      ...items.map(
                        (appointment) => _ArrivalCard(
                          appointment: appointment,
                          patientName:
                              names[appointment
                                      .data()['patientId']
                                      ?.toString() ??
                                  ''] ??
                              'Patient',
                          onChanged: (status) => _update(appointment, status),
                        ),
                      ),
                  ],
                );
              },
            ),
      ),
    );
  }

  Future<void> _update(
    QueryDocumentSnapshot<Map<String, dynamic>> appointment,
    String status,
  ) async {
    await appointment.reference.update({
      'status': status,
      'statut': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Patient marqué : $status.')));
  }
}

class _ReceptionHeader extends StatelessWidget {
  final int count;
  const _ReceptionHeader({required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, Color(0xFF1764C0)],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'File d’accueil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Enregistrez les arrivées et orientez les patients.',
                style: TextStyle(color: Colors.white70),
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

class _ArrivalCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> appointment;
  final String patientName;
  final ValueChanged<String> onChanged;
  const _ArrivalCard({
    required this.appointment,
    required this.patientName,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final data = appointment.data();
    final status = (data['status'] ?? data['statut'] ?? 'prévu').toString();
    final time = (data['date'] as Timestamp).toDate();
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEAF1FF),
          child: Icon(Icons.person_outline, color: AppColors.primary),
        ),
        title: Text(
          patientName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} • ${data['reason'] ?? 'Rendez-vous'}\n$status',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: onChanged,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'arrivé', child: Text('Patient arrivé')),
            PopupMenuItem(
              value: 'en attente',
              child: Text('Mettre en attente'),
            ),
            PopupMenuItem(
              value: 'pris en charge',
              child: Text('Pris en charge'),
            ),
            PopupMenuItem(
              value: 'orienté',
              child: Text('Orienté vers opticien'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReception extends StatelessWidget {
  const _EmptyReception();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: const Column(
      children: [
        Icon(
          Icons.event_available_outlined,
          color: AppColors.success,
          size: 44,
        ),
        SizedBox(height: 10),
        Text(
          'Aucun patient attendu',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'La file d’accueil est vide pour aujourd’hui.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
