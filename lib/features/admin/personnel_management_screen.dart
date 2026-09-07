import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

class PersonnelManagementScreen extends StatefulWidget {
  const PersonnelManagementScreen({super.key});

  @override
  State<PersonnelManagementScreen> createState() =>
      _PersonnelManagementScreenState();
}

class _PersonnelManagementScreenState extends State<PersonnelManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  bool _loading = false;

  CollectionReference<Map<String, dynamic>> get _users =>
      FirebaseFirestore.instance.collection(FirebaseConstants.usersCollection);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openEmployeeForm({
    QueryDocumentSnapshot<Map<String, dynamic>>? employee,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EmployeeForm(employee: employee, onSaved: _reload),
    );
  }

  void _reload() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleStatus(
    QueryDocumentSnapshot<Map<String, dynamic>> employee,
  ) async {
    final current = employee.data()['statut']?.toString().toLowerCase();
    final next = current == 'actif' ? 'inactif' : 'actif';
    await employee.reference.update({'statut': next});
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Gestion du personnel',
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
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _openEmployeeForm(),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Ajouter'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _users.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Impossible de charger le personnel.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final employees = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            final role = data['role']?.toString().toLowerCase() ?? 'patient';
            if (role == 'patient') return false;
            final name =
                '${data['prenom'] ?? ''} ${data['nom'] ?? ''} ${data['email'] ?? ''}'
                    .toLowerCase();
            return _search.isEmpty || name.contains(_search);
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            children: [
              Container(
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Équipe GAV',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Gérez les accès, les rôles et les statuts du personnel.',
                            style: TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StaffSummary(
                      label: 'Total',
                      value: employees.length,
                      icon: Icons.people_alt_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StaffSummary(
                      label: 'Actifs',
                      value: employees
                          .where(
                            (employee) =>
                                employee
                                    .data()['statut']
                                    ?.toString()
                                    .toLowerCase() ==
                                'actif',
                          )
                          .length,
                      icon: Icons.verified_user_outlined,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StaffSummary(
                      label: 'Inactifs',
                      value: employees
                          .where(
                            (employee) =>
                                employee
                                    .data()['statut']
                                    ?.toString()
                                    .toLowerCase() !=
                                'actif',
                          )
                          .length,
                      icon: Icons.pause_circle_outline,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou email',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                  ),
                  suffixIcon: IconButton(
                    onPressed: _searchController.clear,
                    icon: const Icon(Icons.clear),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (employees.isEmpty)
                const _EmptyPersonnel()
              else
                ...employees.map(
                  (employee) => _EmployeeCard(
                    employee: employee,
                    onEdit: () => _openEmployeeForm(employee: employee),
                    onToggle: () => _toggleStatus(employee),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> employee;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _EmployeeCard({
    required this.employee,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final data = employee.data();
    final firstName = data['prenom']?.toString() ?? '';
    final lastName = data['nom']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();
    final role = data['role']?.toString() ?? 'employe';
    final status = data['statut']?.toString() ?? 'inactif';
    final active = status.toLowerCase() == 'actif';
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active ? const Color(0xFFDCE8F8) : const Color(0xFFF0D9D9),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: active
              ? const Color(0xFFEAF1FF)
              : const Color(0xFFFFEDEE),
          child: Text(
            initials.isEmpty ? '?' : initials,
            style: TextStyle(
              color: active ? AppColors.primary : AppColors.secondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name.isEmpty ? 'Employé sans nom' : name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            _StatusBadge(active: active),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              Icon(
                role.toLowerCase() == 'admin'
                    ? Icons.admin_panel_settings_outlined
                    : Icons.badge_outlined,
                size: 15,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 5),
              Text(
                _roleLabel(role),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  data['email']?.toString() ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          tooltip: 'Actions',
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'status') onToggle();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            PopupMenuItem(
              value: 'status',
              child: Text(active ? 'Desactiver' : 'Activer'),
            ),
          ],
        ),
      ),
    );
  }

  static String _roleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrateur':
        return 'Administrateur';
      case 'opticien':
      case 'optician':
        return 'Opticien';
      case 'receptionniste':
      case 'receptionist':
        return 'Réceptionniste';
      default:
        return role;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE8F7EE) : const Color(0xFFFFEDEE),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      active ? 'Actif' : 'Inactif',
      style: TextStyle(
        color: active ? AppColors.success : AppColors.secondary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _StaffSummary extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StaffSummary({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    ),
  );
}

class _EmployeeForm extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>>? employee;
  final VoidCallback onSaved;

  const _EmployeeForm({required this.employee, required this.onSaved});

  @override
  State<_EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<_EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late String _role;
  late String _status;
  bool _saving = false;

  bool get editing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final data = widget.employee?.data() ?? const <String, dynamic>{};
    _firstName = TextEditingController(text: data['prenom']?.toString());
    _lastName = TextEditingController(text: data['nom']?.toString());
    _email = TextEditingController(text: data['email']?.toString());
    _phone = TextEditingController(text: data['telephone']?.toString());
    _password = TextEditingController();
    _role = data['role']?.toString() ?? 'opticien';
    _status = data['statut']?.toString() ?? 'actif';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<FirebaseApp> _secondaryApp() async {
    const appName = 'gav-admin-account-creation';
    for (final app in Firebase.apps) {
      if (app.name == appName) return app;
    }
    return Firebase.initializeApp(
      name: appName,
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDmPTVyw37n0KlIYk0jQwYAworO9vWn3RM',
        appId: '1:776269290873:android:12c64db793959f07fe23a8',
        messagingSenderId: '776269290873',
        projectId: 'gav-mobile-b2e2a',
        storageBucket: 'gav-mobile-b2e2a.firebasestorage.app',
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final users = FirebaseFirestore.instance.collection(
        FirebaseConstants.usersCollection,
      );
      final firestore = FirebaseFirestore.instance;
      final personnel = firestore.collection(
        FirebaseConstants.personnelCollection,
      );
      final patients = firestore.collection(
        FirebaseConstants.patientsCollection,
      );
      String uid;
      if (editing) {
        uid = widget.employee!.id;
        final data = {
          'nom': _lastName.text.trim(),
          'prenom': _firstName.text.trim(),
          'telephone': _phone.text.trim(),
          'role': _role,
          'statut': _status,
        };
        final batch = firestore.batch();
        batch.update(users.doc(uid), data);
        batch.set(personnel.doc(uid), data, SetOptions(merge: true));
        batch.delete(patients.doc(uid));
        await batch.commit();
      } else {
        final app = await _secondaryApp();
        final credential = await FirebaseAuth.instanceFor(app: app)
            .createUserWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
        uid = credential.user!.uid;
        final data = {
          'nom': _lastName.text.trim(),
          'prenom': _firstName.text.trim(),
          'sexe': '',
          'dateNaissance': Timestamp.fromDate(DateTime(1970, 1, 1)),
          'telephone': _phone.text.trim(),
          'email': _email.text.trim(),
          'photo': '',
          'role': _role,
          'statut': _status,
          'adresse': '',
          'createdAt': FieldValue.serverTimestamp(),
        };
        final batch = firestore.batch();
        batch.set(users.doc(uid), data);
        batch.set(personnel.doc(uid), data);
        await batch.commit();
        await FirebaseAuth.instanceFor(app: app).signOut();
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editing ? 'Employe modifie.' : 'Compte employe cree.'),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) _showError(error.message ?? 'Erreur Firebase.');
    } catch (error) {
      if (mounted) _showError(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        editing ? 'Modifier un employé' : 'Ajouter un employé',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  editing
                      ? 'Mettez à jour les informations et les accès.'
                      : 'Créez un accès sécurisé pour un membre de l’équipe.',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                const _FormSectionLabel(label: 'Identité'),
                _field(_firstName, 'Prenom'),
                _field(_lastName, 'Nom'),
                const SizedBox(height: 4),
                const _FormSectionLabel(label: 'Coordonnées et accès'),
                _field(
                  _email,
                  'Adresse email',
                  enabled: !editing,
                  keyboardType: TextInputType.emailAddress,
                ),
                _field(
                  _phone,
                  'Telephone',
                  keyboardType: TextInputType.phone,
                  required: false,
                ),
                if (!editing)
                  _field(_password, 'Mot de passe temporaire', obscure: true),
                const SizedBox(height: 4),
                const _FormSectionLabel(label: 'Permissions'),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: InputDecoration(
                    labelText: 'Rôle',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'opticien',
                      child: Text('Opticien'),
                    ),
                    DropdownMenuItem(
                      value: 'receptionniste',
                      child: Text('Receptionniste'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Administrateur'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _role = value ?? 'opticien'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: InputDecoration(
                    labelText: 'Statut du compte',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'actif', child: Text('Actif')),
                    DropdownMenuItem(value: 'inactif', child: Text('Inactif')),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'actif'),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool enabled = true,
    bool obscure = false,
    bool required = true,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF8FAFD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          suffixIcon: IconButton(
            onPressed: controller.clear,
            icon: const Icon(Icons.clear),
          ),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Champ obligatoire'
                  : null
            : null,
      ),
    );
  }
}

class _FormSectionLabel extends StatelessWidget {
  final String label;

  const _FormSectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _EmptyPersonnel extends StatelessWidget {
  const _EmptyPersonnel();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Column(
      children: [
        Icon(Icons.badge_outlined, size: 46, color: AppColors.primary),
        SizedBox(height: 10),
        Text('Aucun membre du personnel trouve.'),
      ],
    ),
  );
}
