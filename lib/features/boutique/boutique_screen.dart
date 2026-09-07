import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firebase_constants.dart';
import '../../shared/widgets/gav_logo_title.dart';
import '../appointment/appointment_screen.dart';
import '../cart/cart_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../dashboard/patient_bottom_navigation_bar.dart';
import '../patient/profile_screen.dart';
import 'product_detail_screen.dart';
import 'product_item.dart';

class BoutiqueScreen extends StatelessWidget {
  const BoutiqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LiveBoutique();
    /*
    final blue = const Color(0xFF0B3DDB);
    final red = const Color(0xFFEF3B2D);
    final softBlue = const Color(0xFFEAF0FF);
    final softRed = const Color(0xFFFFEAE7);

    final previewCards = [
      _PreviewCard(
        title: 'Nouveautés',
        subtitle: 'Arrivages à venir',
        icon: Icons.new_releases_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF0B3DDB), Color(0xFF2E6BFF)],
        ),
      ),
      _PreviewCard(
        title: 'Produits',
        subtitle: 'Catalogue à mettre en ligne',
        icon: Icons.inventory_2_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFEF3B2D), Color(0xFFFF7A58)],
        ),
      ),
      _PreviewCard(
        title: 'Offres',
        subtitle: 'Promos à valider',
        icon: Icons.local_offer_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF1645E8), Color(0xFFEF3B2D)],
        ),
      ),
      _PreviewCard(
        title: 'Livraison',
        subtitle: 'Suivi bientôt disponible',
        icon: Icons.local_shipping_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF0E6BFF), Color(0xFF0B3DDB)],
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: GavLogoTitle(
          title: 'Boutique',
          titleColor: Colors.white,
          logoSize: 28,
          textSize: 18,
        ),
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF0B3DDB), Color(0xFFEF3B2D)],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [blue, red],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withAlpha(80),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Catalogue à venir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'La boutique GAV',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Une expérience fluide, moderne et prête à accueillir les produits validés par le staff.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _Tag(label: 'Paiement sécurisé'),
                        _Tag(label: 'Livraison'),
                        _Tag(label: 'Produits validés'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.flash_on_rounded,
                      value: 'À venir',
                      label: 'Nouveautés',
                      color: blue,
                      background: softBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite_rounded,
                      value: '0',
                      label: 'Favoris',
                      color: red,
                      background: softRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Découvrir la boutique',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2D3D),
                ),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: previewCards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.04,
                ),
                itemBuilder: (context, index) {
                  final card = previewCards[index];
                  return InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${card.title} sera bientôt disponible',
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: card.gradient.colors.first,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(10),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: card.gradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              card.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            card.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2D3D),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            card.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                'Voir plus',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: card.gradient.colors.first,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Color(0xFF0B3DDB),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFEBEFFD)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE9E7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFEF3B2D),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Le catalogue est en cours de préparation. Les produits seront ajoutés par les personnes habilitées.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PatientBottomNavigationBar(
        selectedIndex: 2,
        onSelected: (index) {
          if (index == 2) return;
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppointmentScreen()),
            );
          } else if (index == 3) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChatbotScreen()));
          } else if (index == 4) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
      ),
    ); */
  }
}

class _LiveBoutique extends StatefulWidget {
  const _LiveBoutique();

  @override
  State<_LiveBoutique> createState() => _LiveBoutiqueState();
}

class _LiveBoutiqueState extends State<_LiveBoutique> {
  String _search = '';
  String _category = 'Tous';

  @override
  Widget build(BuildContext context) {
    final products = FirebaseFirestore.instance
        .collection(FirebaseConstants.productsCollection)
        .snapshots();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3DDB),
        foregroundColor: Colors.white,
        elevation: 0,
        title: GavLogoTitle(
          title: 'Boutique',
          titleColor: Colors.white,
          logoSize: 28,
          textSize: 18,
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: products,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(
              child: Text('Impossible de charger la boutique.'),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final visible = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final category = _productCategory(data);
            final active = (data['active'] ?? data['actif'] ?? true) == true;
            final text =
                '${data['name'] ?? data['nom'] ?? ''} ${data['description'] ?? ''} $category'
                    .toLowerCase();
            return active &&
                (_category == 'Tous' || category == _category) &&
                (_search.isEmpty || text.contains(_search));
          }).toList();
          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              children: [
                _BoutiqueHero(count: visible.length),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) =>
                      setState(() => _search = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    labelText: 'Rechercher dans la boutique',
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
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              selectedColor: const Color(0xFFFFE8E8),
                              onSelected: (_) =>
                                  setState(() => _category = category),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  const _BoutiqueEmpty()
                else
                  ...visible.map(
                    (product) => _BoutiqueProductCard(product: product),
                  ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: PatientBottomNavigationBar(
        selectedIndex: 2,
        onSelected: (index) {
          if (index == 2) return;
          if (index == 1)
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppointmentScreen()),
            );
          if (index == 3)
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ChatbotScreen()));
          if (index == 4)
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
        },
      ),
    );
  }
}

class _BoutiqueHero extends StatelessWidget {
  final int count;
  const _BoutiqueHero({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0B3DDB), Color(0xFFEF3B2D)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x300B3DDB),
          blurRadius: 18,
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
                'La boutique GAV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$count produit${count > 1 ? 's' : ''} disponible${count > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 38),
      ],
    ),
  );
}

class _BoutiqueProductCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> product;
  const _BoutiqueProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final data = product.data();
    final name =
        data['name']?.toString() ??
        data['nom']?.toString() ??
        'Produit optique';
    final category = _productCategory(data);
    final price = _formatPrice(data['price']);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              productId: product.id,
              product: ProductItem(
                name: name,
                price: price,
                subtitle: data['description']?.toString() ?? category,
                color: const Color(0xFF0B3DDB),
                imageUrl:
                    data['imageUrl']?.toString() ??
                    data['image']?.toString() ??
                    '',
              ),
            ),
          ),
        ),
        leading: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF1FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: _ProductImage(
            imageUrl:
                data['imageUrl']?.toString() ?? data['image']?.toString() ?? '',
            iconSize: 28,
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          '$category • ${data['description'] ?? 'Équipement optique'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          price,
          style: const TextStyle(
            color: Color(0xFFD62828),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String imageUrl;
  final double iconSize;

  const _ProductImage({required this.imageUrl, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Icon(
        Icons.visibility_outlined,
        color: const Color(0xFF0B3DDB),
        size: iconSize,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image_outlined,
          color: const Color(0xFF0B3DDB),
          size: iconSize,
        ),
      ),
    );
  }
}

class _BoutiqueEmpty extends StatelessWidget {
  const _BoutiqueEmpty();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: const Column(
      children: [
        Icon(Icons.inventory_2_outlined, color: Color(0xFF0B3DDB), size: 46),
        SizedBox(height: 12),
        Text(
          'Aucun produit disponible',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        SizedBox(height: 6),
        Text(
          'Les produits validés par le cabinet apparaîtront ici.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF667085)),
        ),
      ],
    ),
  );
}

String _productCategory(Map<String, dynamic> data) {
  final value = (data['category'] ?? data['categorie'] ?? data['type'] ?? '')
      .toString()
      .toLowerCase();
  if (value.contains('mont')) return 'Montures';
  if (value.contains('verre') || value.contains('lens')) return 'Verres';
  return 'Autres';
}

String _formatPrice(dynamic value) {
  if (value is num) return '${value.toStringAsFixed(0)} FCFA';
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? 'Prix sur demande' : '$text FCFA';
}

/*
class _PreviewCard {
  const _PreviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
}
*/

/*
class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
*/
