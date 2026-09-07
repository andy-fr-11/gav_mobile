import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../services/supabase_storage_service.dart';

const _productImageBucket = 'products';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  String _category = 'Toutes';

  CollectionReference<Map<String, dynamic>> get _products => FirebaseFirestore
      .instance
      .collection(FirebaseConstants.productsCollection);

  CollectionReference<Map<String, dynamic>> get _categories => FirebaseFirestore
      .instance
      .collection(FirebaseConstants.productCategoriesCollection);

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

  Future<void> _openProductForm({
    QueryDocumentSnapshot<Map<String, dynamic>>? product,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _ProductForm(product: product, onSaved: () => setState(() {})),
    );
  }

  Future<void> _toggleProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> product,
  ) async {
    final data = product.data();
    final active = (data['active'] ?? data['actif'] ?? true) == true;
    await product.reference.update({
      'active': !active,
      'actif': !active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> product,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Supprimer le produit ?'),
            content: const Text(
              'Cette action retire le produit du catalogue administrateur.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) {
      await product.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Gestion de la boutique',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Ajouter un produit'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _products.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Impossible de charger le catalogue.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snapshot.data!.docs;
          final products = all.where((product) {
            final data = product.data();
            final category = data['category']?.toString() ?? 'Autre';
            final searchable =
                '${data['name'] ?? ''} ${data['description'] ?? ''} $category'
                    .toLowerCase();
            return (_search.isEmpty || searchable.contains(_search)) &&
                (_category == 'Toutes' || category == _category);
          }).toList();

          final active = all
              .where(
                (doc) =>
                    (doc.data()['active'] ?? doc.data()['actif'] ?? true) ==
                    true,
              )
              .length;
          final lowStock = all.where((doc) {
            final stock = (doc.data()['stock'] as num?)?.toInt();
            return stock != null && stock <= 5;
          }).length;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _categories.snapshots(),
            builder: (context, categorySnapshot) {
              final categories = [
                'Toutes',
                ...?categorySnapshot.data?.docs.map(
                  (doc) => doc.data()['name']?.toString() ?? doc.id,
                ),
              ];

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
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
                                'Boutique GAV',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Gérez le catalogue, les catégories et les stocks.',
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
                          decoration: const BoxDecoration(
                            color: Colors.white30,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.storefront_outlined,
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
                        child: _StoreSummary(
                          label: 'Produits',
                          value: all.length,
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StoreSummary(
                          label: 'Actifs',
                          value: active,
                          icon: Icons.visibility_outlined,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StoreSummary(
                          label: 'Stock bas',
                          value: lowStock,
                          icon: Icons.warning_amber_outlined,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit',
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
                        for (final category in categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (products.isEmpty)
                    const _EmptyStore()
                  else
                    ...products.map(
                      (product) => _ProductCard(
                        product: product,
                        onEdit: () => _openProductForm(product: product),
                        onToggle: () => _toggleProduct(product),
                        onDelete: () => _deleteProduct(product),
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
}

class _ProductCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> product;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = product.data();
    final image = data['imageUrl']?.toString() ?? data['image']?.toString();
    final active = (data['active'] ?? data['actif'] ?? true) == true;
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final price = (data['price'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1E3A73),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductImage(url: image),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        data['name']?.toString() ?? 'Produit sans nom',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFE7F9EE)
                            : const Color(0xFFFFF0ED),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        active ? 'Actif' : 'Inactif',
                        style: TextStyle(
                          color: active
                              ? AppColors.success
                              : AppColors.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  data['category']?.toString() ?? 'Autre',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${price.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 15,
                      color: stock <= 5
                          ? AppColors.secondary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Stock : $stock',
                      style: TextStyle(
                        color: stock <= 5
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'toggle') onToggle();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(active ? 'Désactiver' : 'Activer'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;

  const _ProductImage({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: url == null || url!.isEmpty
          ? const Icon(Icons.image_outlined, color: AppColors.primary)
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.secondary,
                ),
              ),
            ),
    );
  }
}

class _ProductForm extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>>? product;
  final VoidCallback onSaved;

  const _ProductForm({required this.product, required this.onSaved});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _image;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  late String _category;
  bool _active = true;
  bool _saving = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    final data = widget.product?.data() ?? const <String, dynamic>{};
    _name = TextEditingController(text: data['name']?.toString());
    _description = TextEditingController(text: data['description']?.toString());
    _price = TextEditingController(text: data['price']?.toString());
    _stock = TextEditingController(text: data['stock']?.toString() ?? '0');
    _image = TextEditingController(
      text: data['imageUrl']?.toString() ?? data['image']?.toString(),
    );
    _category = data['category']?.toString() ?? 'Montures';
    _active = (data['active'] ?? data['actif'] ?? true) == true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 88,
    );
    if (picked == null) return;

    setState(() => _uploadingImage = true);
    try {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedImage = picked;
        _pickedImageBytes = bytes;
        _uploadingImage = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger l’image : $error')),
      );
    }
  }

  String _imageExtension() {
    final name = _pickedImage?.name.toLowerCase() ?? '';
    final extension = name.contains('.') ? name.split('.').last : 'jpg';
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? extension
        : 'jpg';
  }

  String _imageContentType() {
    switch (_imageExtension()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Widget _productImagePicker() {
    final currentUrl = _image.text.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Image du produit',
            style: Theme.of(context).inputDecorationTheme.labelStyle,
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _pickedImageBytes != null
                ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                : currentUrl.isNotEmpty
                ? Image.network(
                    currentUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.secondary,
                      size: 34,
                    ),
                  )
                : const Icon(
                    Icons.image_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _uploadingImage ? null : _pickImage,
            icon: _uploadingImage
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.photo_library_outlined),
            label: Text(
              _uploadingImage
                  ? 'Chargement...'
                  : _pickedImageBytes == null
                  ? 'Choisir une image'
                  : 'Remplacer l’image',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez renseigner le nom, le prix et le stock.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'price': double.tryParse(_price.text.replaceAll(',', '.')) ?? 0,
      'stock': int.tryParse(_stock.text) ?? 0,
      'category': _category,
      'imageUrl': _image.text.trim(),
      'active': _active,
      'actif': _active,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final collection = FirebaseFirestore.instance.collection(
        FirebaseConstants.productsCollection,
      );
      final reference = widget.product?.reference ?? collection.doc();

      if (_pickedImageBytes != null) {
        final imageUrl = await SupabaseStorageService.uploadProductImage(
          bucket: _productImageBucket,
          productId: reference.id,
          bytes: _pickedImageBytes!,
          fileName: 'product.${_imageExtension()}',
          contentType: _imageContentType(),
        );
        if (imageUrl == null) {
          throw StateError(
            'Impossible d’envoyer l’image. Vérifiez la configuration Supabase '
            'et les règles du bucket products.',
          );
        }
        data['imageUrl'] = imageUrl;
      }

      if (widget.product == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await reference.set(data);
      } else {
        await reference.update(data);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 8),
            content: Text('Enregistrement impossible : $error'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.product == null
                      ? 'Ajouter un produit'
                      : 'Modifier un produit',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _field(_name, 'Nom du produit'),
                _field(
                  _description,
                  'Description',
                  required: false,
                  maxLines: 3,
                ),
                _field(
                  _price,
                  'Prix (FCFA)',
                  keyboardType: TextInputType.number,
                ),
                _field(
                  _stock,
                  'Stock disponible',
                  keyboardType: TextInputType.number,
                ),
                _productImagePicker(),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Montures',
                      child: Text('Montures'),
                    ),
                    DropdownMenuItem(value: 'Verres', child: Text('Verres')),
                    DropdownMenuItem(
                      value: 'Équipements',
                      child: Text('Équipements'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'Montures'),
                ),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: const Text('Produit visible dans la boutique'),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          suffixIcon: IconButton(
            onPressed: controller.clear,
            icon: const Icon(Icons.clear),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Champ obligatoire'
                  : null
            : null,
      ),
    );
  }
}

class _StoreSummary extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StoreSummary({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1E3A73),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStore extends StatelessWidget {
  const _EmptyStore();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            'Aucun produit dans le catalogue.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ajoutez un produit pour commencer votre catalogue.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
