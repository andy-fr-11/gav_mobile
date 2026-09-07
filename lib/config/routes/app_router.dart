import 'package:go_router/go_router.dart';

import '../../core/constants/roles.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/forgot_password_page.dart';
import '../../features/auth/screens/login_page.dart';
import '../../features/auth/screens/register_page.dart';
import '../../features/auth/screens/splash_page.dart';
import '../../features/auth/screens/welcome_page.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/patient_dashboard.dart';
import '../../features/dashboard/admin_dashboard.dart';
import '../../features/dashboard/optician_dashboard.dart';
import '../../features/dashboard/reception_dashboard.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) => GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        name: RouteNames.splash,
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        name: RouteNames.welcome,
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        name: RouteNames.login,
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        name: RouteNames.register,
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        name: RouteNames.forgotPassword,
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        name: RouteNames.dashboard,
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        name: RouteNames.patientDashboard,
        path: '/dashboard/patient',
        builder: (context, state) => const PatientDashboard(),
      ),
      GoRoute(
        name: RouteNames.adminDashboard,
        path: '/dashboard/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        name: RouteNames.opticianDashboard,
        path: '/dashboard/optician',
        builder: (context, state) => const OpticianDashboard(),
      ),
      GoRoute(
        name: RouteNames.receptionDashboard,
        path: '/dashboard/reception',
        builder: (context, state) => const ReceptionDashboard(),
      ),
    ],
    refreshListenable: authProvider,
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggingIn = path.startsWith('/auth');
      final isDashboard = path.startsWith('/dashboard');
      final isRootDashboard = path == '/dashboard';

      if (!authProvider.isAuthenticated && isDashboard) {
        return state.namedLocation(RouteNames.login);
      }

      if (authProvider.isAuthenticated && isLoggingIn) {
        final role = UserRoleHelper.normalize(authProvider.userProfile?.role);
        switch (role) {
          case UserRole.admin:
            return state.namedLocation(RouteNames.adminDashboard);
          case UserRole.receptionist:
            return state.namedLocation(RouteNames.receptionDashboard);
          case UserRole.optician:
            return state.namedLocation(RouteNames.opticianDashboard);
          case UserRole.doctor:
          case UserRole.patient:
            return state.namedLocation(RouteNames.patientDashboard);
        }
      }

      if (authProvider.isAuthenticated && isRootDashboard) {
        final role = UserRoleHelper.normalize(authProvider.userProfile?.role);
        switch (role) {
          case UserRole.admin:
            return state.namedLocation(RouteNames.adminDashboard);
          case UserRole.receptionist:
            return state.namedLocation(RouteNames.receptionDashboard);
          case UserRole.optician:
            return state.namedLocation(RouteNames.opticianDashboard);
          case UserRole.doctor:
          case UserRole.patient:
            return state.namedLocation(RouteNames.patientDashboard);
        }
      }

      return null;
    },
  );
}
