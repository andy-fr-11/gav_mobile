import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;

  const AppErrorWidget({super.key, this.message = 'Une erreur est survenue'});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
