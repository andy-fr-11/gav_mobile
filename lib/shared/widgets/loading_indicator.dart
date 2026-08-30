import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 35,
      height: 35,
      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
    );
  }
}
