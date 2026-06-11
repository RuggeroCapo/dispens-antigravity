import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class AiExtractionResult {
  final String name;
  final String description;
  final DateTime? expirationDate;

  AiExtractionResult({
    required this.name,
    required this.description,
    this.expirationDate,
  });
}

class AiService {
  // Use a constant that can be provided at compile time: --dart-define=GEMINI_API_KEY=your_key
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static Future<AiExtractionResult?> extractFoodInfo(XFile imageFile) async {
    if (_apiKey.isEmpty) {
      if (kDebugMode) {
        print("Please provide a valid Gemini API key via --dart-define=GEMINI_API_KEY=...");
      }
      throw Exception("Manca la chiave API di Gemini. Aggiungila con --dart-define=GEMINI_API_KEY=...");
    }

    final model = GenerativeModel(
      model: 'gemini-3.1-flash-lite-preview',
      apiKey: _apiKey,
    );

    final prompt = TextPart('''
You are an AI that extracts food information from images for an Italian app.
Please extract the following information from the provided image:
1. "name": The name of the food item (in Italian).
2. "description": A short description of the food item (in Italian).
3. "expirationDate": The expiration date if visible. Format as YYYY-MM-DD. If not visible or not confidently readable, return null.

Return ONLY a valid JSON object with these keys: "name" (string), "description" (string), "expirationDate" (string or null). Make sure the output is pure JSON without markdown blocks.
''');

    final imageBytes = await imageFile.readAsBytes();
    
    // Determine mimeType
    final path = imageFile.path.toLowerCase();
    String mimeType = 'image/jpeg';
    if (path.endsWith('.png')) mimeType = 'image/png';
    else if (path.endsWith('.webp')) mimeType = 'image/webp';
    else if (path.endsWith('.heic')) mimeType = 'image/heic';
    else if (path.endsWith('.heif')) mimeType = 'image/heif';

    final imagePart = DataPart(mimeType, imageBytes);

    try {
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      var text = response.text ?? '';
      // Strip markdown code blocks if any
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      
      final data = jsonDecode(text);
      
      DateTime? expDate;
      if (data['expirationDate'] != null) {
        try {
          expDate = DateTime.parse(data['expirationDate']);
        } catch (_) {}
      }

      return AiExtractionResult(
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        expirationDate: expDate,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting food info: \$e');
      }
      throw Exception("Errore durante l'analisi dell'immagine: \$e");
    }
  }
}
