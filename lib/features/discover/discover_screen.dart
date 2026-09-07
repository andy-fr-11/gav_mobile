import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes/route_names.dart';
import '../../shared/widgets/gav_logo_title.dart';
import '../appointment/appointment_screen.dart';
import '../boutique/boutique_screen.dart';
import '../dashboard/patient_bottom_navigation_bar.dart';
import '../chatbot/chatbot_screen.dart';
import '../patient/profile_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B3DDB),
        elevation: 0,
        foregroundColor: Colors.white,
        title: GavLogoTitle(
          title: 'Découvrir',
          titleColor: Colors.white,
          logoSize: 28,
          textSize: 18,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nos Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2D3D),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AppointmentScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(13),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.remove_red_eye_outlined,
                            color: Color(0xFF0B3DDB),
                            size: 24,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Consultation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2D3D),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Examen optométrique',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AppointmentScreen(),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(13),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.local_hospital_outlined,
                            color: Color(0xFF0B3DDB),
                            size: 24,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Diagnostic',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2D3D),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tests visuels complets',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BoutiqueScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(13),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Color(0xFFEA1C24),
                            size: 24,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Boutique',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2D3D),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Montures et accessoires',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BoutiqueScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha(13),
                            spreadRadius: 1,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.wb_sunny_outlined,
                            color: Color(0xFF0B3DDB),
                            size: 24,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Verres Spéciaux',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2D3D),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Progressifs & solaires',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7F8C8D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Promotions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2D3D),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3DDB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Aucune promotion active actuellement.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'À venir',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2D3D),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEA1C24).withAlpha(80),
                  ),
                ),
                child: const Text(
                  'Les contenus seront ajoutés par les personnes habilitées.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF1F2D3D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PatientBottomNavigationBar(
        selectedIndex: -1,
        onSelected: (index) {
          if (index == 0) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AppointmentScreen()),
            );
          } else if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const BoutiqueScreen()));
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
    );
  }
}

class PublicDiscoverScreen extends StatelessWidget {
  const PublicDiscoverScreen({super.key});

  void _requireAccount(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Créez votre compte pour continuer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2D3D),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'La prise de rendez-vous, les achats et le suivi personnalisé sont réservés aux utilisateurs inscrits.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF65758B), height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.goNamed(RouteNames.register),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA1C24),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Créer un compte'),
                ),
              ),
              TextButton(
                onPressed: () => context.goNamed(RouteNames.login),
                child: const Text('J’ai déjà un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const services = [
      (
        'Consultation optique',
        'Évaluation personnalisée de votre vision.',
        Icons.remove_red_eye_outlined,
      ),
      (
        'Contrôle visuel',
        'Tests visuels et orientation par nos professionnels.',
        Icons.visibility_outlined,
      ),
      (
        'Lunettes et verres',
        'Des équipements adaptés à votre quotidien.',
        Icons.face_retouching_natural_outlined,
      ),
      (
        'Conseil et suivi',
        'Un accompagnement avant et après votre équipement.',
        Icons.support_agent_outlined,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Découvrir GAV',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFF0B3DDB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0B3DDB), Color(0xFFEA1C24)],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GILLES-ANDRE VISION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'un autre regard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Découvrez notre cabinet, nos services et notre accompagnement en santé visuelle.',
                      style: TextStyle(color: Colors.white, height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Nos Services',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2D3D),
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.94,
                ),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return InkWell(
                    onTap: () => _requireAccount(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            service.$3,
                            color: index.isEven
                                ? const Color(0xFF0B3DDB)
                                : const Color(0xFFEA1C24),
                            size: 28,
                          ),
                          const Spacer(),
                          Text(
                            service.$1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2D3D),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            service.$2,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.3,
                              color: Color(0xFF65758B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              const Text(
                'Nos engagements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2D3D),
                ),
              ),
              const SizedBox(height: 12),
              const _PublicInfoTile(
                icon: Icons.verified_user_outlined,
                title: 'Écoute et conseil',
                text: 'Une orientation adaptée à chaque besoin.',
              ),
              const _PublicInfoTile(
                icon: Icons.health_and_safety_outlined,
                title: 'Expertise visuelle',
                text: 'Des services centrés sur votre santé visuelle.',
              ),
              const _PublicInfoTile(
                icon: Icons.access_time_rounded,
                title: 'Accompagnement',
                text: 'Un suivi attentif à chaque étape.',
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _requireAccount(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Créer un compte pour continuer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA1C24),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _PublicInfoTile({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: const Color(0xFF0B3DDB)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(text),
    );
  }
}
