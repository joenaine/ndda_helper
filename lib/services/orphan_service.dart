import 'package:flutter/foundation.dart';
import '../models/drug_model.dart';
import '../models/orphan_entry.dart';
import '../data/orphan_data.dart';

class OrphanService {
  static OrphanService? _instance;
  List<OrphanEntry>? _orphanData;
  bool _isInitialized = false;

  // Indexes for fast lookup
  Map<String, List<OrphanEntry>>? _atcIndex;
  Map<String, List<OrphanEntry>>? _mnnIndex;
  bool _indexesBuilt = false;

  // Cache for check results
  final Map<int, bool> _resultCache = {};

  OrphanService._();

  factory OrphanService() {
    _instance ??= OrphanService._();
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

  /// Load Orphan data (instant, no parsing needed - data is compiled as Dart code)
  void loadOrphanData() {
    if (_isInitialized) {
      if (kDebugMode) {
        print('ORPHAN: Already initialized');
      }
      return;
    }

    try {
      // Data is already compiled as Dart constants - instant access!
      _orphanData = orphanData;
      _isInitialized = true;
      if (kDebugMode) {
        print(
          'ORPHAN: Data loaded successfully, ${_orphanData!.length} entries',
        );
      }
      // Indexes will be built lazily on first use to avoid blocking UI
    } catch (e) {
      if (kDebugMode) {
        print('Error loading Orphan data: $e');
      }
      _orphanData = [];
      _isInitialized = true;
    }
  }

  /// Build indexes for fast lookup (runs once, can be slow)
  void _buildIndexes() {
    if (_indexesBuilt || _orphanData == null) {
      return;
    }

    _atcIndex = {};
    _mnnIndex = {};

    for (final entry in _orphanData!) {
      // Index by ATC code
      final atcCode = entry.atcCode?.trim();
      if (atcCode != null && atcCode.isNotEmpty) {
        _atcIndex!.putIfAbsent(atcCode, () => []).add(entry);
      }

      // Index by МНН
      final mnnValue = entry.mnn?.trim();
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

  /// Check if a drug is an orphan drug (by ATC or МНН)
  bool isDrugOrphan(Drug drug) {
    // Check cache first
    if (_resultCache.containsKey(drug.id)) {
      return _resultCache[drug.id]!;
    }

    if (_orphanData == null || _orphanData!.isEmpty) {
      if (kDebugMode) {
        print('ORPHAN: Data not loaded or empty');
      }
      _resultCache[drug.id] = false;
      return false;
    }

    // Ensure indexes are built
    if (!_indexesBuilt) {
      _buildIndexes();
    }

    final drugAtcCode = drug.code?.trim() ?? '';

    // Priority 1: ATC code
    if (drugAtcCode.isNotEmpty && _atcIndex != null) {
      final entries = _atcIndex![drugAtcCode];
      if (entries != null && entries.isNotEmpty) {
        if (kDebugMode) {
          print('ORPHAN: ATC match found for $drugAtcCode');
        }
        // If ATC matches, also try to match by МНН for better accuracy
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
              if (entry.mnn != null) {
                final entryMnnNormalized = _normalizeString(entry.mnn!);
                if (normalized == entryMnnNormalized ||
                    _extractBaseMnn(normalized) ==
                        _extractBaseMnn(entryMnnNormalized)) {
                  if (kDebugMode) {
                    print(
                      'ORPHAN: ATC + MNN match for $drugAtcCode + $drugMnnName',
                    );
                  }
                  _resultCache[drug.id] = true;
                  return true;
                }
              }
            }
          }
        }
        // If ATC matches, consider it orphan (even without МНН match)
        if (kDebugMode) {
          print('ORPHAN: ATC match (without MNN validation) for $drugAtcCode');
        }
        _resultCache[drug.id] = true;
        return true;
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
          if (kDebugMode) {
            print('ORPHAN: MNN exact match for $drugMnnName');
          }
          _resultCache[drug.id] = true;
          return true;
        }

        // Try to extract base МНН (remove common suffixes)
        final baseMnn = _extractBaseMnn(normalized);
        if (baseMnn != normalized && baseMnn.length >= 4) {
          final baseEntries = _mnnIndex![baseMnn];
          if (baseEntries != null && baseEntries.isNotEmpty) {
            if (kDebugMode) {
              print('ORPHAN: MNN base match for $drugMnnName -> $baseMnn');
            }
            _resultCache[drug.id] = true;
            return true;
          }
        }

        // Try partial match: check if any МНН in index matches base МНН
        if (normalized.length >= 4) {
          final baseMnnForSearch = _extractBaseMnn(normalized);
          for (final entry in _mnnIndex!.entries) {
            final orphanMnnNormalized = entry.key;
            final orphanBaseMnn = _extractBaseMnn(orphanMnnNormalized);
            // Check if base МНН match
            if (baseMnnForSearch == orphanBaseMnn &&
                baseMnnForSearch.length >= 4) {
              if (kDebugMode) {
                print('ORPHAN: MNN partial match for $drugMnnName');
              }
              _resultCache[drug.id] = true;
              return true;
            }
          }
        }
      }
    }

    if (kDebugMode) {
      print(
        'ORPHAN: No match found for ATC=$drugAtcCode, data size=${_orphanData!.length}',
      );
    }
    _resultCache[drug.id] = false;
    return false;
  }
}
