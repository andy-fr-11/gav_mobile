import 'package:dio/dio.dart';

class ChatbotService {
  ChatbotService({Dio? client}) : _client = client ?? Dio();

  static const String endpoint = String.fromEnvironment('CHATBOT_API_URL');
  final Dio _client;

  bool get isConfigured => endpoint.trim().isNotEmpty;

  Future<String> sendMessage({
    required String message,
    required List<ChatbotTurn> history,
  }) async {
    if (!isConfigured) {
      throw const ChatbotUnavailableException();
    }

    final response = await _client.post<Map<String, dynamic>>(
      endpoint,
      data: {
        'message': message,
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
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final data = response.data;
    final reply = data?['reply'] ?? data?['message'] ?? data?['content'];
    if (reply is! String || reply.trim().isEmpty) {
      throw const ChatbotResponseException();
    }

    return reply.trim();
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
