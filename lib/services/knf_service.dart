import 'package:flutter/foundation.dart';
import '../models/drug_model.dart';
import '../models/knf_entry.dart';
import '../models/knf_result.dart';
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

  // Cache for check results
  final Map<int, KnfCheckResult> _resultCache = {};

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
      ' hydrochloride',
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

  /// Strict matching: registration number -> trade name -> ATC validated
  KnfStrictResult matchStrict(Drug drug) {
    if (_knfData == null || _knfData!.isEmpty) {
      return KnfStrictResult.notFound(reason: 'КНФ data not loaded');
    }

    // Ensure indexes are built
    if (!_indexesBuilt) {
      _buildIndexes();
    }

    final drugRegNumber = drug.regNumber.trim();
    final drugNameLower = drug.name.trim().toLowerCase();
    final drugAtcCode = drug.code?.trim() ?? '';

    // Priority 1: Registration number (100% accuracy)
    if (drugRegNumber.isNotEmpty && _regNumberIndex != null) {
      final entry = _regNumberIndex![drugRegNumber];
      if (entry != null) {
        return KnfStrictResult.found(
          level: KnfStrictLevel.regNumberExact,
          entry: entry,
          matchedBy: 'Registration number',
        );
      }
    }

    // Priority 2: Trade name (high accuracy)
    if (drugNameLower.isNotEmpty && _tradeNameIndex != null) {
      final normalized = _normalizeString(drugNameLower);
      final entries = _tradeNameIndex![normalized];
      if (entries != null && entries.isNotEmpty) {
        return KnfStrictResult.found(
          level: KnfStrictLevel.tradeNameExact,
          entry: entries.first,
          candidates: entries,
          matchedBy: 'Trade name',
        );
      }
    }

    // Priority 3: ATC code (with validation)
    if (drugAtcCode.isNotEmpty && _atcIndex != null) {
      final entries = _atcIndex![drugAtcCode];
      if (entries != null) {
        // Additional validation: entry should represent a concrete drug
        final validEntries = <KnfEntry>[];
        for (final entry in entries) {
          final tradeName = entry.tradeName?.trim() ?? '';
          final regNumber = entry.regNumber?.trim() ?? '';
          final mnnValue = entry.mnnOrGroup?.trim() ?? '';
          final hasConcreteDrug =
              (tradeName.isNotEmpty || regNumber.isNotEmpty) ||
              _isLikelyMnn(mnnValue);
          if (hasConcreteDrug) {
            validEntries.add(entry);
          }
        }
        if (validEntries.isNotEmpty) {
          return KnfStrictResult.found(
            level: KnfStrictLevel.atcValidated,
            entry: validEntries.first,
            candidates: validEntries,
            matchedBy: 'ATC code',
          );
        }
      }
    }

    return KnfStrictResult.notFound(
      reason: 'No strict match found (reg number, trade name, or ATC)',
    );
  }

  /// MNN matching with normalization and salt/ester stripping (RU+EN)
  KnfMnnResult matchByMnn(Drug drug) {
    if (_knfData == null || _knfData!.isEmpty) {
      return KnfMnnResult.notFound(reason: 'КНФ data not loaded');
    }

    // Ensure indexes are built
    if (!_indexesBuilt) {
      _buildIndexes();
    }

    if (_mnnIndex == null || _mnnIndex!.isEmpty) {
      return KnfMnnResult.notFound(reason: 'МНН index not available');
    }

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

    if (drugMnnNames.isEmpty) {
      return KnfMnnResult.notFound(reason: 'No МНН names available');
    }

    for (final drugMnnName in drugMnnNames) {
      final normalized = _normalizeString(drugMnnName);

      // Try exact match first
      final entries = _mnnIndex![normalized];
      if (entries != null && entries.isNotEmpty) {
        return KnfMnnResult.found(
          level: KnfMnnLevel.mnnExact,
          entry: entries.first,
          candidates: entries,
          matchedBy: normalized,
        );
      }

      // Try to extract base МНН (remove common suffixes)
      final baseMnn = _extractBaseMnn(normalized);
      if (baseMnn != normalized && baseMnn.length >= 4) {
        final baseEntries = _mnnIndex![baseMnn];
        if (baseEntries != null && baseEntries.isNotEmpty) {
          return KnfMnnResult.found(
            level: KnfMnnLevel.mnnDerived,
            entry: baseEntries.first,
            candidates: baseEntries,
            matchedBy: '$normalized -> $baseMnn',
          );
        }
      }

      // Try partial match: check if any МНН in index matches base МНН
      if (normalized.length >= 4) {
        final baseMnnForSearch = _extractBaseMnn(normalized);
        for (final entry in _mnnIndex!.entries) {
          final knfMnnNormalized = entry.key;
          final knfBaseMnn = _extractBaseMnn(knfMnnNormalized);
          // Check if base МНН match
          if (baseMnnForSearch == knfBaseMnn && baseMnnForSearch.length >= 4) {
            return KnfMnnResult.found(
              level: KnfMnnLevel.mnnDerived,
              entry: entry.value.first,
              candidates: entry.value,
              matchedBy: '$normalized -> $baseMnnForSearch',
            );
          }
        }
      }
    }

    return KnfMnnResult.notFound(
      reason: 'No МНН match found for: ${drugMnnNames.join(", ")}',
    );
  }

  /// Main check method: strict first, then MNN if strict failed
  KnfCheckResult checkDrug(Drug drug) {
    // Check cache first
    if (_resultCache.containsKey(drug.id)) {
      return _resultCache[drug.id]!;
    }

    final strict = matchStrict(drug);
    if (strict.inKnf) {
      final result = KnfCheckResult(strict: strict, mnn: null);
      _resultCache[drug.id] = result;
      return result;
    }

    final mnn = matchByMnn(drug);
    final result = KnfCheckResult(strict: strict, mnn: mnn);
    _resultCache[drug.id] = result;
    return result;
  }

  /// Check if a drug exists in КНФ (backward compatibility)
  /// Uses strict matching only
  bool isDrugInKnf(Drug drug) {
    return checkDrug(drug).strict.inKnf;
  }

  /// Get КНФ entry for a drug if it exists (backward compatibility)
  KnfEntry? getKnfEntryForDrug(Drug drug) {
    return checkDrug(drug).entry;
  }
}

