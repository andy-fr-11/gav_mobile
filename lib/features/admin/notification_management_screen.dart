import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

const _notificationAccent = AppColors.secondary;

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends State<NotificationManagementScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _audience = 'all';
  String _type = 'general';
  bool _sending = false;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      FirebaseFirestore.instance.collection(
        FirebaseConstants.notificationsCollection,
      );

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _recipients() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .get();
    return snapshot.docs.where((doc) {
      if (_audience == 'patients') {
        return doc.data()['role']?.toString().toLowerCase() == 'patient';
      }
      return true;
    }).toList();
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) {
      _showMessage('Renseignez le titre et le message.');
      return;
    }

    setState(() => _sending = true);
    try {
      final recipients = await _recipients();
      if (recipients.isEmpty) {
        _showMessage('Aucun destinataire trouvé.');
        return;
      }
      await _writeNotifications(
        recipients.map((doc) => doc.id).toList(),
        title: title,
        message: message,
        type: _type,
      );
      _titleController.clear();
      _messageController.clear();
      _showMessage(
        'Notification enregistrée pour ${recipients.length} utilisateur(s).',
      );
    } catch (error) {
      _showMessage('Envoi impossible : $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _writeNotifications(
    List<String> userIds, {
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    for (var start = 0; start < userIds.length; start += 450) {
      final ids = userIds.skip(start).take(450);
      final batch = FirebaseFirestore.instance.batch();
      for (final userId in ids) {
        final ref = _notifications.doc();
        batch.set(ref, {
          'userId': userId,
          'title': title,
          'message': message,
          'type': type,
          'relatedId': relatedId,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Future<void> _sendBirthdayReminders() async {
    setState(() => _sending = true);
    try {
      final users = await FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .get();
      final today = DateTime.now();
      final recipients = users.docs.where((doc) {
        final value = doc.data()['dateNaissance'];
        final date = value is Timestamp ? value.toDate() : null;
        return date != null &&
            date.month == today.month &&
            date.day == today.day;
      }).toList();
      if (recipients.isEmpty) {
        _showMessage('Aucun anniversaire à notifier aujourd’hui.');
        return;
      }
      await _writeNotifications(
        recipients.map((doc) => doc.id).toList(),
        title: 'Joyeux anniversaire !',
        message: 'Toute l’équipe GAV vous souhaite une excellente journée.',
        type: 'birthday',
      );
      _showMessage('${recipients.length} anniversaire(s) notifié(s).');
    } catch (error) {
      _showMessage('Impossible de traiter les anniversaires : $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendOperationalReminders(String kind) async {
    setState(() => _sending = true);
    try {
      final collection = FirebaseFirestore.instance.collection(
        kind == 'appointment'
            ? FirebaseConstants.appointmentsCollection
            : FirebaseConstants.ordersCollection,
      );
      final snapshot = await collection.get();
      final userIds = snapshot.docs
          .map((doc) => doc.data()['patientId']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
      if (userIds.isEmpty) {
        _showMessage('Aucun utilisateur concerné trouvé.');
        return;
      }
      await _writeNotifications(
        userIds,
        title: kind == 'appointment'
            ? 'Rappel de rendez-vous'
            : 'Mise à jour de votre commande',
        message: kind == 'appointment'
            ? 'Consultez votre rendez-vous GAV dans l’application.'
            : 'Consultez le suivi de votre commande GAV dans l’application.',
        type: kind,
      );
      _showMessage('${userIds.length} utilisateur(s) notifié(s).');
    } catch (error) {
      _showMessage('Notification impossible : $error');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Gérer les notifications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: _notificationAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_notificationAccent, Color(0xFFB21F27)],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          _NotificationHeader(),
          const SizedBox(height: 16),
          _ComposerCard(
            titleController: _titleController,
            messageController: _messageController,
            audience: _audience,
            type: _type,
            sending: _sending,
            onAudienceChanged: (value) => setState(() => _audience = value),
            onTypeChanged: (value) => setState(() => _type = value),
            onSend: _sendNotification,
          ),
          const SizedBox(height: 16),
          const Text(
            'Raccourcis automatiques',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.cake_outlined,
            title: 'Anniversaires du jour',
            subtitle: 'Notifier les patients concernés',
            onTap: _sending ? null : _sendBirthdayReminders,
          ),
          _QuickAction(
            icon: Icons.calendar_month_outlined,
            title: 'Rendez-vous',
            subtitle: 'Envoyer un rappel aux patients concernés',
            onTap: _sending
                ? null
                : () => _sendOperationalReminders('appointment'),
          ),
          _QuickAction(
            icon: Icons.shopping_bag_outlined,
            title: 'Commandes',
            subtitle: 'Informer les patients du suivi de commande',
            onTap: _sending ? null : () => _sendOperationalReminders('order'),
          ),
          _QuickAction(
            icon: Icons.event_available_outlined,
            title: 'Événement annuel',
            subtitle: 'Utiliser le formulaire pour une campagne générale',
            onTap: () => setState(() {
              _type = 'annual_event';
              _titleController.text = 'Événement GAV';
              _messageController.text =
                  'Découvrez les actualités et événements de GAV.';
            }),
          ),
        ],
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_notificationAccent, Color(0xFFB21F27)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24D62828),
          blurRadius: 15,
          offset: Offset(0, 7),
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
                'Centre de communication',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Informez les patients au bon moment.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        Icon(
          Icons.notifications_active_outlined,
          color: Colors.white,
          size: 34,
        ),
      ],
    ),
  );
}

class _ComposerCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController messageController;
  final String audience;
  final String type;
  final bool sending;
  final ValueChanged<String> onAudienceChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSend;

  const _ComposerCard({
    required this.titleController,
    required this.messageController,
    required this.audience,
    required this.type,
    required this.sending,
    required this.onAudienceChanged,
    required this.onTypeChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nouvelle notification',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Titre',
            prefixIcon: Icon(Icons.title),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: messageController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Message',
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.message_outlined),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: audience,
          decoration: const InputDecoration(labelText: 'Destinataires'),
          items: const [
            DropdownMenuItem(
              value: 'all',
              child: Text('Tous les utilisateurs'),
            ),
            DropdownMenuItem(
              value: 'patients',
              child: Text('Tous les patients'),
            ),
          ],
          onChanged: (value) => onAudienceChanged(value ?? 'all'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: type,
          decoration: const InputDecoration(labelText: 'Type de notification'),
          items: const [
            DropdownMenuItem(
              value: 'general',
              child: Text('Information générale'),
            ),
            DropdownMenuItem(value: 'appointment', child: Text('Rendez-vous')),
            DropdownMenuItem(value: 'order', child: Text('Commande')),
            DropdownMenuItem(
              value: 'annual_event',
              child: Text('Événement annuel'),
            ),
          ],
          onChanged: (value) => onTypeChanged(value ?? 'general'),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: sending ? null : onSend,
          style: FilledButton.styleFrom(
            backgroundColor: _notificationAccent,
            minimumSize: const Size.fromHeight(50),
          ),
          icon: sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_outlined),
          label: Text(sending ? 'Envoi...' : 'Envoyer la notification'),
        ),
      ],
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFFECEC),
        child: Icon(icon, color: _notificationAccent),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}
