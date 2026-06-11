import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // Needed for debugPrint

class GeminiVisionService {
  final String apiKey;
  // Using the active, stable 2.5 flash model
  final String _model = 'gemini-2.5-flash';

  GeminiVisionService(this.apiKey);

  Future<Map<String, dynamic>> analyzeSkin(File imageFile) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
    );

    try {
      // 1. Read and encode the image
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Determine MIME type based on file extension
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mimeType = (extension == 'png') ? 'image/png' : 'image/jpeg';

      // 2. Define the exact prompt for structured JSON
      const prompt = '''
Analyze this facial image and return ONLY valid JSON with this exact structure:
{
  "skinType": "Combination" | "Oily" | "Dry" | "Normal" | "Sensitive",
  "skinTone": "Fair" | "Medium" | "Olive" | "Brown" | "Dark",
  "undertone": "Cool" | "Warm" | "Neutral",
  "conditions": [
    {"name": "Acne", "percentage": 0-100},
    {"name": "Pigmentation", "percentage": 0-100},
    {"name": "DarkCircles", "percentage": 0-100},
    {"name": "Wrinkles", "percentage": 0-100},
    {"name": "EnlargedPores", "percentage": 0-100}
  ],
  "confidenceScore": 0.0-1.0,
  "summary": "A brief natural language summary of the analysis."
}''';

      // 3. Construct the request body
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {"mime_type": mimeType, "data": base64Image},
              },
            ],
          },
        ],
        "generationConfig": {
          "responseMimeType": "application/json",
          "temperature": 0.1,
        },
      });

      // 4. Send the request with Retry Logic for 503 errors
      const int maxRetries = 3;
      http.Response? response;

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        if (response.statusCode == 200) {
          // Success! Break out of the retry loop.
          break;
        } else if (response.statusCode == 503 && attempt < maxRetries) {
          // Server overloaded. Wait for a moment before retrying.
          debugPrint('Gemini overloaded (503). Retrying attempt $attempt...');
          await Future.delayed(
            Duration(seconds: 2 * attempt),
          ); // Backoff: 2s, 4s...
        } else if (attempt == maxRetries) {
          // Ran out of retries or hit a different error
          throw Exception(
            'Gemini API Error: ${response.statusCode} - ${response.body}',
          );
        }
      }

      // 5. Handle the successful response
      // We know response is not null here if it didn't throw in the loop
      final jsonResponse = jsonDecode(response!.body);

      // Extract the text output from Gemini's response structure
      final content =
          jsonResponse['candidates'][0]['content']['parts'][0]['text'];

      // Parse the clean JSON string into a Dart Map
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to analyze skin image: $e');
    }
  }
}
