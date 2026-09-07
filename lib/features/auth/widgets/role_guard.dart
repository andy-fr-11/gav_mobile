import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/roles.dart';
import '../providers/auth_provider.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.redirectTo,
  });

  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? redirectTo;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().currentRole;
    final allowed = allowedRoles.contains(role) ||
        (role == UserRole.admin && allowedRoles.contains(UserRole.admin));

    if (!allowed) {
      return redirectTo ?? const _UnauthorizedView();
    }

    return child;
  }
}

class _UnauthorizedView extends StatelessWidget {
  const _UnauthorizedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline, size: 64, color: Colors.redAccent),
              SizedBox(height: 16),
              Text(
                'Accès non autorisé',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Vous n’avez pas les permissions nécessaires pour accéder à cet écran.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
