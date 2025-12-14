import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/drug_model.dart';

class StorageService {
  static const String _drugsBoxName = 'drugs_box';
  static const String _selectedDrugsBoxName = 'selected_drugs_box';
  static const String _drugsKey = 'cached_drugs';
  static const String _selectedDrugsKey = 'selected_drugs';

  late Box<String> _drugsBox;
  late Box<String> _selectedDrugsBox;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      _drugsBox = await Hive.openBox<String>(_drugsBoxName);
      _selectedDrugsBox = await Hive.openBox<String>(_selectedDrugsBoxName);
      _initialized = true;
    }
  }

  // Save drugs list to local storage
  Future<void> saveDrugs(List<Drug> drugs) async {
    try {
      await _ensureInitialized();
      final jsonList = drugs.map((drug) => drug.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _drugsBox.put(_drugsKey, jsonString);
    } catch (e) {
      print('Error saving drugs: $e');
      rethrow;
    }
  }

  // Load drugs list from local storage
  Future<List<Drug>> loadDrugs() async {
    try {
      await _ensureInitialized();
      final jsonString = _drugsBox.get(_drugsKey);

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
      await _ensureInitialized();
      final jsonString = _drugsBox.get(_drugsKey);
      return jsonString != null && jsonString.isNotEmpty;
    } catch (e) {
      print('Error checking cache: $e');
      return false;
    }
  }

  // Clear cached drugs
  Future<void> clearDrugsCache() async {
    try {
      await _ensureInitialized();
      await _drugsBox.delete(_drugsKey);
    } catch (e) {
      print('Error clearing cache: $e');
      rethrow;
    }
  }

  // Save selected drugs IDs
  Future<void> saveSelectedDrugs(Set<int> selectedIds) async {
    try {
      await _ensureInitialized();
      final jsonString = jsonEncode(selectedIds.toList());
      await _selectedDrugsBox.put(_selectedDrugsKey, jsonString);
    } catch (e) {
      print('Error saving selected drugs: $e');
      rethrow;
    }
  }

  // Load selected drugs IDs
  Future<Set<int>> loadSelectedDrugs() async {
    try {
      await _ensureInitialized();
      final jsonString = _selectedDrugsBox.get(_selectedDrugsKey);

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
      await _ensureInitialized();
      await _selectedDrugsBox.delete(_selectedDrugsKey);
    } catch (e) {
      print('Error clearing selected drugs: $e');
      rethrow;
    }
  }
}
