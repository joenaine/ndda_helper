class OrphanEntry {
  final String? mnn;
  final String? atcCode;

  const OrphanEntry({this.mnn, this.atcCode});

  factory OrphanEntry.fromJson(Map<String, dynamic> json) {
    return OrphanEntry(
      mnn: json['MNN']?.toString().trim(),
      atcCode: json['ATX']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'MNN': mnn, 'ATX': atcCode};
  }
}
