import 'knf_entry.dart';

enum KnfStrictLevel { regNumberExact, tradeNameExact, atcValidated, none }

enum KnfMnnLevel { mnnExact, mnnDerived, none }

class KnfStrictResult {
  final bool inKnf;
  final KnfStrictLevel level;
  final KnfEntry? entry;
  final List<KnfEntry> candidates;
  final String reason;
  final String? matchedBy;

  KnfStrictResult({
    required this.inKnf,
    required this.level,
    this.entry,
    List<KnfEntry>? candidates,
    required this.reason,
    this.matchedBy,
  }) : candidates = candidates ?? [];

  factory KnfStrictResult.notFound({String reason = 'Not found'}) {
    return KnfStrictResult(
      inKnf: false,
      level: KnfStrictLevel.none,
      reason: reason,
    );
  }

  factory KnfStrictResult.found({
    required KnfStrictLevel level,
    required KnfEntry entry,
    required String matchedBy,
    List<KnfEntry>? candidates,
  }) {
    return KnfStrictResult(
      inKnf: true,
      level: level,
      entry: entry,
      candidates: candidates,
      reason: 'Found by $matchedBy',
      matchedBy: matchedBy,
    );
  }
}

class KnfMnnResult {
  final bool inKnfByMnn;
  final KnfMnnLevel level;
  final KnfEntry? entry;
  final List<KnfEntry> candidates;
  final String reason;
  final String? matchedBy;

  KnfMnnResult({
    required this.inKnfByMnn,
    required this.level,
    this.entry,
    List<KnfEntry>? candidates,
    required this.reason,
    this.matchedBy,
  }) : candidates = candidates ?? [];

  factory KnfMnnResult.notFound({String reason = 'MNN not found'}) {
    return KnfMnnResult(
      inKnfByMnn: false,
      level: KnfMnnLevel.none,
      reason: reason,
    );
  }

  factory KnfMnnResult.found({
    required KnfMnnLevel level,
    required KnfEntry entry,
    required String matchedBy,
    List<KnfEntry>? candidates,
  }) {
    return KnfMnnResult(
      inKnfByMnn: true,
      level: level,
      entry: entry,
      candidates: candidates,
      reason: 'Found by MNN: $matchedBy',
      matchedBy: matchedBy,
    );
  }
}

class KnfCheckResult {
  final KnfStrictResult strict;
  final KnfMnnResult? mnn; // nullable; only computed if strict.inKnf==false

  KnfCheckResult({required this.strict, this.mnn});

  bool get inKnf => strict.inKnf || (mnn?.inKnfByMnn ?? false);
  KnfEntry? get entry => strict.entry ?? mnn?.entry;
}

