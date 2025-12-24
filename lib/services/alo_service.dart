import 'package:flutter/foundation.dart';
import '../models/drug_model.dart';
import '../data/alo_data.dart';

class AloService {
  static AloService? _instance;
  Set<String>? _aloCodes;
  bool _isInitialized = false;

  // Cache for check results
  final Map<int, bool> _resultCache = {};

  AloService._();

  factory AloService() {
    _instance ??= AloService._();
    return _instance!;
  }

  /// Load ALO data (instant, no parsing needed - data is compiled as Dart code)
  void loadAloData() {
    if (_isInitialized) {
      if (kDebugMode) {
        print('ALO: Already initialized');
      }
      return;
    }

    try {
      // Convert list to set for O(1) lookup
      _aloCodes = aloDrugCodes.toSet();
      _isInitialized = true;
      if (kDebugMode) {
        print('ALO: Data loaded successfully, ${_aloCodes!.length} codes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ALO data: $e');
      }
      _aloCodes = {};
      _isInitialized = true;
    }
  }

  /// Check if a drug's ATC code is in the ALO list
  /// ALO matching is based on ATC code only
  bool isDrugInAlo(Drug drug) {
    // Check cache first
    if (_resultCache.containsKey(drug.id)) {
      if (kDebugMode) {
        print('ALO: Using cached result for drug ID ${drug.id}');
      }
      return _resultCache[drug.id]!;
    }

    if (_aloCodes == null || _aloCodes!.isEmpty) {
      if (kDebugMode) {
        print(
          'ALO: Codes not loaded or empty for drug "${drug.name}" (ID: ${drug.id})',
        );
      }
      _resultCache[drug.id] = false;
      return false;
    }

    final drugAtcCode = drug.code?.trim() ?? '';
    if (drugAtcCode.isEmpty) {
      if (kDebugMode) {
        print(
          'ALO: Drug ATC code is empty for "${drug.name}" (ID: ${drug.id})',
        );
      }
      _resultCache[drug.id] = false;
      return false;
    }

    if (kDebugMode) {
      print(
        'ALO: Checking drug "${drug.name}" (ID: ${drug.id}) with ATC: $drugAtcCode',
      );
    }

    // Direct match
    if (_aloCodes!.contains(drugAtcCode)) {
      if (kDebugMode) {
        print('ALO: ✅ Direct match found for $drugAtcCode');
      }
      _resultCache[drug.id] = true;
      return true;
    }

    // Check for codes with slash (e.g., "L01EA01/L01XE01")
    // If drug code matches any part of a combined ALO code, it's in ALO
    for (final aloCode in _aloCodes!) {
      if (aloCode.contains('/')) {
        final parts = aloCode.split('/');
        for (final part in parts) {
          if (part.trim() == drugAtcCode) {
            if (kDebugMode) {
              print(
                'ALO: ✅ Match found in combined code $aloCode for $drugAtcCode',
              );
            }
            _resultCache[drug.id] = true;
            return true;
          }
        }
      }
    }

    if (kDebugMode) {
      print(
        'ALO: ❌ No match found for "$drugAtcCode" (drug: "${drug.name}", total codes: ${_aloCodes!.length})',
      );
    }
    _resultCache[drug.id] = false;
    return false;
  }

  /// Clear cache (useful for testing)
  void clearCache() {
    _resultCache.clear();
    if (kDebugMode) {
      print('ALO: Cache cleared');
    }
  }
}
