class InteractionDrug {
  final int ddcId;
  final int brandNameId;
  final String drugName;
  final String genericName;
  final int interactionListDrugId;
  final String? interactionListId;
  final String? drugList;

  InteractionDrug({
    required this.ddcId,
    required this.brandNameId,
    required this.drugName,
    required this.genericName,
    required this.interactionListDrugId,
    this.interactionListId,
    this.drugList,
  });

  factory InteractionDrug.fromJson(Map<String, dynamic> json) {
    return InteractionDrug(
      ddcId: json['ddc_id'] as int? ?? 0,
      brandNameId: json['brand_name_id'] as int? ?? 0,
      drugName: json['drugName'] as String? ?? '',
      genericName: json['generic_name'] as String? ?? '',
      interactionListDrugId: json['interaction_list_drug_id'] as int? ?? 0,
      interactionListId: json['interaction_list_id']?.toString(),
      drugList: json['drug_list'] as String?,
    );
  }

  String get displayName {
    if (drugName.isNotEmpty) {
      return drugName;
    }
    return genericName;
  }
}
