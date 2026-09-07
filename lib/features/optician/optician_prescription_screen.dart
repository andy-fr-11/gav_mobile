import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class OpticianPrescriptionScreen extends StatefulWidget {
  const OpticianPrescriptionScreen({super.key});

  @override
  State<OpticianPrescriptionScreen> createState() =>
      _OpticianPrescriptionScreenState();
}

class _OpticianPrescriptionScreenState
    extends State<OpticianPrescriptionScreen> {
  String? _patientId;
  QueryDocumentSnapshot<Map<String, dynamic>>? _editing;
  bool _saving = false;
  final _details = TextEditingController();
  final _recommendations = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    _recommendations.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_patientId == null || _details.text.trim().isEmpty) {
      _message('Sélectionnez un patient et renseignez la prescription.');
      return;
    }
    final opticianId = FirebaseAuth.instance.currentUser?.uid;
    if (opticianId == null) {
      _message('Votre session a expiré. Reconnectez-vous.');
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'patientId': _patientId,
        'opticianId': opticianId,
        'details': _details.text.trim(),
        'recommendations': _recommendations.text.trim(),
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final collection = FirebaseFirestore.instance.collection(
        FirebaseConstants.prescriptionsCollection,
      );
      if (_editing == null) {
        await collection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _editing!.reference.update(data);
      }
      if (!mounted) return;
      _clearForm();
      _message(
        _editing == null
            ? 'Prescription enregistrée.'
            : 'Prescription modifiée.',
      );
    } on FirebaseException catch (error) {
      _message('Enregistrement impossible : ${error.message ?? error.code}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _edit(QueryDocumentSnapshot<Map<String, dynamic>> prescription) {
    final data = prescription.data();
    setState(() {
      _editing = prescription;
      _patientId = data['patientId']?.toString();
      _details.text = data['details']?.toString() ?? '';
      _recommendations.text = data['recommendations']?.toString() ?? '';
    });
  }

  void _clearForm() {
    setState(() {
      _editing = null;
      _patientId = null;
      _details.clear();
      _recommendations.clear();
    });
  }

  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final patients = FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .snapshots();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text(
          'Ordonnances optiques',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
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
          final patientDocs = snapshot.data!.docs.where(
            (doc) =>
                (doc.data()['role']?.toString().toLowerCase() ?? 'patient') ==
                'patient',
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              _PrescriptionHero(editing: _editing != null),
              const SizedBox(height: 16),
              _form(patientDocs.toList()),
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(Icons.history_rounded, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text(
                    'Historique des prescriptions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_patientId == null)
                const Text(
                  'Sélectionnez un patient pour consulter son historique.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                _PrescriptionHistory(patientId: _patientId!, onEdit: _edit),
            ],
          );
        },
      ),
    );
  }

  Widget _form(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> patients,
  ) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D0A3D91),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE8E8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_note_rounded,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _editing == null
                    ? 'Établir une prescription'
                    : 'Modifier la prescription',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: patients.any((doc) => doc.id == _patientId)
              ? _patientId
              : null,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Patient'),
          items: patients.map((doc) {
            final data = doc.data();
            final name = '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim();
            return DropdownMenuItem(
              value: doc.id,
              child: Text(name.isEmpty ? 'Patient sans nom' : name),
            );
          }).toList(),
          onChanged: (value) => setState(() => _patientId = value),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _details,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Détails de la prescription',
            hintText: 'OD : sphère, cylindre, axe\nOG : sphère, cylindre, axe',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _recommendations,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Recommandations'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Enregistrement...' : 'Enregistrer la prescription',
                ),
              ),
            ),
            if (_editing != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: _clearForm,
                tooltip: 'Annuler la modification',
                icon: const Icon(Icons.close),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _PrescriptionHero extends StatelessWidget {
  final bool editing;
  const _PrescriptionHero({required this.editing});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, Color(0xFF1764C0)],
      ),
      borderRadius: BorderRadius.circular(22),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editing ? 'Mise à jour du dossier' : 'Nouvelle ordonnance',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Formalisez la correction et les recommandations du patient.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(35),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.description_outlined,
            color: Colors.white,
            size: 30,
          ),
        ),
      ],
    ),
  );
}

class _PrescriptionHistory extends StatelessWidget {
  final String patientId;
  final ValueChanged<QueryDocumentSnapshot<Map<String, dynamic>>> onEdit;
  const _PrescriptionHistory({required this.patientId, required this.onEdit});

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.prescriptionsCollection)
            .where('patientId', isEqualTo: patientId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Aucune prescription pour ce patient.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          return Column(
            children: docs.map((doc) {
              final data = doc.data();
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    data['details']?.toString() ?? 'Prescription',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    data['status']?.toString() ?? 'active',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () => onEdit(doc),
                    tooltip: 'Modifier',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
}
