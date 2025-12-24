import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meddra_model.dart';

class MedDraService {
  static const String _baseUrl =
      'https://www.ndda.kz/register.php/Sideeffects/MedDra';

  static Future<List<MedDraModel>> fetchMedDraData() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => MedDraModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load MedDRA data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching MedDRA data: $e');
    }
  }
}

