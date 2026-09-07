import 'package:flutter/material.dart';

class GavLogoTitle extends StatelessWidget {
  const GavLogoTitle({
    super.key,
    this.title,
    this.titleColor = Colors.white,
    this.logoSize = 28,
    this.textSize = 18,
  });

  final String? title;
  final Color titleColor;
  final double logoSize;
  final double textSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      title ?? 'GAV',
      style: TextStyle(
        color: titleColor,
        fontWeight: FontWeight.w700,
        fontSize: textSize,
      ),
    );
  }
}
