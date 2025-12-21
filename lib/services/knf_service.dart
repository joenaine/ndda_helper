import 'package:flutter/foundation.dart';
import '../models/drug_model.dart';
import '../models/knf_entry.dart';
import '../data/knf_data.dart';

class KnfService {
  static KnfService? _instance;
  List<KnfEntry>? _knfData;
  bool _isInitialized = false;

  // Indexes for fast lookup
  Map<String, KnfEntry>? _regNumberIndex;
  Map<String, List<KnfEntry>>? _tradeNameIndex;
  Map<String, List<KnfEntry>>? _mnnIndex;
  Map<String, List<KnfEntry>>? _atcIndex;
  bool _indexesBuilt = false;

  KnfService._();

  factory KnfService() {
    _instance ??= KnfService._();
    return _instance!;
  }

  /// Normalize string for comparison (remove special characters, normalize spaces)
  String _normalizeString(String str) {
    return str
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize multiple spaces
        .replaceAll(RegExp(r'[®™©]'), '') // Remove trademark symbols
        .replaceAll(
          RegExp(r'[^\p{L}\p{N}\s]', unicode: true),
          '',
        ); // Remove special characters except letters (including Cyrillic), numbers, spaces
  }

  /// Load КНФ data (instant, no parsing needed - data is compiled as Dart code)
  void loadKnfData() {
    if (_isInitialized) {
      return;
    }

    try {
      // Data is already compiled as Dart constants - instant access!
      _knfData = knfData;
      _isInitialized = true;
      // Indexes will be built lazily on first use to avoid blocking UI
    } catch (e) {
      if (kDebugMode) {
        print('Error loading КНФ data: $e');
      }
      _knfData = [];
      _isInitialized = true;
    }
  }

  /// Build indexes for fast lookup (runs once, can be slow)
  void _buildIndexes() {
    if (_indexesBuilt || _knfData == null) {
      return;
    }

    _regNumberIndex = {};
    _tradeNameIndex = {};
    _mnnIndex = {};
    _atcIndex = {};

    for (final entry in _knfData!) {
      // Index by registration number (exact match, highest priority)
      final regNumber = entry.regNumber?.trim();
      if (regNumber != null && regNumber.isNotEmpty) {
        _regNumberIndex![regNumber] = entry;
      }

      // Index by trade name (normalized)
      final tradeName = entry.tradeName?.trim();
      if (tradeName != null && tradeName.isNotEmpty) {
        final normalized = _normalizeString(tradeName);
        _tradeNameIndex!.putIfAbsent(normalized, () => []).add(entry);
      }

      // Index by МНН (only for concrete drugs)
      final mnnValue = entry.mnnOrGroup?.trim();
      if (mnnValue != null && mnnValue.isNotEmpty) {
        final hasConcreteDrug =
            (tradeName != null && tradeName.isNotEmpty) ||
            (regNumber != null && regNumber.isNotEmpty) ||
            _isLikelyMnn(mnnValue);

        if (hasConcreteDrug) {
          final normalized = _normalizeString(mnnValue);
          _mnnIndex!.putIfAbsent(normalized, () => []).add(entry);
        }
      }

      // Index by ATC code
      final atcCode = entry.atcCode?.trim();
      if (atcCode != null && atcCode.isNotEmpty) {
        _atcIndex!.putIfAbsent(atcCode, () => []).add(entry);
      }
    }

    _indexesBuilt = true;
  }

  /// Check if a value looks like МНН (not a pharmacological group)
  bool _isLikelyMnn(String value) {
    if (value.isEmpty) return false;

    // Pharmacological groups usually contain these words
    final groupKeywords = [
      'препарат',
      'средство',
      'группа',
      'применяемый',
      'применяемые',
      'сочетание',
      'комбинация',
    ];

    final valueLower = value.toLowerCase();
    for (final keyword in groupKeywords) {
      if (valueLower.contains(keyword)) {
        return false; // Likely a pharmacological group
      }
    }

    // МНН are usually shorter (less than 50 characters) and don't contain commas
    return value.length < 50 && !value.contains(',');
  }

