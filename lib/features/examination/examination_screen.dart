import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../models/examination_model.dart';
import '../../providers/examination_provider.dart';
import '../appointment/appointment_screen.dart';
import '../boutique/boutique_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../dashboard/patient_bottom_navigation_bar.dart';
import '../dashboard/patient_dashboard.dart';
import '../patient/profile_screen.dart';

class ExaminationScreen extends StatefulWidget {
  const ExaminationScreen({super.key});

  @override
  State<ExaminationScreen> createState() => _ExaminationScreenState();
}

class _ExaminationScreenState extends State<ExaminationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExaminationProvider>().loadExaminations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExaminationProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: provider.loading && provider.examinations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.loadExaminations,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(provider.examinations.length),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                    sliver: provider.examinations.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildExaminationCard(
                                provider.examinations[index],
                              ),
                              childCount: provider.examinations.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: PatientBottomNavigationBar(
        selectedIndex: 0,
        onSelected: _handleNavigation,
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 54, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A3D91), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
            color: Colors.white,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mes examens',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$count résultat${count > 1 ? 's' : ''} disponible${count > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.health_and_safety_outlined,
            color: Colors.white,
            size: 32,
          ),
        ],
      ),
    );
  }

  Widget _buildExaminationCard(ExaminationModel examination) {
    final date = examination.performedAt;
    final status = examination.status?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A3D91),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F8EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: Color(0xFF117A65),
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  examination.type,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (status?.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F8EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status!,
                    style: const TextStyle(
                      color: Color(0xFF117A65),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 12),
            Text(
              'Réalisé le ${date.day}/${date.month}/${date.year}',
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            ),
          ],
          if (examination.details.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              examination.details,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
          if (examination.result?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Résultat : ${examination.result}',
                style: const TextStyle(
                  color: Color(0xFF117A65),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          if (examination.documentUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _openDocument(examination.documentUrl!),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
              label: const Text('Consulter le compte rendu'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.biotech_outlined, color: Color(0xFF117A65), size: 48),
            SizedBox(height: 16),
            Text(
              'Aucun examen disponible',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Vos résultats apparaîtront ici dès qu’ils seront ajoutés par le cabinet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.mutedText),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le compte rendu ne peut pas être ouvert.'),
        ),
      );
    }
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PatientDashboard()),
        (route) => false,
      );
      return;
    }
    final page = switch (index) {
      1 => const AppointmentScreen(),
      2 => const BoutiqueScreen(),
      3 => const ChatbotScreen(),
      4 => const ProfileScreen(),
      _ => null,
    };
    if (page != null)
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}
