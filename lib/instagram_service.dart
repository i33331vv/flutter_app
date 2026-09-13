import 'dart:convert';
import 'package:http/http.dart' as http;

class InstagramService {
  static const String serverUrl = 'https://instagram-server-by7b.onrender.com';

  // دالة المتابعة التي يحتاجها تطبيق الفلاتر
  static Future<bool> followUser(String sessionId, String targetUsername) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/api/follow'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sessionid': sessionId, 'target_username': targetUsername}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}