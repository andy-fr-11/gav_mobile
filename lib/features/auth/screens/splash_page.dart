import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/routes/route_names.dart';
import '../providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), _navigate);
  }

  void _navigate() {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      context.goNamed(RouteNames.welcome);
      return;
    }

    final role = authProvider.userProfile?.role.toLowerCase() ?? 'patient';
    switch (role) {
      case 'admin':
      case 'administrateur':
        context.goNamed(RouteNames.adminDashboard);
        break;
      case 'receptionniste':
        context.goNamed(RouteNames.receptionDashboard);
        break;
      case 'opticien':
        context.goNamed(RouteNames.opticianDashboard);
        break;
      default:
        context.goNamed(RouteNames.patientDashboard);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo_gav.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
