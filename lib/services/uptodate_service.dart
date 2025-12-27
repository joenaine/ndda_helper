import 'dart:convert';
import 'package:http/http.dart' as http;
import 'libook_auth_service.dart';
import '../models/drug_model.dart';
import '../models/uptodate_search_result.dart';

class UpToDateService {
  final LibookAuthService _authService = LibookAuthService();
  static const String _baseUrl = 'https://utd.libook.xyz';

  // Autocomplete search
  // NOTE: This method is no longer used - we use WebView JavaScript for authenticated calls
  Future<List<UpToDateSearchResult>> autocompleteSearch(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final headers = await _authService.getAuthHeaders();
      final url = '$_baseUrl/api/search/autocomplete?term=${Uri.encodeComponent(query)}';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((item) => UpToDateSearchResult.fromJson(item))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error searching UpToDate: $e');
      return [];
    }
  }

  // Search drug in UpToDate (legacy method)
  Future<List<UpToDateDrugResult>> searchDrug(String query) async {
    try {
      final results = await autocompleteSearch(query);
      return results
          .map((r) => UpToDateDrugResult(
                id: r.english,
                title: r.display,
                description: null,
              ))
          .toList();
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

