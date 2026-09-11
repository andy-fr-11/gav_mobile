class OpenAIConfig {
  static const bool enabled = false;
  static const String apiKey = '';
  static const String model = 'gpt-4o-mini';
  static const String backendUrl = String.fromEnvironment(
    'CHATBOT_API_URL',
    defaultValue: 'https://us-central1-gav-mobile-b2e2a.cloudfunctions.net/gavChatbot',
  );
}
