import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/drug_model.dart';
import 'storage_service.dart';

class ApiService {
  static const String _apiUrl =
      'https://register.ndda.kz/register-backend/RegisterService/list';

  final StorageService _storageService = StorageService();

  // Fetch drugs from API
  Future<List<Drug>> fetchDrugsFromApi() async {
    try {
      // Prepare request body with required parameters
      final requestBody = jsonEncode({'regTypeId': 1, 'regPeriod': 1});

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;
        final drugs = jsonList.map((json) => Drug.fromJson(json)).toList();

        // Save to local storage
        await _storageService.saveDrugs(drugs);

        return drugs;
      } else {
        throw Exception('Failed to load drugs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching drugs: $e');
      rethrow;
    }
  }

  // Get drugs (from cache or API)
  Future<List<Drug>> getDrugs({bool forceRefresh = false}) async {
    try {
      // Check if we should use cache
      if (!forceRefresh) {
        final hasCached = await _storageService.hasCachedDrugs();
        if (hasCached) {
          final cachedDrugs = await _storageService.loadDrugs();
          if (cachedDrugs.isNotEmpty) {
            return cachedDrugs;
          }
        }
      }

      // Fetch from API
      return await fetchDrugsFromApi();
    } catch (e) {
      print('Error getting drugs: $e');

      // Try to load from cache as fallback
      try {
        final cachedDrugs = await _storageService.loadDrugs();
        if (cachedDrugs.isNotEmpty) {
          return cachedDrugs;
        }
      } catch (cacheError) {
        print('Error loading cache: $cacheError');
      }

      rethrow;
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    await _storageService.clearDrugsCache();
  }
}
