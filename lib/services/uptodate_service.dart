import 'package:http/http.dart' as http;
import 'libook_auth_service.dart';
import '../models/drug_model.dart';

class UpToDateService {
  final LibookAuthService _authService = LibookAuthService();
  static const String _baseUrl = 'https://utd.libook.xyz';

  // Search drug in UpToDate
  Future<List<UpToDateDrugResult>> searchDrug(String query) async {
    try {
      final headers = await _authService.getAuthHeaders();

      // TODO: Replace with actual UpToDate API endpoint
      final response = await http.get(
        Uri.parse('$_baseUrl/api/search?q=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // TODO: Parse actual response when API is available
        // final data = json.decode(response.body);
        return []; // TODO: Parse actual response
      }
      return [];
    } catch (e) {
      print('Error searching UpToDate: $e');
      return [];
    }
  }

  // Get drug monograph
  Future<String?> getDrugMonograph(String drugId) async {
    try {
      final headers = await _authService.getAuthHeaders();

      // TODO: Replace with actual UpToDate API endpoint
      final response = await http.get(
        Uri.parse('$_baseUrl/api/monograph/$drugId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      print('Error getting monograph: $e');
      return null;
    }
  }

  // Check drug availability in UpToDate
  Future<bool> isDrugAvailable(Drug drug) async {
    try {
      final results = await searchDrug(drug.name);
      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

class UpToDateDrugResult {
  final String id;
  final String title;
  final String? description;

  UpToDateDrugResult({
    required this.id,
    required this.title,
    this.description,
  });
}

