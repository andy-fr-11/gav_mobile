import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class OpticianEquipmentScreen extends StatefulWidget {
  const OpticianEquipmentScreen({super.key});

  @override
  State<OpticianEquipmentScreen> createState() =>
      _OpticianEquipmentScreenState();
}

class _OpticianEquipmentScreenState extends State<OpticianEquipmentScreen> {
  String _category = 'Tous';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final products = FirebaseFirestore.instance
        .collection(FirebaseConstants.productsCollection)
        .snapshots();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FC),
      appBar: AppBar(
        title: const Text(
          'Catalogue optique',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: products,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
              child: Text('Impossible de charger le catalogue.'),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final category = _categoryOf(data);
            final text =
                '${data['name'] ?? data['nom'] ?? ''} ${data['description'] ?? ''} $category'
                    .toLowerCase();
            final active = (data['active'] ?? data['actif'] ?? true) == true;
            return active &&
                (_category == 'Tous' || category == _category) &&
                (_search.isEmpty || text.contains(_search));
          }).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              _EquipmentHero(count: docs.length),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) =>
                    setState(() => _search = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  labelText: 'Rechercher un équipement',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => setState(() => _search = ''),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Tous', 'Montures', 'Verres', 'Autres']
                      .map(
                        (value) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(value),
                            selected: _category == value,
                            selectedColor: const Color(0xFFFFE8E8),
                            side: BorderSide(
                              color: _category == value
                                  ? AppColors.secondary
                                  : AppColors.border,
                            ),
                            labelStyle: TextStyle(
                              color: _category == value
                                  ? AppColors.secondary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (_) =>
                                setState(() => _category = value),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (docs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 42,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aucun équipement trouvé',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Modifiez votre recherche ou votre filtre.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                ...docs.map(
                  (doc) => _EquipmentCard(
                    product: doc,
                    onRecommend: () => _recommend(context, doc),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _recommend(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> product,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final patients = await FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .get();
    if (!context.mounted) return;
    final patientDocs = patients.docs
        .where(
          (doc) =>
              (doc.data()['role']?.toString().toLowerCase() ?? 'patient') ==
              'patient',
        )
        .toList();
    if (patientDocs.isEmpty) return;
    String? patientId;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Proposer au patient'),
        content: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Patient'),
          items: patientDocs.map((doc) {
            final data = doc.data();
            return DropdownMenuItem(
              value: doc.id,
              child: Text('${data['prenom'] ?? ''} ${data['nom'] ?? ''}'),
            );
          }).toList(),
          onChanged: (value) => patientId = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              if (patientId == null) return;
              await FirebaseFirestore.instance
                  .collection(FirebaseConstants.notificationsCollection)
                  .add({
                    'patientId': patientId,
                    'type': 'equipment_recommendation',
                    'productId': product.id,
                    'title': 'Équipement recommandé',
                    'message':
                        'Un équipement adapté vous a été proposé par le cabinet.',
                    'read': false,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted)
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Équipement proposé au patient.'),
                  ),
                );
            },
            child: const Text('Proposer'),
          ),
        ],
      ),
    );
  }
}

class _EquipmentHero extends StatelessWidget {
  final int count;
  const _EquipmentHero({required this.count});

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
              const Text(
                'Le choix GAV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count équipement${count > 1 ? 's' : ''} disponible${count > 1 ? 's' : ''} pour vos patients.',
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.secondary.withAlpha(230),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ],
    ),
  );
}

class _EquipmentCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> product;
  final VoidCallback onRecommend;
  const _EquipmentCard({required this.product, required this.onRecommend});

  @override
  Widget build(BuildContext context) {
    final data = product.data();
    final category = _categoryOf(data);
    final name =
        data['name']?.toString() ??
        data['nom']?.toString() ??
        'Équipement optique';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) =>
              _EquipmentDetails(data: data, name: name, category: category),
        ),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF1FF),
          child: Icon(_iconFor(category), color: AppColors.primary),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          '$category • ${data['description'] ?? data['details'] ?? 'Caractéristiques disponibles'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          onPressed: onRecommend,
          tooltip: 'Proposer au patient',
          style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFE8E8)),
          icon: const Icon(
            Icons.person_add_alt_1_outlined,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}

class _EquipmentDetails extends StatelessWidget {
  final Map<String, dynamic> data;
  final String name;
  final String category;
  const _EquipmentDetails({
    required this.data,
    required this.name,
    required this.category,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          category,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          data['description']?.toString() ??
              data['details']?.toString() ??
              'Aucune description technique renseignée.',
        ),
        if (data['reference'] != null) Text('Référence : ${data['reference']}'),
        if (data['material'] != null) Text('Matière : ${data['material']}'),
        if (data['price'] != null) Text('Prix : ${data['price']}'),
      ],
    ),
  );
}

String _categoryOf(Map<String, dynamic> data) {
  final value = (data['category'] ?? data['categorie'] ?? data['type'] ?? '')
      .toString()
      .toLowerCase();
  if (value.contains('mont')) return 'Montures';
  if (value.contains('verre') || value.contains('lens')) return 'Verres';
  return 'Autres';
}

IconData _iconFor(String category) => switch (category) {
  'Montures' => Icons.face_retouching_natural_outlined,
  'Verres' => Icons.visibility_outlined,
  _ => Icons.medical_services_outlined,
};
