import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../shared/widgets/gav_logo_title.dart';
import '../appointment/appointment_screen.dart';
import '../boutique/boutique_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../dashboard/patient_bottom_navigation_bar.dart';
import '../dashboard/patient_dashboard.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/models/auth_user_model.dart';
import '../../services/supabase_storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;
  String? _imageUrl;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenomCtrl;
  late final TextEditingController _nomCtrl;
  late final TextEditingController _telephoneCtrl;
  late final TextEditingController _adresseCtrl;
  DateTime? _dateNaissance;

  Future<void> _pickAndUpload() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final profile = auth.userProfile;
    if (profile == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Profil utilisateur introuvable.')),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final bytes = await picked.readAsBytes();
      final url = await SupabaseStorageService.uploadProfileImage(
        bucket: 'avatars',
        userId: profile.uid,
        bytes: bytes,
      );

      if (url == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Échec du téléchargement')),
        );
        return;
      }

      setState(() => _imageUrl = url);

      final updated = AuthUserModel(
        uid: profile.uid,
        nom: profile.nom,
        prenom: profile.prenom,
        sexe: profile.sexe,
        dateNaissance: profile.dateNaissance,
        telephone: profile.telephone,
        email: profile.email,
        photo: url,
        role: profile.role,
        statut: profile.statut,
        adresse: profile.adresse,
        createdAt: profile.createdAt,
      );

      await auth.updateUserProfile(updated);

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour')),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().userProfile;
    _prenomCtrl = TextEditingController(text: profile?.prenom ?? '');
    _nomCtrl = TextEditingController(text: profile?.nom ?? '');
    _telephoneCtrl = TextEditingController(text: profile?.telephone ?? '');
    _adresseCtrl = TextEditingController(text: profile?.adresse ?? '');
    _dateNaissance ??= profile?.dateNaissance;
    final displayName = '${profile?.prenom ?? ''} ${profile?.nom ?? ''}'.trim();
    final initialPhoto = profile?.photo ?? '';
    return Scaffold(
      appBar: AppBar(
        title: GavLogoTitle(
          title: 'Profil',
          titleColor: Colors.white,
          logoSize: 28,
          textSize: 18,
        ),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 52,
                backgroundColor: const Color(0xFFF5F7FA),
                backgroundImage: _imageUrl != null
                    ? NetworkImage(_imageUrl!) as ImageProvider
                    : (initialPhoto.isNotEmpty
                          ? NetworkImage(initialPhoto)
                          : null),
                child: (_imageUrl == null && initialPhoto.isEmpty)
                    ? const Icon(
                        Icons.person,
                        size: 48,
                        color: Color(0xFF1A5276),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                displayName.isEmpty ? 'Patient' : displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile?.email ?? '',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  _uploading
                      ? 'Téléchargement...'
                      : 'Changer la photo de profil',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _prenomCtrl,
                        decoration: InputDecoration(
                          labelText: 'Prénom',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _prenomCtrl.clear(),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Prénom requis'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nomCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _nomCtrl.clear(),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nom requis'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telephoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Téléphone',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _telephoneCtrl.clear(),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Téléphone requis'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateNaissance ?? DateTime(1990, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null)
                            setState(() => _dateNaissance = picked);
                        },
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Date de naissance',
                            hintText: _dateNaissance == null
                                ? 'Sélectionner'
                                : '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}',
                            suffixIcon: _dateNaissance == null
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () =>
                                        setState(() => _dateNaissance = null),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _adresseCtrl,
                        decoration: InputDecoration(
                          labelText: 'Adresse',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _adresseCtrl.clear(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          final auth = context.read<AuthProvider>();
                          final existing = auth.userProfile;
                          if (existing == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil introuvable'),
                              ),
                            );
                            return;
                          }
                          final updated = AuthUserModel(
                            uid: existing.uid,
                            nom: _nomCtrl.text.trim(),
                            prenom: _prenomCtrl.text.trim(),
                            sexe: existing.sexe,
                            dateNaissance:
                                _dateNaissance ?? existing.dateNaissance,
                            telephone: _telephoneCtrl.text.trim(),
                            email: existing.email,
                            photo: _imageUrl ?? existing.photo,
                            role: existing.role,
                            statut: existing.statut,
                            adresse: _adresseCtrl.text.trim(),
                            createdAt: existing.createdAt,
                          );
                          try {
                            await auth.updateUserProfile(updated);
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profil enregistré'),
                                ),
                              );
                          } catch (e) {
                            if (mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Erreur: $e')),
                              );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                        ),
                        child: const Text('Enregistrer'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: PatientBottomNavigationBar(
        selectedIndex: 4,
        onSelected: _handleNavigation,
      ),
    );
  }

  void _handleNavigation(int index) {
    if (index == 4) return;
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
      _ => null,
    };
    if (page != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    }
  }
}
