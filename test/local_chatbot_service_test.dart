import 'package:flutter_test/flutter_test.dart';

import 'package:gav_mobile/features/chatbot/services/gav_knowledge_base.dart';
import 'package:gav_mobile/features/chatbot/services/local_chatbot_service.dart';

void main() {
  group('GAV knowledge base', () {
    test('contains exactly 100 entries', () {
      expect(gavKnowledgeBase, hasLength(100));
      expect(
        gavKnowledgeBase.every(
          (entry) =>
              entry.keywords.isNotEmpty && entry.answer.trim().isNotEmpty,
        ),
        isTrue,
      );
    });
  });

  group('LocalChatbotService', () {
    test('answers questions about GAV location', () {
      final reply = LocalChatbotService.generateReply(
        'Ou se trouve GAV a Makepe ?',
      );

      expect(reply, contains('Makèpè'));
      expect(reply, contains('Tradex'));
    });

    test('handles accents and visual-health prevention', () {
      final reply = LocalChatbotService.generateReply(
        'Comment réduire la fatigue des yeux devant un écran ?',
      );

      expect(reply, contains('20-20-20'));
      expect(reply, contains('pauses'));
    });

    test('gives contact-lens hygiene guidance', () {
      final reply = LocalChatbotService.generateReply(
        'Comment nettoyer mes lentilles ?',
      );

      expect(reply, contains('mains'));
      expect(reply, contains('eau du robinet'));
    });

    test('warns about potentially urgent visual symptoms', () {
      final reply = LocalChatbotService.generateReply(
        'J ai une perte brutale de vision',
      );

      expect(reply, contains('urgence'));
      expect(reply, contains('professionnel de santé'));
    });

    test('does not invent missing opening hours', () {
      final reply = LocalChatbotService.generateReply(
        'Quels sont les horaires de GAV ?',
      );

      expect(reply, contains('horaires'));
      expect(reply, contains('accueil GAV'));
    });
  });
}
