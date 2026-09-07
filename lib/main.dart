import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/firebase/firebase_initializer.dart';
import 'config/routes/app_router.dart';
import 'config/supabase/supabase_config.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/examination_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/order_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseInitializer.initialize();

  try {
    await SupabaseConfig.initialize();
  } catch (error) {
    debugPrint('Supabase initialization skipped: $error');
  }

  final authProvider = AuthProvider();
  await authProvider.initialize();

  final appointmentProvider = AppointmentProvider();
  // attempt to load appointments (will be empty if user not authenticated)
  await appointmentProvider.loadAppointments();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<AppointmentProvider>.value(
          value: appointmentProvider,
        ),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
        ChangeNotifierProvider(create: (_) => ExaminationProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router(context.read<AuthProvider>()),
    );
  }
}
