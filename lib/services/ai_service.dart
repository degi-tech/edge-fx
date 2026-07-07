import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  final String _apiKey;
  late final GenerativeModel _model;

  AiService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
    );
  }

  Future<String> getTradingAdvice(List<double> prices) async {
    if (prices.isEmpty) return "No data available.";
    
    final prompt = '''
    Act as a professional forex and synthetic indices trader. 
    Analyze the following recent tick prices: ${prices.join(', ')}.
    Provide a brief sentiment analysis (Bullish, Bearish, or Neutral) and a reason why.
    Keep it concise.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Unable to get advice.";
    } catch (e) {
      return "Error: $e";
    }
  }
}
