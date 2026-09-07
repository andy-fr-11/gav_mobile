import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class PatientManagementScreen extends StatefulWidget {
  const PatientManagementScreen({super.key});

  @override
  State<PatientManagementScreen> createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection(FirebaseConstants.usersCollection);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Gestion des patients',
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
        stream: _users.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Impossible de charger les patients.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final patients = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            if ((data['role']?.toString().toLowerCase() ?? 'patient') !=
                'patient') {
              return false;
            }
            final searchable =
                '${data['prenom'] ?? ''} ${data['nom'] ?? ''} ${data['email'] ?? ''} ${data['telephone'] ?? ''}'
                    .toLowerCase();
            return _search.isEmpty || searchable.contains(_search);
          }).toList();
          final activeCount = patients
              .where(
                (doc) =>
                    doc.data()['statut']?.toString().toLowerCase() == 'actif',
              )
              .length;

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
                            'Patients GAV',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Consultez les comptes et les dossiers de vos patients.',
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
                        Icons.people_alt_rounded,
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
                    child: _PatientSummary(
                      label: 'Patients',
                      value: patients.length,
                      icon: Icons.people_alt_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PatientSummary(
                      label: 'Comptes actifs',
                      value: activeCount,
                      icon: Icons.verified_user_outlined,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom, email ou téléphone',
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (patients.isEmpty)
                const _EmptyPatients()
              else
                ...patients.map((patient) => _PatientCard(patient: patient)),
            ],
          );
        },
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> patient;

  const _PatientCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final data = patient.data();
    final firstName = data['prenom']?.toString() ?? '';
    final lastName = data['nom']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
    final active = data['statut']?.toString().toLowerCase() == 'actif';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _PatientRecord(patient: patient),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFEAF1FF),
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          name.isEmpty ? 'Patient sans nom' : name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${data['email'] ?? 'Email non renseigné'}\n${data['telephone'] ?? 'Téléphone non renseigné'}',
            style: const TextStyle(fontSize: 12, height: 1.45),
          ),
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chevron_right_rounded,
              color: active ? AppColors.primary : AppColors.mutedText,
            ),
            Text(
              active ? 'Actif' : 'Inactif',
              style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.success : AppColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientRecord extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> patient;

  const _PatientRecord({required this.patient});

  Future<_PatientRecordData> _load() async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore
          .collection(FirebaseConstants.appointmentsCollection)
          .where('patientId', isEqualTo: patient.id)
          .get(),
      firestore
          .collection(FirebaseConstants.examinationsCollection)
          .where('patientId', isEqualTo: patient.id)
          .get(),
      firestore
          .collection(FirebaseConstants.prescriptionsCollection)
          .where('patientId', isEqualTo: patient.id)
          .get(),
    ]);
    return _PatientRecordData(
      appointments: results[0].size,
      examinations: results[1].size,
      prescriptions: results[2].size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = patient.data();
    final name = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.folder_shared_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name.isEmpty ? 'Dossier patient' : name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                data['email']?.toString() ?? 'Email non renseigné',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              _InfoLine(
                label: 'Téléphone',
                value: data['telephone']?.toString() ?? 'Non renseigné',
              ),
              _InfoLine(
                label: 'Statut',
                value: data['statut']?.toString() ?? 'Non renseigné',
              ),
              _InfoLine(
                label: 'Adresse',
                value: data['adresse']?.toString() ?? 'Non renseignée',
              ),
              const SizedBox(height: 16),
              const Text(
                'Dossier médical',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<_PatientRecordData>(
                future: _load(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  final record = snapshot.data!;
                  return Row(
                    children: [
                      Expanded(
                        child: _RecordMetric(
                          label: 'Rendez-vous',
                          value: record.appointments,
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RecordMetric(
                          label: 'Examens',
                          value: record.examinations,
                          icon: Icons.visibility_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RecordMetric(
                          label: 'Ordonnances',
                          value: record.prescriptions,
                          icon: Icons.description_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatientRecordData {
  final int appointments;
  final int examinations;
  final int prescriptions;

  const _PatientRecordData({
    required this.appointments,
    required this.examinations,
    required this.prescriptions,
  });
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _RecordMetric extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _RecordMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF1FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 5),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}

class _PatientSummary extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _PatientSummary({
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

class _EmptyPatients extends StatelessWidget {
  const _EmptyPatients();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Column(
      children: [
        Icon(Icons.people_alt_outlined, size: 46, color: AppColors.primary),
        SizedBox(height: 10),
        Text('Aucun patient trouvé.'),
      ],
    ),
  );
}
