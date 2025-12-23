import 'package:flutter/foundation.dart';
import '../models/drug_model.dart';
import '../models/mnn_price_entry.dart';
import '../data/mnn_price_data.dart';

class MnnPriceService {
  static MnnPriceService? _instance;
  List<MnnPriceEntry>? _priceData;
  bool _isInitialized = false;

  // Indexes for fast lookup
  Map<String, List<MnnPriceEntry>>? _atcIndex;
  Map<String, List<MnnPriceEntry>>? _mnnIndex;
  bool _indexesBuilt = false;

  // Cache for check results
  final Map<int, MnnPriceEntry?> _resultCache = {};

  MnnPriceService._();

  factory MnnPriceService() {
    _instance ??= MnnPriceService._();
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

  /// Load МНН price data (instant, no parsing needed - data is compiled as Dart code)
  void loadMnnPriceData() {
    if (_isInitialized) {
      return;
    }

    try {
      // Data is already compiled as Dart constants - instant access!
      _priceData = mnnPriceData;
      _isInitialized = true;
      // Indexes will be built lazily on first use to avoid blocking UI
    } catch (e) {
      if (kDebugMode) {
        print('Error loading МНН price data: $e');
      }
      _priceData = [];
      _isInitialized = true;
    }
  }

  /// Build indexes for fast lookup (runs once, can be slow)
  void _buildIndexes() {
    if (_indexesBuilt || _priceData == null) {
      return;
    }

    _atcIndex = {};
    _mnnIndex = {};

    for (final entry in _priceData!) {
      // Only index entries that have a price
      if (entry.maxPrice == null || entry.maxPrice!.isEmpty) {
        continue;
      }

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

  /// Get price entry for a drug if it exists
  /// Returns null if no price found
  MnnPriceEntry? getPriceForDrug(Drug drug) {
    // Check cache first
    if (_resultCache.containsKey(drug.id)) {
      return _resultCache[drug.id];
    }

    if (_priceData == null || _priceData!.isEmpty) {
      _resultCache[drug.id] = null;
      return null;
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
        // Try to match by МНН if available
        if (drug.internationalnames != null &&
            drug.internationalnames!.isNotEmpty) {
          final drugMnnNames = drug.internationalnames!
              .split(',')
              .map((name) => name.trim().toLowerCase())
              .where((name) => name.isNotEmpty)
              .toList();

          for (final drugMnnName in drugMnnNames) {
            final normalized = _normalizeString(drugMnnName);
            for (final entry in entries) {
              if (entry.mnnOrComposition != null) {
                final entryMnnNormalized = _normalizeString(
                  entry.mnnOrComposition!,
                );
                if (normalized == entryMnnNormalized ||
                    _extractBaseMnn(normalized) ==
                        _extractBaseMnn(entryMnnNormalized)) {
                  _resultCache[drug.id] = entry;
                  return entry;
                }
              }
            }
          }
        }
        // If no МНН match, return first entry with this ATC code
        _resultCache[drug.id] = entries.first;
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
          _resultCache[drug.id] = entries.first;
          return entries.first;
        }

        // Try to extract base МНН (remove common suffixes)
        final baseMnn = _extractBaseMnn(normalized);
        if (baseMnn != normalized && baseMnn.length >= 4) {
          final baseEntries = _mnnIndex![baseMnn];
          if (baseEntries != null && baseEntries.isNotEmpty) {
            _resultCache[drug.id] = baseEntries.first;
            return baseEntries.first;
          }
        }

        // Try partial match: check if any МНН in index matches base МНН
        if (normalized.length >= 4) {
          final baseMnnForSearch = _extractBaseMnn(normalized);
          for (final entry in _mnnIndex!.entries) {
            final priceMnnNormalized = entry.key;
            final priceBaseMnn = _extractBaseMnn(priceMnnNormalized);
            // Check if base МНН match
            if (baseMnnForSearch == priceBaseMnn &&
                baseMnnForSearch.length >= 4) {
              _resultCache[drug.id] = entry.value.first;
              return entry.value.first;
            }
          }
        }
      }
    }

    _resultCache[drug.id] = null;
    return null;
  }

  /// Get price string for a drug (formatted)
  String? getPriceStringForDrug(Drug drug) {
    final entry = getPriceForDrug(drug);
    return entry?.maxPrice;
  }

  /// Get price as double for a drug
  double? getPriceDoubleForDrug(Drug drug) {
    final entry = getPriceForDrug(drug);
    return entry?.priceAsDouble;
  }
}
