class Drug {
  final int id;
  final String regNumber;
  final String regTypesName;
  final String name;
  final int regActionId;
  final String regActions;
  final String regDate;
  final int regTerm;
  final String expirationDate;
  final String producerNameRu;
  final String producerNameEng;
  final String countryNameRu;
  final String drugTypesName;
  final String? atcName;
  final String? code;
  final String? shortName;
  final String? shortNameKz;
  final dynamic dosageValue;
  final String? dosageMeasure;
  final double? storageTerm;
  final String? storageMeasureName;
  final bool gmpSign;
  final bool genericSign;
  final bool recipeSign;
  final bool blockSign;
  final bool patentSign;
  final bool trademarkSign;
  final bool? invitroSign;
  final String? ndName;
  final String? ndNumber;
  final bool unlimitedSign;
  final bool? biosimilarSign;
  final bool? strategSign;
  final String? internationalnames;
  final String? dosageFormName;
  final String? concentration;
  final String? registerDrugsDosageComment;
  final String? useMethodName;
  final String? useMethodNameKz;
  final int regTypeId;

  Drug({
    required this.id,
    required this.regNumber,
    required this.regTypesName,
    required this.name,
    required this.regActionId,
    required this.regActions,
    required this.regDate,
    required this.regTerm,
    required this.expirationDate,
    required this.producerNameRu,
    required this.producerNameEng,
    required this.countryNameRu,
    required this.drugTypesName,
    this.atcName,
    this.code,
    this.shortName,
    this.shortNameKz,
    this.dosageValue,
    this.dosageMeasure,
    this.storageTerm,
    this.storageMeasureName,
    required this.gmpSign,
    required this.genericSign,
    required this.recipeSign,
    required this.blockSign,
    required this.patentSign,
    required this.trademarkSign,
    this.invitroSign,
    this.ndName,
    this.ndNumber,
    required this.unlimitedSign,
    this.biosimilarSign,
    this.strategSign,
    this.internationalnames,
    this.dosageFormName,
    this.concentration,
    this.registerDrugsDosageComment,
    this.useMethodName,
    this.useMethodNameKz,
    required this.regTypeId,
  });

  factory Drug.fromJson(Map<String, dynamic> json) {
    return Drug(
      id: json['id'] ?? 0,
      regNumber: json['reg_number'] ?? '',
      regTypesName: json['regTypesName'] ?? '',
      name: json['name'] ?? '',
      regActionId: json['reg_action_id'] ?? 0,
      regActions: json['regActions'] ?? '',
      regDate: json['reg_date'] ?? '',
      regTerm: json['reg_term'] ?? 0,
      expirationDate: json['expiration_date'] ?? '',
      producerNameRu: json['producerNameRu'] ?? '',
      producerNameEng: json['producerNameEng'] ?? '',
      countryNameRu: json['countryNameRu'] ?? '',
      drugTypesName: json['drugTypesName'] ?? '',
      atcName: json['atc_name'],
      code: json['code'],
      shortName: json['short_name'],
      shortNameKz: json['short_name_kz'],
      dosageValue: json['dosage_value'],
      dosageMeasure: json['dosageMeasure'],
      storageTerm: json['storage_term']?.toDouble(),
      storageMeasureName: json['storageMeasure_name'],
      gmpSign: json['gmp_sign'] ?? false,
      genericSign: json['generic_sign'] ?? false,
      recipeSign: json['recipe_sign'] ?? false,
      blockSign: json['block_sign'] ?? false,
      patentSign: json['patent_sign'] ?? false,
      trademarkSign: json['trademark_sign'] ?? false,
      invitroSign: json['invitro_sign'],
      ndName: json['nd_name'],
      ndNumber: json['nd_number'],
      unlimitedSign: json['unlimited_sign'] ?? false,
      biosimilarSign: json['biosimilar_sign'],
      strategSign: json['strateg_sign'],
      internationalnames: json['internationalnames'],
      dosageFormName: json['dosageForm_name'],
      concentration: json['concentration'],
      registerDrugsDosageComment: json['registerDrugs_dosageComment'],
      useMethodName: json['useMethodName'],
      useMethodNameKz: json['useMethodNameKz'],
      regTypeId: json['reg_type_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reg_number': regNumber,
      'regTypesName': regTypesName,
      'name': name,
      'reg_action_id': regActionId,
      'regActions': regActions,
      'reg_date': regDate,
      'reg_term': regTerm,
      'expiration_date': expirationDate,
      'producerNameRu': producerNameRu,
      'producerNameEng': producerNameEng,
      'countryNameRu': countryNameRu,
      'drugTypesName': drugTypesName,
      'atc_name': atcName,
      'code': code,
      'short_name': shortName,
      'short_name_kz': shortNameKz,
      'dosage_value': dosageValue,
      'dosageMeasure': dosageMeasure,
      'storage_term': storageTerm,
      'storageMeasure_name': storageMeasureName,
      'gmp_sign': gmpSign,
      'generic_sign': genericSign,
      'recipe_sign': recipeSign,
      'block_sign': blockSign,
      'patent_sign': patentSign,
      'trademark_sign': trademarkSign,
      'invitro_sign': invitroSign,
      'nd_name': ndName,
      'nd_number': ndNumber,
      'unlimited_sign': unlimitedSign,
      'biosimilar_sign': biosimilarSign,
      'strateg_sign': strategSign,
      'internationalnames': internationalnames,
      'dosageForm_name': dosageFormName,
      'concentration': concentration,
      'registerDrugs_dosageComment': registerDrugsDosageComment,
      'useMethodName': useMethodName,
      'useMethodNameKz': useMethodNameKz,
      'reg_type_id': regTypeId,
    };
  }

  // Helper method for search
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase().trim();

    return name.toLowerCase().contains(lowerQuery) ||
        (atcName?.toLowerCase().contains(lowerQuery) ?? false) ||
        (code?.toLowerCase().contains(lowerQuery) ?? false) ||
        regNumber.toLowerCase().contains(lowerQuery) ||
        producerNameRu.toLowerCase().contains(lowerQuery);
  }
}
