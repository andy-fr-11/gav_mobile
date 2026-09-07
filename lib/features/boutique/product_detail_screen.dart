import 'package:flutter/material.dart';

import '../../shared/widgets/gav_logo_title.dart';
import '../cart/cart_screen.dart';
import 'product_item.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductItem product;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3DDB),
        elevation: 0,
        foregroundColor: Colors.white,
        title: GavLogoTitle(
          title: 'Produit',
          titleColor: Colors.white,
          logoSize: 26,
          textSize: 16,
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CartScreen(initialItems: [_cartItem()]),
              ),
            ),
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: product.imageUrl.trim().isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.remove_red_eye_outlined,
                                  size: 90,
                                  color: Color(0xFF1F2D3D),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 70,
                                      color: Color(0xFF1F2D3D),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2D3D),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: const [
                                Icon(
                                  Icons.star,
                                  color: Color(0xFF0B3DDB),
                                  size: 18,
                                ),
                                Icon(
                                  Icons.star,
                                  color: Color(0xFF0B3DDB),
                                  size: 18,
                                ),
                                Icon(
                                  Icons.star,
                                  color: Color(0xFF0B3DDB),
                                  size: 18,
                                ),
                                Icon(
                                  Icons.star,
                                  color: Color(0xFF0B3DDB),
                                  size: 18,
                                ),
                                Icon(
                                  Icons.star_half,
                                  color: Color(0xFF0B3DDB),
                                  size: 18,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  product.price,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0B3DDB),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '4 000 FCFA',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Couleur',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2D3D),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _ColorDot(color: const Color(0xFF0B3DDB)),
                                _ColorDot(color: const Color(0xFFEA1C24)),
                                _ColorDot(color: const Color(0xFF3B82F6)),
                                _ColorDot(color: const Color(0xFF1D4ED8)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                const Text(
                                  'Quantité',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2D3D),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.remove, size: 18),
                                      SizedBox(width: 12),
                                      Text(
                                        '1',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(Icons.add, size: 18),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CartScreen(initialItems: [_cartItem()]),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3DDB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Ajouter au panier',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CartItem _cartItem() => CartItem(
    id: productId,
    name: product.name,
    price:
        double.tryParse(product.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
    subtitle: product.subtitle,
  );
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4)],
      ),
    );
  }
}
