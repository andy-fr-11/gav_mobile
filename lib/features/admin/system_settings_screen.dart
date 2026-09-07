import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _hours = TextEditingController();
  bool _maintenanceMode = false;
  bool _pushNotifications = true;
  bool _chatbotEnabled = true;
  bool _loading = true;
  bool _saving = false;

  DocumentReference<Map<String, dynamic>> get _settings =>
      FirebaseFirestore.instance.collection('system_settings').doc('general');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final snapshot = await _settings.get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      _name.text = data['institutionName']?.toString() ?? 'Gilles-André Vision';
      _email.text = data['email']?.toString() ?? '';
      _phone.text = data['phone']?.toString() ?? '';
      _address.text = data['address']?.toString() ?? '';
      _hours.text =
          data['openingHours']?.toString() ?? 'Lun - Sam : 08h00 - 18h00';
      _maintenanceMode = data['maintenanceMode'] == true;
      _pushNotifications = data['pushNotifications'] != false;
      _chatbotEnabled = data['chatbotEnabled'] != false;
    } catch (error) {
      if (mounted)
        _showMessage('Impossible de charger les paramètres : $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await _settings.set({
        'institutionName': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'openingHours': _hours.text.trim(),
        'maintenanceMode': _maintenanceMode,
        'pushNotifications': _pushNotifications,
        'chatbotEnabled': _chatbotEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _showMessage('Paramètres enregistrés.');
    } catch (error) {
      _showMessage('Enregistrement impossible : $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Paramètres du système',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, Color(0xFF1764C0)],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _SettingsHeader(),
                  const SizedBox(height: 16),
                  _SettingsSection(
                    title: 'Identité de l’établissement',
                    icon: Icons.business_outlined,
                    children: [
                      _field(_name, 'Nom de l’établissement'),
                      _field(
                        _email,
                        'Adresse email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _field(
                        _phone,
                        'Téléphone',
                        keyboardType: TextInputType.phone,
                      ),
                      _field(_address, 'Adresse', maxLines: 2),
                      _field(_hours, 'Horaires d’ouverture'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SettingsSection(
                    title: 'Fonctionnement de l’application',
                    icon: Icons.tune_outlined,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _pushNotifications,
                        onChanged: (value) =>
                            setState(() => _pushNotifications = value),
                        title: const Text(
                          'Notifications activées',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Autoriser les rappels et informations aux utilisateurs.',
                        ),
                        activeThumbColor: AppColors.primary,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _chatbotEnabled,
                        onChanged: (value) =>
                            setState(() => _chatbotEnabled = value),
                        title: const Text(
                          'Chatbot activé',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Rendre l’assistant disponible aux patients.',
                        ),
                        activeThumbColor: AppColors.primary,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _maintenanceMode,
                        onChanged: (value) =>
                            setState(() => _maintenanceMode = value),
                        title: const Text(
                          'Mode maintenance',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          'Signaler une maintenance en cours aux utilisateurs.',
                        ),
                        activeThumbColor: AppColors.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveSettings,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving
                          ? 'Enregistrement...'
                          : 'Enregistrer les paramètres',
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
      ),
      validator: label == 'Nom de l’établissement'
          ? (value) => value == null || value.trim().isEmpty
                ? 'Champ obligatoire'
                : null
          : null,
    ),
  );
}

class _SettingsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primary, Color(0xFF174F9B)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x260A3D91),
          blurRadius: 16,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuration GAV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Centralisez les informations et les options du système.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        Icon(Icons.settings_suggest_outlined, color: Colors.white, size: 34),
      ],
    ),
  );
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D1E3A73),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}
