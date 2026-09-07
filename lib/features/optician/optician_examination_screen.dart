import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class OpticianExaminationScreen extends StatefulWidget {
  const OpticianExaminationScreen({super.key});

  @override
  State<OpticianExaminationScreen> createState() =>
      _OpticianExaminationScreenState();
}

class _OpticianExaminationScreenState extends State<OpticianExaminationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _details = TextEditingController();
  final _result = TextEditingController();
  final _recommendations = TextEditingController();
  final _rightSphere = TextEditingController();
  final _rightCylinder = TextEditingController();
  final _rightAxis = TextEditingController();
  final _leftSphere = TextEditingController();
  final _leftCylinder = TextEditingController();
  final _leftAxis = TextEditingController();
  String? _patientId;
  String? _consultationId;
  bool _saving = false;

  @override
  void dispose() {
    for (final controller in [
      _details,
      _result,
      _recommendations,
      _rightSphere,
      _rightCylinder,
      _rightAxis,
      _leftSphere,
      _leftCylinder,
      _leftAxis,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _patientId == null) {
      return;
    }
    final opticianId = FirebaseAuth.instance.currentUser?.uid;
    if (opticianId == null) {
      _showMessage('Votre session a expiré. Reconnectez-vous.');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'patientId': _patientId,
        'opticianId': opticianId,
        'consultationId': _consultationId,
        'type': 'Examen de vue',
        'details': _details.text.trim(),
        'result': _result.text.trim(),
        'recommendations': _recommendations.text.trim(),
        'measurements': {
          'rightEye': {
            'sphere': _rightSphere.text.trim(),
            'cylinder': _rightCylinder.text.trim(),
            'axis': _rightAxis.text.trim(),
          },
          'leftEye': {
            'sphere': _leftSphere.text.trim(),
            'cylinder': _leftCylinder.text.trim(),
            'axis': _leftAxis.text.trim(),
          },
        },
        'status': 'completed',
        'performedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.examinationsCollection)
          .add(data);
      if (!mounted) return;
      _formKey.currentState?.reset();
      for (final controller in [
        _details,
        _result,
        _recommendations,
        _rightSphere,
        _rightCylinder,
        _rightAxis,
        _leftSphere,
        _leftCylinder,
        _leftAxis,
      ]) {
        controller.clear();
      }
      setState(() {
        _patientId = null;
        _consultationId = null;
      });
      _showMessage('Examen de vue enregistré dans le dossier du patient.');
    } on FirebaseException catch (error) {
      _showMessage(
        'Enregistrement impossible : ${error.message ?? error.code}',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final patients = FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .snapshots();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text('Réaliser un examen de vue'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: patients,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Impossible de charger les patients.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final documents = snapshot.data!.docs.where((doc) {
            return (doc.data()['role']?.toString().toLowerCase() ??
                    'patient') ==
                'patient';
          }).toList();
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section(
                  'Patient et consultation',
                  Icons.person_search_outlined,
                  DropdownButtonFormField<String>(
                    initialValue: _patientId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Patient'),
                    items: documents.map((doc) {
                      final data = doc.data();
                      final name =
                          '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(name.isEmpty ? 'Patient sans nom' : name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() {
                      _patientId = value;
                      _consultationId = null;
                    }),
                    validator: (value) =>
                        value == null ? 'Sélectionnez un patient' : null,
                  ),
                ),
                if (_patientId != null) ...[
                  const SizedBox(height: 10),
                  _ConsultationPicker(
                    patientId: _patientId!,
                    value: _consultationId,
                    onChanged: (value) =>
                        setState(() => _consultationId = value),
                  ),
                  const SizedBox(height: 10),
                  _PreviousExaminations(patientId: _patientId!),
                ],
                const SizedBox(height: 14),
                _section(
                  'Mesures de réfraction',
                  Icons.visibility_outlined,
                  Column(
                    children: [
                      _eyeTitle('OD - Oeil droit'),
                      _measurementRow(_rightSphere, _rightCylinder, _rightAxis),
                      const SizedBox(height: 12),
                      _eyeTitle('OG - Oeil gauche'),
                      _measurementRow(_leftSphere, _leftCylinder, _leftAxis),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  'Résultats et recommandations',
                  Icons.edit_note_outlined,
                  Column(
                    children: [
                      _field(
                        _details,
                        'Observations et tests réalisés',
                        4,
                        true,
                      ),
                      _field(_result, 'Résultat de l’examen', 3, true),
                      _field(_recommendations, 'Recommandations', 3, false),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _saving ? 'Enregistrement...' : 'Enregistrer l’examen',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) => Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  Widget _eyeTitle(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    ),
  );

  Widget _measurementRow(
    TextEditingController sphere,
    TextEditingController cylinder,
    TextEditingController axis,
  ) => Row(
    children: [
      Expanded(child: _field(sphere, 'Sphère', 1, false)),
      const SizedBox(width: 8),
      Expanded(child: _field(cylinder, 'Cylindre', 1, false)),
      const SizedBox(width: 8),
      Expanded(child: _field(axis, 'Axe', 1, false)),
    ],
  );

  Widget _field(
    TextEditingController controller,
    String label,
    int maxLines,
    bool required,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? 'Ce champ est obligatoire'
                : null
          : null,
    ),
  );
}

class _ConsultationPicker extends StatelessWidget {
  final String patientId;
  final String? value;
  final ValueChanged<String?> onChanged;
  const _ConsultationPicker({
    required this.patientId,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.consultationsCollection)
            .where('patientId', isEqualTo: patientId)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          return DropdownButtonFormField<String>(
            initialValue: docs.any((doc) => doc.id == value) ? value : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Consultation associée (facultatif)',
            ),
            items: docs
                .map(
                  (doc) => DropdownMenuItem(
                    value: doc.id,
                    child: Text(
                      'Consultation du ${_dateLabel(doc.data()['createdAt'])}',
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          );
        },
      );
}

class _PreviousExaminations extends StatelessWidget {
  final String patientId;
  const _PreviousExaminations({required this.patientId});

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection(FirebaseConstants.examinationsCollection)
            .where('patientId', isEqualTo: patientId)
            .get(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty)
            return const Text(
              'Aucun examen antérieur.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            );
          return ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Examens antérieurs (${docs.length})',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            children: docs.reversed.take(5).map((doc) {
              final data = doc.data();
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: AppColors.primary),
                title: Text(data['result']?.toString() ?? 'Examen de vue'),
                subtitle: Text(
                  _dateLabel(data['performedAt'] ?? data['createdAt']),
                ),
              );
            }).toList(),
          );
        },
      );
}

String _dateLabel(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  return 'date non renseignée';
}