  /// Check if a drug exists in КНФ
  /// Priority order:
  /// 1. Registration number (100% accuracy)
  /// 2. Trade name (high accuracy)
  /// 3. МНН (main criterion)
  /// 4. ATC code (additional check/fallback)
  bool isDrugInKnf(Drug drug) {
    if (_knfData == null || _knfData!.isEmpty) {
      return false;
    }

    // Ensure indexes are built
    if (!_indexesBuilt) {
      _buildIndexes();
    }

    // Prepare drug data for matching
    final drugRegNumber = drug.regNumber.trim();
    final drugNameLower = drug.name.trim().toLowerCase();
    final drugAtcCode = drug.code?.trim() ?? '';

    // Priority 1: Registration number (100% accuracy) - O(1) lookup
    if (drugRegNumber.isNotEmpty && _regNumberIndex != null) {
      if (_regNumberIndex!.containsKey(drugRegNumber)) {
        return true;
      }
    }

    // Priority 2: Trade name (high accuracy) - O(1) lookup
    if (drugNameLower.isNotEmpty && _tradeNameIndex != null) {
      final normalized = _normalizeString(drugNameLower);
      final entries = _tradeNameIndex![normalized];
      if (entries != null && entries.isNotEmpty) {
        return true;
      }
    }

    // Priority 3: МНН (main criterion) - O(1) lookup per МНН
    if (_mnnIndex != null) {
      final List<String> drugMnnNames = [];
      if (drug.internationalnames != null &&
          drug.internationalnames!.isNotEmpty) {
        final drugInternationalNames = drug.internationalnames!
            .split(',')
            .map((name) => name.trim().toLowerCase())
            .where((name) => name.isNotEmpty)
            .toList();
        drugMnnNames.addAll(drugInternationalNames);
      }
      if (drugNameLower.isNotEmpty) {
        drugMnnNames.add(drugNameLower);
      }

      for (final drugMnnName in drugMnnNames) {
        final normalized = _normalizeString(drugMnnName);
        final entries = _mnnIndex![normalized];
        if (entries != null && entries.isNotEmpty) {
          return true;
        }
      }
    }

    // Priority 4: ATC code (additional check/fallback) - O(1) lookup
    if (drugAtcCode.isNotEmpty && _atcIndex != null) {
      final entries = _atcIndex![drugAtcCode];
      if (entries != null) {
        // Additional validation: entry should represent a concrete drug
        for (final entry in entries) {
          final tradeName = entry.tradeName?.trim() ?? '';
          final regNumber = entry.regNumber?.trim() ?? '';
          final mnnValue = entry.mnnOrGroup?.trim() ?? '';
          final hasConcreteDrug =
              (tradeName.isNotEmpty || regNumber.isNotEmpty) ||
              _isLikelyMnn(mnnValue);
          if (hasConcreteDrug) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Get КНФ entry for a drug if it exists
  /// Priority order:
  /// 1. Registration number (100% accuracy)
  /// 2. Trade name (high accuracy)
  /// 3. МНН (main criterion)
  /// 4. ATC code (additional check/fallback)
  KnfEntry? getKnfEntryForDrug(Drug drug) {
    if (_knfData == null || _knfData!.isEmpty) {
      return null;
    }

    // Ensure indexes are built
    if (!_indexesBuilt) {
      _buildIndexes();
    }

    // Prepare drug data for matching
    final drugRegNumber = drug.regNumber.trim();
    final drugNameLower = drug.name.trim().toLowerCase();
    final drugAtcCode = drug.code?.trim() ?? '';

    // Priority 1: Registration number (100% accuracy) - O(1) lookup
    if (drugRegNumber.isNotEmpty && _regNumberIndex != null) {
      final entry = _regNumberIndex![drugRegNumber];
      if (entry != null) {
        return entry;
      }
    }

    // Priority 2: Trade name (high accuracy) - O(1) lookup
    if (drugNameLower.isNotEmpty && _tradeNameIndex != null) {
      final normalized = _normalizeString(drugNameLower);
      final entries = _tradeNameIndex![normalized];
      if (entries != null && entries.isNotEmpty) {
        return entries.first;
      }
    }

    // Priority 3: МНН (main criterion) - O(1) lookup per МНН
    if (_mnnIndex != null) {
      final List<String> drugMnnNames = [];
      if (drug.internationalnames != null &&
          drug.internationalnames!.isNotEmpty) {
        final drugInternationalNames = drug.internationalnames!
            .split(',')
            .map((name) => name.trim().toLowerCase())
            .where((name) => name.isNotEmpty)
            .toList();
        drugMnnNames.addAll(drugInternationalNames);
      }
      if (drugNameLower.isNotEmpty) {
        drugMnnNames.add(drugNameLower);
      }

      for (final drugMnnName in drugMnnNames) {
        final normalized = _normalizeString(drugMnnName);
        final entries = _mnnIndex![normalized];
        if (entries != null && entries.isNotEmpty) {
          return entries.first;
        }
      }
    }

    // Priority 4: ATC code (additional check/fallback) - O(1) lookup
    if (drugAtcCode.isNotEmpty && _atcIndex != null) {
      final entries = _atcIndex![drugAtcCode];
      if (entries != null) {
        // Additional validation: entry should represent a concrete drug
        for (final entry in entries) {
          final tradeName = entry.tradeName?.trim() ?? '';
          final regNumber = entry.regNumber?.trim() ?? '';
          final mnnValue = entry.mnnOrGroup?.trim() ?? '';
          final hasConcreteDrug =
              (tradeName.isNotEmpty || regNumber.isNotEmpty) ||
              _isLikelyMnn(mnnValue);
          if (hasConcreteDrug) {
            return entry;
          }
        }
      }
    }

    return null;
  }
}
