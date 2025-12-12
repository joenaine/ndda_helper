enum InteractionSeverity { major, moderate, minor, unknown }

class InteractionResult {
  final InteractionSeverity severity;
  final String title;
  final String description;
  final List<String> drugs;
  final String category; // e.g., "drug-drug", "food", "disease"

  InteractionResult({
    required this.severity,
    required this.title,
    required this.description,
    required this.drugs,
    required this.category,
  });

  String get severityLabel {
    switch (severity) {
      case InteractionSeverity.major:
        return 'Major';
      case InteractionSeverity.moderate:
        return 'Moderate';
      case InteractionSeverity.minor:
        return 'Minor';
      case InteractionSeverity.unknown:
        return 'Unknown';
    }
  }

  static InteractionSeverity severityFromString(String severity) {
    switch (severity.toLowerCase()) {
      case 'major':
        return InteractionSeverity.major;
      case 'moderate':
        return InteractionSeverity.moderate;
      case 'minor':
        return InteractionSeverity.minor;
      default:
        return InteractionSeverity.unknown;
    }
  }
}
