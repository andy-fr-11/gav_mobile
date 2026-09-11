import 'package:dio/dio.dart';

import '../../../config/openai_config.dart';

class ChatbotService {
  ChatbotService({Dio? client}) : _client = client ?? Dio();

  final Dio _client;

  bool get isConfigured => OpenAIConfig.backendUrl.trim().isNotEmpty;

  Future<String> sendMessage({
    required String message,
    required List<ChatbotTurn> history,
  }) async {
    if (!isConfigured) {
      throw const ChatbotUnavailableException();
    }

    try {
      final response = await _client.post<Map<String, dynamic>>(
        OpenAIConfig.backendUrl,
        data: {
          'question': message,
          'history': [
            for (final turn in history)
              {'role': turn.role, 'content': turn.content},
          ],
          'locale': 'fr-FR',
          'scope': 'gav_smartvision',
        },
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;
      final reply = data?['reply'] ?? data?['message'] ?? data?['content'];
      if (reply is! String || reply.trim().isEmpty) {
        throw const ChatbotResponseException();
      }

      return reply.trim();
    } on DioException catch (_) {
      throw const ChatbotUnavailableException();
    }
  }
}

class ChatbotTurn {
  final String role;
  final String content;

  const ChatbotTurn({required this.role, required this.content});
}

class ChatbotUnavailableException implements Exception {
  const ChatbotUnavailableException();
}

class ChatbotResponseException implements Exception {
  const ChatbotResponseException();
}
