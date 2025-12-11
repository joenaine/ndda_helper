import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/drug_model.dart';

class StorageService {
  static const String _drugsKey = 'cached_drugs';
  static const String _selectedDrugsKey = 'selected_drugs';

  // Save drugs list to local storage
  Future<void> saveDrugs(List<Drug> drugs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = drugs.map((drug) => drug.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_drugsKey, jsonString);
    } catch (e) {
      print('Error saving drugs: $e');
      rethrow;
    }
  }

  // Load drugs list from local storage
  Future<List<Drug>> loadDrugs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_drugsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => Drug.fromJson(json)).toList();
    } catch (e) {
      print('Error loading drugs: $e');
      return [];
    }
  }

  // Check if drugs are cached
  Future<bool> hasCachedDrugs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_drugsKey);
      return jsonString != null && jsonString.isNotEmpty;
    } catch (e) {
      print('Error checking cache: $e');
      return false;
    }
  }

  // Clear cached drugs
  Future<void> clearDrugsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_drugsKey);
    } catch (e) {
      print('Error clearing cache: $e');
      rethrow;
    }
  }

  // Save selected drugs IDs
  Future<void> saveSelectedDrugs(Set<int> selectedIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(selectedIds.toList());
      await prefs.setString(_selectedDrugsKey, jsonString);
    } catch (e) {
      print('Error saving selected drugs: $e');
      rethrow;
    }
  }

  // Load selected drugs IDs
  Future<Set<int>> loadSelectedDrugs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_selectedDrugsKey);

      if (jsonString == null || jsonString.isEmpty) {
        return {};
      }

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((id) => id as int).toSet();
    } catch (e) {
      print('Error loading selected drugs: $e');
      return {};
    }
  }

  // Clear selected drugs
  Future<void> clearSelectedDrugs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedDrugsKey);
    } catch (e) {
      print('Error clearing selected drugs: $e');
      rethrow;
    }
  }
}
