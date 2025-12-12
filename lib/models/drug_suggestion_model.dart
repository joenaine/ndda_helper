class DrugSuggestion {
  final String suggestion;
  final String suggestionRaw;
  final String suggestionFormatted;
  final String additional;
  final int ddcId;
  final int brandNameId;

  DrugSuggestion({
    required this.suggestion,
    required this.suggestionRaw,
    required this.suggestionFormatted,
    required this.additional,
    required this.ddcId,
    required this.brandNameId,
  });

  factory DrugSuggestion.fromJson(Map<String, dynamic> json) {
    return DrugSuggestion(
      suggestion: json['suggestion'] as String? ?? '',
      suggestionRaw: json['suggestionRaw'] as String? ?? '',
      suggestionFormatted: json['suggestionFormatted'] as String? ?? '',
      additional: json['additional'] as String? ?? '',
      ddcId: json['ddc_id'] as int? ?? 0,
      brandNameId: json['brand_name_id'] as int? ?? 0,
    );
  }

  String get displayName {
    if (suggestionRaw.isNotEmpty) {
      return suggestionRaw;
    }
    return suggestion;
  }

  String get fullDisplayName {
    if (additional.isNotEmpty) {
      return '$displayName $additional';
    }
    return displayName;
  }
}
