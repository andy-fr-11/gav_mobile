import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'services/chatbot_service.dart';
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
  final ChatbotService _chatbotService = ChatbotService();
  bool _isSending = false;
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          'Bonjour, je suis l’assistant GAV. Je peux vous orienter sur nos services, rendez-vous, commandes, équipements et questions fréquentes. Je protège aussi vos informations personnelles et médicales en ne demandant que ce qui est nécessaire.',
      isUser: false,
    ),
  ];

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final history = [
      for (final message in _messages)
        ChatbotTurn(
          role: message.isUser ? 'user' : 'assistant',
          content: message.text,
        ),
    ];

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
    });

    _messageController.clear();

    String answer;
    try {
      answer =
          await _findConfiguredReply(text) ??
          await _chatbotService.sendMessage(message: text, history: history);
    } catch (_) {
      answer = _ChatbotAssistant.generateReply(text);
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
              child: ListView.separated(
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

class _ChatbotAssistant {
  static String generateReply(String rawMessage) {
    final message = _normalize(rawMessage);

    if (_containsAny(message, ['bonjour', 'salut', 'bonsoir', 'coucou'])) {
      return 'Bonjour ! Je peux vous aider sur les services, les rendez-vous, les commandes, les équipements et les questions fréquentes de GAV SmartVision.';
    }

    if (_containsAny(message, [
      'rendez',
      'rdv',
      'prise',
      'consultation',
      'appointment',
    ])) {
      return 'Pour prendre un rendez-vous, rendez-vous dans la section Rendez-vous de l’application. Je peux aussi vous aider à choisir le bon service selon votre besoin (consultation, contrôle visuel, lunettes, suivi post-opératoire).';
    }

    if (_containsAny(message, [
      'service',
      'prestations',
      'consultation',
      'controle',
      'exam',
      'lunette',
      'verre',
      'optique',
    ])) {
      return 'GAV SmartVision propose : consultation optique, contrôle visuel, lunettes et verres, suivi de correction visuelle, ainsi que des conseils sur les équipements et accessoires optiques.';
    }

    if (_containsAny(message, [
      'commande',
      'suivi commande',
      'ma commande',
      'etat commande',
      'livraison',
    ])) {
      return 'Vous pouvez suivre l’état de vos commandes depuis l’écran des commandes. Si vous avez besoin d’un détail spécifique sur une commande, je peux vous orienter vers le bon statut ou vers un agent.';
    }

    if (_containsAny(message, [
      'equipement',
      'materiel',
      'matériel',
      'appareil',
      'machine',
      'lentille',
    ])) {
      return 'Pour les questions sur les équipements et appareils optiques, nous pouvons vous orienter vers le service technique ou la maintenance. Les informations personnelles et médicales restent protégées et ne doivent pas être partagées librement dans le chat.';
    }

    if (_containsAny(message, [
      'faq',
      'question',
      'info',
      'information',
      'prix',
      'tarif',
    ])) {
      return 'Les questions fréquentes portent généralement sur les consultations, les délais de livraison, les types de verres et la prise de rendez-vous. Si votre demande est plus spécifique, je peux vous orienter vers un agent humain.';
    }

    if (_containsAny(message, [
      'agent',
      'humaine',
      'personne',
      'recontact',
      'contact',
    ])) {
      return 'Votre demande nécessite probablement une intervention humaine. Vous pouvez demander à un agent du cabinet et il vous orientera vers le bon service pour une réponse personnalisée.';
    }

    if (_containsAny(message, ['merci', 'thank', 'ok', 'daccord'])) {
      return 'Avec plaisir. Je reste disponible pour vous aider sur les services, les rendez-vous et le suivi de vos demandes GAV.';
    }

    return 'Je peux vous aider sur les services GAV, les rendez-vous, les commandes, les équipements et les questions fréquentes. Si vous voulez, je peux aussi vous orienter vers un agent humain.';
  }

  static bool _containsAny(String input, List<String> keywords) {
    for (final keyword in keywords) {
      if (input.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  }
}
