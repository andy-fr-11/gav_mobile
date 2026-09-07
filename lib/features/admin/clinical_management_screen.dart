import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class ClinicalManagementScreen extends StatefulWidget {
  const ClinicalManagementScreen({super.key});

  @override
  State<ClinicalManagementScreen> createState() =>
      _ClinicalManagementScreenState();
}

class _ClinicalManagementScreenState extends State<ClinicalManagementScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  int _tab = 0;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Consultations et examens',
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
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.usersCollection)
            .snapshots(),
        builder: (context, usersSnapshot) {
          if (!usersSnapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final names = <String, String>{};
          for (final user in usersSnapshot.data!.docs) {
            final data = user.data();
            names[user.id] = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'
                .trim();
          }
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
                            'Suivi clinique',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Accédez aux consultations, résultats d’examens et ordonnances selon vos droits.',
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
                        Icons.medical_information_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un patient ou un résultat',
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
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Consultations'),
                    icon: Icon(Icons.event_note_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Examens'),
                    icon: Icon(Icons.visibility_outlined),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Ordonnances'),
                    icon: Icon(Icons.description_outlined),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
              const SizedBox(height: 16),
              _buildTab(names),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab(Map<String, String> names) {
    final collection = switch (_tab) {
      0 => FirebaseConstants.appointmentsCollection,
      1 => FirebaseConstants.examinationsCollection,
      _ => FirebaseConstants.prescriptionsCollection,
    };
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const _ClinicalEmpty(
            text: 'Impossible de charger les données cliniques.',
          );
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final documents = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final patient = names[data['patientId']?.toString()] ?? 'Patient';
          final searchable =
              '$patient ${data['reason'] ?? ''} ${data['details'] ?? ''} ${data['result'] ?? ''} ${data['resultat'] ?? ''}'
                  .toLowerCase();
          return _search.isEmpty || searchable.contains(_search);
        }).toList();
        if (documents.isEmpty)
          return const _ClinicalEmpty(text: 'Aucune donnée clinique trouvée.');
        return Column(
          children: documents
              .map(
                (doc) => _ClinicalCard(
                  tab: _tab,
                  document: doc,
                  patientName:
                      names[doc.data()['patientId']?.toString()] ?? 'Patient',
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ClinicalCard extends StatelessWidget {
  final int tab;
  final QueryDocumentSnapshot<Map<String, dynamic>> document;
  final String patientName;

  const _ClinicalCard({
    required this.tab,
    required this.document,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final data = document.data();
    final title = tab == 0
        ? (data['reason']?.toString().isNotEmpty == true
              ? data['reason'].toString()
              : 'Consultation')
        : tab == 1
        ? (data['type'] ?? data['title'] ?? 'Examen visuel').toString()
        : 'Ordonnance';
    final details = tab == 0
        ? _formatDate(data['date'])
        : tab == 1
        ? (data['result'] ??
                  data['resultat'] ??
                  data['details'] ??
                  'Résultat non renseigné')
              .toString()
        : (data['details'] ?? 'Détails non renseignés').toString();
    final status = (data['status'] ?? data['statut'])?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF1FF),
          child: Icon(
            tab == 0
                ? Icons.event_note_outlined
                : tab == 1
                ? Icons.visibility_outlined
                : Icons.description_outlined,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          patientName,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '$title\n$details',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, height: 1.4),
          ),
        ),
        isThreeLine: true,
        trailing: status == null
            ? const Icon(Icons.chevron_right_rounded, color: AppColors.primary)
            : Text(
                status,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
        onTap: () => _showDetails(context, title, details, data),
      ),
    );
  }

  void _showDetails(
    BuildContext context,
    String title,
    String details,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                patientName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(details, style: const TextStyle(height: 1.5)),
              if (data['documentUrl'] != null || data['url'] != null)
                const Padding(
                  padding: EdgeInsets.only(top: 14),
                  child: Text(
                    'Document associé disponible.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(Object? value) => value is Timestamp
      ? '${value.toDate().day.toString().padLeft(2, '0')}/${value.toDate().month.toString().padLeft(2, '0')}/${value.toDate().year}'
      : 'Date non renseignée';
}

class _ClinicalEmpty extends StatelessWidget {
  final String text;

  const _ClinicalEmpty({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.medical_information_outlined,
          size: 46,
          color: AppColors.primary,
        ),
        const SizedBox(height: 10),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}
