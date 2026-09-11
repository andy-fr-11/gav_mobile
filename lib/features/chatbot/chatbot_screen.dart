import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/local_chatbot_service.dart';
import '../../core/constants/firebase_constants.dart';
import '../appointment/appointment_screen.dart';
import '../boutique/boutique_screen.dart';
import '../dashboard/patient_bottom_navigation_bar.dart';
import '../patient/profile_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;
  bool _isLoadingHistory = true;
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Bonjour, je suis l’assistant GAV. Je peux vous orienter sur nos services, rendez-vous, commandes, équipements et questions fréquentes. Je protège aussi vos informations personnelles et médicales en ne demandant que ce qui est nécessaire.',
      isUser: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadConversationHistory();
  }

  Future<void> _loadConversationHistory() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) setState(() => _isLoadingHistory = false);
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection(FirebaseConstants.chatbotInteractionsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final interactions = [...snapshot.docs]
        ..sort((left, right) {
          final leftDate = (left.data()['createdAt'] as Timestamp?)?.toDate();
          final rightDate = (right.data()['createdAt'] as Timestamp?)?.toDate();
          if (leftDate == null && rightDate == null) return 0;
          if (leftDate == null) return -1;
          if (rightDate == null) return 1;
          return leftDate.compareTo(rightDate);
        });
      final recentInteractions = interactions.length > 50
          ? interactions.sublist(interactions.length - 50)
          : interactions;

      if (!mounted) return;
      setState(() {
        for (final interaction in recentInteractions) {
          final data = interaction.data();
          final question = data['question']?.toString().trim();
          final answer = data['answer']?.toString().trim();
          if (question == null || question.isEmpty) continue;
          _messages.add(_ChatMessage(text: question, isUser: true));
          if (answer != null && answer.isNotEmpty) {
            _messages.add(_ChatMessage(text: answer, isUser: false));
          }
        }
        _isLoadingHistory = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
    });

    _messageController.clear();

    String answer;
    try {
      answer =
          await _findConfiguredReply(text) ??
          LocalChatbotService.generateReply(text);
    } catch (_) {
      answer = LocalChatbotService.generateReply(text);
    }

    await _recordInteraction(question: text, answer: answer);

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: answer, isUser: false));
      _isSending = false;
    });
  }

  Future<String?> _findConfiguredReply(String question) async {
    final normalized = question.toLowerCase().trim();
    final snapshot = await FirebaseFirestore.instance
        .collection(FirebaseConstants.chatbotFaqsCollection)
        .where('active', isEqualTo: true)
        .get();

    for (final faq in snapshot.docs) {
      final data = faq.data();
      final faqQuestion = data['question']?.toString().toLowerCase() ?? '';
      final keywords =
          (data['keywords'] as List?)
              ?.map((item) => item.toString().toLowerCase().trim())
              .where((item) => item.isNotEmpty)
              .toList() ??
          const <String>[];
      final questionMatch =
          faqQuestion.isNotEmpty &&
          (normalized.contains(faqQuestion) ||
              faqQuestion.contains(normalized));
      final keywordMatch = keywords.any(normalized.contains);
      if (questionMatch || keywordMatch) {
        final answer = data['answer']?.toString().trim();
        if (answer != null && answer.isNotEmpty) return answer;
      }
    }
    return null;
  }

  Future<void> _recordInteraction({
    required String question,
    required String answer,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection(FirebaseConstants.chatbotInteractionsCollection)
          .add({
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'question': question,
            'answer': answer,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {
      // A history failure must not interrupt the patient conversation.
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text(
          'Assistant GAV',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF0B3DDB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE7ECF5)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _SuggestionChip(label: 'Rendez-vous'),
                  _SuggestionChip(label: 'Services'),
                  _SuggestionChip(label: 'Commandes'),
                  _SuggestionChip(label: 'FAQ'),
                  _SuggestionChip(label: 'Parler à un agent'),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? const Color(0xFF0B3DDB)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(
                                  message.isUser ? 16 : 4,
                                ),
                                bottomRight: Radius.circular(
                                  message.isUser ? 4 : 16,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : const Color(0xFF1F2D3D),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (_isLoadingHistory)
                    const Positioned(
                      top: 12,
                      right: 16,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            ),
            if (_isSending)
              const Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Assistant GAV rédige une réponse...',
                    style: TextStyle(
                      color: Color(0xFF65758B),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5EAF4))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isSending,
                      decoration: InputDecoration(
                        hintText: 'Écrivez votre message...',
                        filled: true,
                        fillColor: const Color(0xFFF4F7FB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0B3DDB), Color(0xFFEF3B2D)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: PatientBottomNavigationBar(
        selectedIndex: 3,
        onSelected: (index) {
          if (index == 3) return;
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

class _SuggestionChip extends StatelessWidget {
  final String label;

  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF0B3DDB),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}
