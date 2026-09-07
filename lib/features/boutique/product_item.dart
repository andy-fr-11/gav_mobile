import 'package:flutter/material.dart';

class ProductItem {
  final String name;
  final String price;
  final String subtitle;
  final Color color;
  final String imageUrl;

  const ProductItem({
    required this.name,
    required this.price,
    required this.subtitle,
    required this.color,
    this.imageUrl = '',
  });
}
