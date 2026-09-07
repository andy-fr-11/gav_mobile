import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

const _consultationAccent = AppColors.secondary;

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _observations = TextEditingController();
  final _outcome = TextEditingController();
  final _recommendations = TextEditingController();
  String? _patientId;
  bool _saving = false;

  @override
  void dispose() {
    _observations.dispose();
    _outcome.dispose();
    _recommendations.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sélectionnez un patient et renseignez les observations et les résultats.',
          ),
        ),
      );
      return;
    }
    if (_patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez un patient avant d’enregistrer.'),
        ),
      );
      return;
    }
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre session a expiré. Reconnectez-vous.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final consultation = firestore
          .collection(FirebaseConstants.consultationsCollection)
          .doc();
      await consultation
          .set({
            'patientId': _patientId,
            'opticianId': currentUser.uid,
            'observations': _observations.text.trim(),
            'outcome': _outcome.text.trim(),
            'recommendations': _recommendations.text.trim(),
            'notes': _observations.text.trim(),
            'status': 'completed',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 15));
      if (mounted) {
        _observations.clear();
        _outcome.clear();
        _recommendations.clear();
        setState(() => _patientId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consultation clôturée et enregistrée.'),
          ),
        );
      }
    } catch (error) {
      final message = error is TimeoutException
          ? 'Firestore ne répond pas sur l’émulateur après 15 secondes. Vérifiez que l’émulateur a accès à Internet, puis relancez complètement l’application.'
          : error is FirebaseException && error.code == 'permission-denied'
          ? 'Firestore refuse l’enregistrement de la collection consultations. Vérifiez les règles Firestore.'
          : 'Enregistrement impossible : $error';
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 8),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patients = FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .snapshots();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Réaliser une consultation',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _consultationAccent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_consultationAccent, Color(0xFFB21F27)],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: patients,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
              child: Text('Impossible de charger les patients.'),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final documents = snapshot.data!.docs
              .where(
                (doc) =>
                    (doc.data()['role']?.toString().toLowerCase() ??
                        'patient') ==
                    'patient',
              )
              .toList();
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                _ConsultationHeader(),
                const SizedBox(height: 16),
                _FormSection(
                  title: 'Patient concerné',
                  icon: Icons.person_search_outlined,
                  child: DropdownButtonFormField<String>(
                    initialValue: _patientId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sélectionner un patient',
                    ),
                    items: documents.map((doc) {
                      final data = doc.data();
                      final name =
                          '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(
                          name.isEmpty ? 'Patient sans nom' : name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _patientId = value),
                    validator: (value) =>
                        value == null ? 'Sélectionnez un patient' : null,
                  ),
                ),
                if (_patientId != null) ...[
                  const SizedBox(height: 12),
                  _PatientSnapshot(patientId: _patientId!),
                ],
                const SizedBox(height: 14),
                _FormSection(
                  title: 'Compte rendu',
                  icon: Icons.edit_note_outlined,
                  child: Column(
                    children: [
                      _field(
                        _observations,
                        'Observations effectuées',
                        maxLines: 5,
                      ),
                      _field(
                        _outcome,
                        'Résultats de la prise en charge',
                        maxLines: 4,
                      ),
                      _field(
                        _recommendations,
                        'Recommandations et suite',
                        maxLines: 4,
                        required: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _consultationAccent,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _saving ? 'Enregistrement...' : 'Clôturer et enregistrer',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required int maxLines,
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
      ),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Champ obligatoire'
                : null
          : null,
    ),
  );
}

class _ConsultationHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_consultationAccent, Color(0xFFB21F27)],
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
    child: const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle consultation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Consultez le dossier, renseignez vos observations et clôturez la prise en charge.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.medical_information_outlined, color: Colors.white, size: 34),
      ],
    ),
  );
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: _consultationAccent),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _PatientSnapshot extends StatelessWidget {
  final String patientId;
  const _PatientSnapshot({required this.patientId});

  Future<Map<String, int>> _load() async {
    final firestore = FirebaseFirestore.instance;
    final results = await Future.wait([
      firestore
          .collection(FirebaseConstants.appointmentsCollection)
          .where('patientId', isEqualTo: patientId)
          .get(),
      firestore
          .collection(FirebaseConstants.examinationsCollection)
          .where('patientId', isEqualTo: patientId)
          .get(),
      firestore
          .collection(FirebaseConstants.prescriptionsCollection)
          .where('patientId', isEqualTo: patientId)
          .get(),
    ]);
    return {
      'Consultations': results[0].size,
      'Examens': results[1].size,
      'Ordonnances': results[2].size,
    };
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, int>>(
    future: _load(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const LinearProgressIndicator();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: snapshot.data!.entries
              .map(
                (entry) => Column(
                  children: [
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        color: _consultationAccent,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      );
    },
  );
}
