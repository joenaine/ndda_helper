class UpToDateSearchResult {
  final String display;
  final String english;
  final String? translationProvider;

  UpToDateSearchResult({
    required this.display,
    required this.english,
    this.translationProvider,
  });

  factory UpToDateSearchResult.fromJson(Map<String, dynamic> json) {
    return UpToDateSearchResult(
      display: json['disp'] ?? '',
      english: json['engl'] ?? '',
      translationProvider: json['trprov']?.isEmpty ?? true ? null : json['trprov'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disp': display,
      'engl': english,
      'trprov': translationProvider ?? '',
    };
  }
}

