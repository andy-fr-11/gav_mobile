import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class OpticianPatientRecordsScreen extends StatefulWidget {
  const OpticianPatientRecordsScreen({super.key});

  @override
  State<OpticianPatientRecordsScreen> createState() =>
      _OpticianPatientRecordsScreenState();
}

class _OpticianPatientRecordsScreenState
    extends State<OpticianPatientRecordsScreen> {
  final _searchController = TextEditingController();
  String _search = '';

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

  @override
  Widget build(BuildContext context) {
    final users = FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .snapshots();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Dossiers des patients',
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
        stream: users,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
              child: Text('Impossible de charger les patients.'),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final patients = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final role = data['role']?.toString().toLowerCase() ?? 'patient';
            final searchable =
                '${data['prenom'] ?? ''} ${data['nom'] ?? ''} ${data['email'] ?? ''} ${data['telephone'] ?? ''}'
                    .toLowerCase();
            return role == 'patient' &&
                (_search.isEmpty || searchable.contains(_search));
          }).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
            children: [
              _RecordsHeader(count: patients.length),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un patient',
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
              const SizedBox(height: 16),
              if (patients.isEmpty)
                const _EmptyRecords()
              else
                ...patients.map(
                  (patient) => _PatientRecordCard(patient: patient),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RecordsHeader extends StatelessWidget {
  final int count;
  const _RecordsHeader({required this.count});

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
                'Patients GAV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Accédez au dossier complet et à l’historique optique.',
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

class _PatientRecordCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> patient;
  const _PatientRecordCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    final data = patient.data();
    final firstName = data['prenom']?.toString() ?? '';
    final lastName = data['nom']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => _PatientRecordSheet(patient: patient),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: CircleAvatar(
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
        subtitle: Text(
          '${data['email'] ?? 'Email non renseigné'}\n${data['telephone'] ?? 'Téléphone non renseigné'}',
          style: const TextStyle(fontSize: 12, height: 1.4),
        ),
        isThreeLine: true,
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PatientRecordSheet extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> patient;
  const _PatientRecordSheet({required this.patient});

  @override
  State<_PatientRecordSheet> createState() => _PatientRecordSheetState();
}

class _PatientRecordSheetState extends State<_PatientRecordSheet> {
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final data = widget.patient.data();
    _phone = TextEditingController(text: data['telephone']?.toString());
    _address = TextEditingController(text: data['adresse']?.toString());
    _email = TextEditingController(text: data['email']?.toString());
  }

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    final data = {
      'telephone': _phone.text.trim(),
      'adresse': _address.text.trim(),
      'email': _email.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.set(
        firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(widget.patient.id),
        data,
        SetOptions(merge: true),
      );
      batch.set(
        firestore
            .collection(FirebaseConstants.patientsCollection)
            .doc(widget.patient.id),
        data,
        SetOptions(merge: true),
      );
      await batch.commit();
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dossier patient mis à jour.')),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mise à jour impossible : $error')),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<List<_HistoryItem>> _loadHistory() async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore
          .collection(FirebaseConstants.appointmentsCollection)
          .where('patientId', isEqualTo: widget.patient.id)
          .get(),
      firestore
          .collection(FirebaseConstants.examinationsCollection)
          .where('patientId', isEqualTo: widget.patient.id)
          .get(),
      firestore
          .collection(FirebaseConstants.prescriptionsCollection)
          .where('patientId', isEqualTo: widget.patient.id)
          .get(),
    ]);
    final history = <_HistoryItem>[];
    for (final doc in results[0].docs)
      history.add(
        _HistoryItem(
          'Consultation',
          doc.data()['reason']?.toString() ?? 'Rendez-vous',
          _dateOf(doc.data()),
          Icons.calendar_month_outlined,
        ),
      );
    for (final doc in results[1].docs)
      history.add(
        _HistoryItem(
          'Examen de vue',
          doc.data()['type']?.toString() ??
              doc.data()['title']?.toString() ??
              'Examen visuel',
          _dateOf(doc.data()),
          Icons.visibility_outlined,
        ),
      );
    for (final doc in results[2].docs)
      history.add(
        _HistoryItem(
          'Prescription',
          doc.data()['details']?.toString() ?? 'Ordonnance optique',
          _dateOf(doc.data()),
          Icons.description_outlined,
        ),
      );
    history.sort(
      (a, b) => (b.date ?? DateTime(1970)).compareTo(a.date ?? DateTime(1970)),
    );
    return history;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.patient.data();
    final name = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
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
                  IconButton(
                    onPressed: () => setState(() => _editing = !_editing),
                    icon: Icon(
                      _editing ? Icons.close : Icons.edit_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              if (_editing) ...[
                _recordField(_email, 'Email'),
                _recordField(_phone, 'Téléphone'),
                _recordField(_address, 'Adresse', maxLines: 2),
                FilledButton.icon(
                  onPressed: _saving ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    _saving
                        ? 'Enregistrement...'
                        : 'Enregistrer les informations',
                  ),
                ),
              ] else ...[
                Text(
                  data['email']?.toString() ?? 'Email non renseigné',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                _InfoLine(
                  label: 'Téléphone',
                  value: data['telephone']?.toString() ?? 'Non renseigné',
                ),
                _InfoLine(
                  label: 'Adresse',
                  value: data['adresse']?.toString() ?? 'Non renseignée',
                ),
              ],
              const SizedBox(height: 18),
              const Text(
                'Historique du dossier',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<_HistoryItem>>(
                future: _loadHistory(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  if (snapshot.data!.isEmpty)
                    return const Text(
                      'Aucun historique enregistré.',
                      style: TextStyle(color: AppColors.textSecondary),
                    );
                  return Column(
                    children: snapshot.data!
                        .map((item) => _HistoryTile(item: item))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recordField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
      ),
    ),
  );
}

class _HistoryItem {
  final String type;
  final String title;
  final DateTime? date;
  final IconData icon;
  const _HistoryItem(this.type, this.title, this.date, this.icon);
}

class _HistoryTile extends StatelessWidget {
  final _HistoryItem item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFEAF1FF),
      child: Icon(item.icon, color: AppColors.primary, size: 19),
    ),
    title: Text(
      item.title,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text('${item.type} • ${_formatDate(item.date)}'),
  );
}

class _EmptyRecords extends StatelessWidget {
  const _EmptyRecords();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(28),
    child: Column(
      children: [
        Icon(Icons.folder_open_outlined, color: AppColors.primary, size: 42),
        SizedBox(height: 10),
        Text(
          'Aucun patient trouvé.',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
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

DateTime? _dateOf(Map<String, dynamic> data) {
  final value = data['date'] ?? data['performedAt'] ?? data['createdAt'];
  return value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : null;
}

String _formatDate(DateTime? date) => date == null
    ? 'Date non renseignée'
    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
