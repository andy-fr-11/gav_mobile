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
  final TextEditingController _prenomCtrl = TextEditingController();
  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _telephoneCtrl = TextEditingController();
  final TextEditingController _adresseCtrl = TextEditingController();
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
  void initState() {
    super.initState();
    _syncProfileFields();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncProfileFields();
  }

  void _syncProfileFields() {
    final profile = context.read<AuthProvider>().userProfile;
    if (profile == null) return;

    _prenomCtrl.text = profile.prenom;
    _nomCtrl.text = profile.nom;
    _telephoneCtrl.text = profile.telephone;
    _adresseCtrl.text = profile.adresse;
    _dateNaissance = profile.dateNaissance;
    if (_imageUrl == null && profile.photo.isNotEmpty) {
      _imageUrl = profile.photo;
    }
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telephoneCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().userProfile;
    final displayName = '${profile?.prenom ?? ''} ${profile?.nom ?? ''}'.trim();
    final initialPhoto = profile?.photo ?? '';
    final effectiveImage = _imageUrl ?? initialPhoto;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: GavLogoTitle(
          title: 'Profil',
          titleColor: Colors.white,
          logoSize: 28,
          textSize: 18,
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF1F8AE0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E88E5).withOpacity(0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 58,
                            backgroundColor: Colors.white,
                            backgroundImage: effectiveImage.isNotEmpty
                                ? NetworkImage(effectiveImage)
                                : null,
                            child: effectiveImage.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 54,
                                    color: Color(0xFF1A5276),
                                  )
                                : null,
                          ),
                        ),
                        if (_uploading)
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Color(0xFF1976D2),
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      displayName.isEmpty ? 'Patient' : displayName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile?.email ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
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
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(
                    _uploading
                        ? 'Téléchargement...'
                        : 'Changer la photo de profil',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _prenomCtrl,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Prénom',
                          filled: true,
                          fillColor: const Color(0xFFF5F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF1976D2),
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF1976D2),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _prenomCtrl.clear(),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Prénom requis'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nomCtrl,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Nom',
                          filled: true,
                          fillColor: const Color(0xFFF5F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF1976D2),
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: Color(0xFF1976D2),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _nomCtrl.clear(),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nom requis'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _telephoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Téléphone',
                          filled: true,
                          fillColor: const Color(0xFFF5F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF1976D2),
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: Color(0xFF1976D2),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _telephoneCtrl.clear(),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Téléphone requis'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateNaissance ?? DateTime(1990, 1, 1),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _dateNaissance = picked);
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Date de naissance',
                              filled: true,
                              fillColor: const Color(0xFFF5F8FC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1976D2),
                                  width: 1.5,
                                ),
                              ),
                              prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF1976D2),
                              ),
                              hintText: _dateNaissance == null
                                  ? 'Sélectionner'
                                  : '${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}',
                              suffixIcon: _dateNaissance == null
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () =>
                                          setState(() => _dateNaissance = null),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _adresseCtrl,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Adresse',
                          filled: true,
                          fillColor: const Color(0xFFF5F8FC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF1976D2),
                              width: 1.5,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF1976D2),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _adresseCtrl.clear(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
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
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profil enregistré'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Enregistrer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
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
