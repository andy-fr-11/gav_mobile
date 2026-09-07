import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/theme/app_colors.dart';

const _chatbotAccent = AppColors.primary;

class ChatbotManagementScreen extends StatefulWidget {
  const ChatbotManagementScreen({super.key});

  @override
  State<ChatbotManagementScreen> createState() =>
      _ChatbotManagementScreenState();
}

class _ChatbotManagementScreenState extends State<ChatbotManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openFaqForm({
    QueryDocumentSnapshot<Map<String, dynamic>>? faq,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FaqForm(faq: faq),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Gérer le chatbot',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _chatbotAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_chatbotAccent, Color(0xFF1764C0)],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.quiz_outlined), text: 'FAQ et informations'),
            Tab(icon: Icon(Icons.forum_outlined), text: 'Interactions'),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabs,
        builder: (context, _) => _tabs.index == 0
            ? FloatingActionButton.extended(
                onPressed: () => _openFaqForm(),
                backgroundColor: _chatbotAccent,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une FAQ'),
              )
            : const SizedBox.shrink(),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _FaqList(onEdit: _openFaqForm),
          const _InteractionList(),
        ],
      ),
    );
  }
}

class _FaqList extends StatelessWidget {
  final Future<void> Function({
    QueryDocumentSnapshot<Map<String, dynamic>>? faq,
  })
  onEdit;
  const _FaqList({required this.onEdit});

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection(FirebaseConstants.chatbotFaqsCollection)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return _ChatbotMessage(
          text: 'Impossible de charger les informations.',
          detail: snapshot.error.toString(),
        );
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator());
      final docs = snapshot.data!.docs;
      if (docs.isEmpty)
        return const _ChatbotMessage(
          text: 'Aucune FAQ configurée.',
          detail:
              'Ajoutez les informations que le chatbot doit transmettre aux patients.',
        );
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
        children: [
          _KnowledgeHeader(count: docs.length),
          const SizedBox(height: 16),
          ...docs.map(
            (faq) => _FaqCard(
              faq: faq,
              onEdit: () => onEdit(faq: faq),
            ),
          ),
        ],
      );
    },
  );
}

class _KnowledgeHeader extends StatelessWidget {
  final int count;
  const _KnowledgeHeader({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [_chatbotAccent, Color(0xFF1764C0)],
      ),
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x260A3D91),
          blurRadius: 15,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Base de connaissances',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Maintenez les réponses données aux patients.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: Colors.white24,
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FaqCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> faq;
  final VoidCallback onEdit;
  const _FaqCard({required this.faq, required this.onEdit});

  Future<void> _delete(BuildContext context) async {
    await faq.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    final data = faq.data();
    final active = data['active'] != false;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    data['question']?.toString() ?? 'Question sans titre',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') _delete(context);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['answer']?.toString() ?? 'Réponse non renseignée',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  active
                      ? Icons.check_circle_outline
                      : Icons.visibility_off_outlined,
                  size: 16,
                  color: active ? AppColors.success : AppColors.mutedText,
                ),
                const SizedBox(width: 6),
                Text(
                  active ? 'Active' : 'Désactivée',
                  style: TextStyle(
                    color: active ? AppColors.success : AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Mots-clés : ${data['keywords'] ?? 'aucun'}',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqForm extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>>? faq;
  const _FaqForm({this.faq});

  @override
  State<_FaqForm> createState() => _FaqFormState();
}

class _FaqFormState extends State<_FaqForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _question;
  late final TextEditingController _answer;
  late final TextEditingController _keywords;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.faq?.data() ?? const <String, dynamic>{};
    _question = TextEditingController(text: data['question']?.toString());
    _answer = TextEditingController(text: data['answer']?.toString());
    final keywords = data['keywords'];
    _keywords = TextEditingController(
      text: keywords is List ? keywords.join(', ') : keywords?.toString(),
    );
    _active = data['active'] != false;
  }

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    _keywords.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final data = {
      'question': _question.text.trim(),
      'answer': _answer.text.trim(),
      'keywords': _keywords.text
          .split(',')
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toList(),
      'active': _active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      if (widget.faq == null) {
        await FirebaseFirestore.instance
            .collection(FirebaseConstants.chatbotFaqsCollection)
            .add({...data, 'createdAt': FieldValue.serverTimestamp()});
      } else {
        await widget.faq!.reference.update(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enregistrement impossible : $error')),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
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
              Text(
                widget.faq == null ? 'Ajouter une FAQ' : 'Modifier la FAQ',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _question,
                decoration: const InputDecoration(
                  labelText: 'Question du patient',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Champ obligatoire'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _answer,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Réponse fournie par le chatbot',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Champ obligatoire'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keywords,
                decoration: const InputDecoration(
                  labelText: 'Mots-clés séparés par des virgules',
                  hintText: 'prix, rendez-vous, lunettes',
                ),
              ),
              SwitchListTile(
                value: _active,
                onChanged: (value) => setState(() => _active = value),
                title: const Text('Information active dans le chatbot'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _chatbotAccent,
                  minimumSize: const Size.fromHeight(50),
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

class _InteractionList extends StatelessWidget {
  const _InteractionList();

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(FirebaseConstants.chatbotInteractionsCollection)
            .orderBy('createdAt', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return _ChatbotMessage(
              text: 'Impossible de charger les interactions.',
              detail: snapshot.error.toString(),
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty)
            return const _ChatbotMessage(
              text: 'Aucune interaction enregistrée.',
            );
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final data = docs[index].data();
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEAF1FF),
                    child: Icon(Icons.chat_outlined, color: _chatbotAccent),
                  ),
                  title: Text(
                    data['question']?.toString() ?? 'Question',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    data['answer']?.toString() ?? 'Réponse',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _formatDate(data['createdAt']),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
}

class _ChatbotMessage extends StatelessWidget {
  final String text;
  final String? detail;
  const _ChatbotMessage({required this.text, this.detail});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.smart_toy_outlined, color: _chatbotAccent, size: 42),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

String _formatDate(dynamic value) {
  if (value is Timestamp) {
    final date = value.toDate();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
  return '--/--';
}
