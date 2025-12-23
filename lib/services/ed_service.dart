import 'package:flutter/foundation.dart';
import '../models/drug_model.dart';
import '../models/ed_entry.dart';
import '../data/ed_data.dart';

class EdService {
  static EdService? _instance;
  List<EdEntry>? _edData;
  bool _isInitialized = false;

  // Indexes for fast lookup
  Map<String, List<EdEntry>>? _atcIndex;
  Map<String, List<EdEntry>>? _mnnIndex;
  bool _indexesBuilt = false;

  // Cache for check results
  final Map<int, bool> _resultCache = {};

  EdService._();

  factory EdService() {
    _instance ??= EdService._();
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

  /// Load ЕД data (instant, no parsing needed - data is compiled as Dart code)
  void loadEdData() {
    if (_isInitialized) {
      return;
    }

    try {
      // Data is already compiled as Dart constants - instant access!
      _edData = edData;
      _isInitialized = true;
      // Indexes will be built lazily on first use to avoid blocking UI
    } catch (e) {
      if (kDebugMode) {
        print('Error loading ЕД data: $e');
      }
      _edData = [];
      _isInitialized = true;
    }
  }

  /// Build indexes for fast lookup (runs once, can be slow)
  void _buildIndexes() {
    if (_indexesBuilt || _edData == null) {
      return;
    }

    _atcIndex = {};
    _mnnIndex = {};

    for (final entry in _edData!) {
      // Index by ATC code
      final atcCode = entry.atcCode?.trim();
      if (atcCode != null && atcCode.isNotEmpty) {
        _atcIndex!.putIfAbsent(atcCode, () => []).add(entry);
      }

      // Index by МНН
      final mnnValue = entry.mnnOrComposition?.trim();
      if (mnnValue != null && mnnValue.isNotEmpty) {
        final normalized = _normalizeString(mnnValue);
        _mnnIndex!.putIfAbsent(normalized, () => []).add(entry);
      }
    }

    _indexesBuilt = true;
  }

  /// Extract base МНН (remove common suffixes - salt/ester stripping RU+EN)
  String _extractBaseMnn(String mnn) {
    // Remove common suffixes that don't change the active ingredient
    // Russian suffixes
    final ruSuffixes = [
      ' фосфат',
      ' гидрохлорид',
      ' сульфат',
      ' ацетат',
      ' натрий',
      ' калий',
      ' кальций',
      ' магний',
      ' дигидрохлорид',
      ' гидрохлорида',
      ' фосфата',
      ' сульфата',
    ];

    // English suffixes (salt/ester stripping)
    final enSuffixes = [
      ' phosphate',
      ' hydrochloride',
      ' sulfate',
      ' sulphate',
      ' acetate',
      ' sodium',
      ' potassium',
      ' calcium',
      ' magnesium',
      ' dihydrochloride',
      ' mesylate',
      ' maleate',
      ' tartrate',
      ' citrate',
      ' succinate',
      ' fumarate',
      ' lactate',
      ' gluconate',
      ' palmitate',
      ' stearate',
    ];

    String base = mnn.toLowerCase().trim();

    // Try Russian suffixes first
    for (final suffix in ruSuffixes) {
      if (base.endsWith(suffix)) {
        base = base.substring(0, base.length - suffix.length).trim();
        break;
      }
    }

    // Try English suffixes
    for (final suffix in enSuffixes) {
      if (base.endsWith(suffix)) {
        base = base.substring(0, base.length - suffix.length).trim();
        break;
      }
    }

    return base;
  }

  /// Check if drug has concrete ATC code (not just a group)
  bool _hasConcreteDrug(String atcCode) {
    // ATC codes for concrete drugs are usually 7 characters (e.g., "A02BC01")
    // Group codes are shorter (e.g., "A02BC")
    return atcCode.length >= 7;
  }

  /// Check if a drug exists in ЕД (Единый Дистрибьютор)
  bool isDrugInEd(Drug drug) {
    // Check cache first
    if (_resultCache.containsKey(drug.id)) {
      return _resultCache[drug.id]!;
    }

    if (_edData == null || _edData!.isEmpty) {
      return false;
    }

    // Ensure indexes are built
    if (!_indexesBuilt) {
      _buildIndexes();
    }

    final drugAtcCode = drug.code?.trim() ?? '';

    // Priority 1: ATC code (if concrete, not just a group)
    if (drugAtcCode.isNotEmpty &&
        _atcIndex != null &&
        _hasConcreteDrug(drugAtcCode)) {
      final entries = _atcIndex![drugAtcCode];
      if (entries != null && entries.isNotEmpty) {
        _resultCache[drug.id] = true;
        return true;
      }
    }

    // Priority 2: МНН matching
    if (_mnnIndex != null && _mnnIndex!.isNotEmpty) {
      // Prepare МНН names for matching
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

      for (final drugMnnName in drugMnnNames) {
        final normalized = _normalizeString(drugMnnName);

        // Try exact match first
        final entries = _mnnIndex![normalized];
        if (entries != null && entries.isNotEmpty) {
          _resultCache[drug.id] = true;
          return true;
        }

        // Try to extract base МНН (remove common suffixes)
        final baseMnn = _extractBaseMnn(normalized);
        if (baseMnn != normalized && baseMnn.length >= 4) {
          final baseEntries = _mnnIndex![baseMnn];
          if (baseEntries != null && baseEntries.isNotEmpty) {
            _resultCache[drug.id] = true;
            return true;
          }
        }

        // Try partial match: check if any МНН in index matches base МНН
        if (normalized.length >= 4) {
          final baseMnnForSearch = _extractBaseMnn(normalized);
          for (final entry in _mnnIndex!.entries) {
            final edMnnNormalized = entry.key;
            final edBaseMnn = _extractBaseMnn(edMnnNormalized);
            // Check if base МНН match
            if (baseMnnForSearch == edBaseMnn && baseMnnForSearch.length >= 4) {
              _resultCache[drug.id] = true;
              return true;
            }
          }
        }
      }
    }

    _resultCache[drug.id] = false;
    return false;
  }

  /// Get ЕД entry for a drug if it exists
  EdEntry? getEdEntryForDrug(Drug drug) {
    if (_edData == null || _edData!.isEmpty) {
      return null;
    }

    // Ensure indexes are built
    if (!_indexesBuilt) {
      _buildIndexes();
    }

    final drugAtcCode = drug.code?.trim() ?? '';

    // Priority 1: ATC code
    if (drugAtcCode.isNotEmpty &&
        _atcIndex != null &&
        _hasConcreteDrug(drugAtcCode)) {
      final entries = _atcIndex![drugAtcCode];
      if (entries != null && entries.isNotEmpty) {
        return entries.first;
      }
    }

    // Priority 2: МНН matching
    if (_mnnIndex != null && _mnnIndex!.isNotEmpty) {
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

      for (final drugMnnName in drugMnnNames) {
        final normalized = _normalizeString(drugMnnName);

        // Try exact match first
        final entries = _mnnIndex![normalized];
        if (entries != null && entries.isNotEmpty) {
          return entries.first;
        }

        // Try base МНН match
        final baseMnn = _extractBaseMnn(normalized);
        if (baseMnn != normalized && baseMnn.length >= 4) {
          final baseEntries = _mnnIndex![baseMnn];
          if (baseEntries != null && baseEntries.isNotEmpty) {
            return baseEntries.first;
          }
        }
      }
    }

    return null;
  }
}
