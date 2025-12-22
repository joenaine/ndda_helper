import 'package:flutter/foundation.dart';
import '../models/drug_model.dart';
import '../data/alo_data.dart';

class AloService {
  static AloService? _instance;
  Set<String>? _aloCodes;
  bool _isInitialized = false;

  AloService._();

  factory AloService() {
    _instance ??= AloService._();
    return _instance!;
  }

  /// Load ALO data (instant, no parsing needed - data is compiled as Dart code)
  void loadAloData() {
    if (_isInitialized) {
      return;
    }

    try {
      // Convert list to set for O(1) lookup
      _aloCodes = aloDrugCodes.toSet();
      _isInitialized = true;
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
    if (_aloCodes == null || _aloCodes!.isEmpty) {
      return false;
    }

    final drugAtcCode = drug.code?.trim() ?? '';
    if (drugAtcCode.isEmpty) {
      return false;
    }

    // Direct match
    if (_aloCodes!.contains(drugAtcCode)) {
      return true;
    }

    // Check for codes with slash (e.g., "L01EA01/L01XE01")
    // If drug code matches any part of a combined ALO code, it's in ALO
    for (final aloCode in _aloCodes!) {
      if (aloCode.contains('/')) {
        final parts = aloCode.split('/');
        for (final part in parts) {
          if (part.trim() == drugAtcCode) {
            return true;
          }
        }
      }
    }

    return false;
  }
}

