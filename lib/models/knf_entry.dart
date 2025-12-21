class KnfEntry {
  final String? number;
  final String? atcCode;
  final String? mnnOrGroup;
  final String? tradeName;
  final String? dosageForm;
  final String? regNumber;

  const KnfEntry({
    this.number,
    this.atcCode,
    this.mnnOrGroup,
    this.tradeName,
    this.dosageForm,
    this.regNumber,
  });

  factory KnfEntry.fromJson(Map<String, dynamic> json) {
    return KnfEntry(
      number: json['№']?.toString().trim(),
      atcCode: json['Код анатомо-терапевтическо-химической (АТХ) классификации']
          ?.toString()
          .trim(),
      mnnOrGroup:
          json['Фармакологическая группа/ Международное непатентованное наименование или состав']
              ?.toString()
              .trim(),
      tradeName: json['Торговое наименование']?.toString().trim(),
      dosageForm: json['Лекарственная форма, дозировка и объем']
          ?.toString()
          .trim(),
      regNumber: json['Номер регистрационного удостоверения/орфанный']
          ?.toString()
          .trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '№': number,
      'Код анатомо-терапевтическо-химической (АТХ) классификации': atcCode,
      'Фармакологическая группа/ Международное непатентованное наименование или состав':
          mnnOrGroup,
      'Торговое наименование': tradeName,
      'Лекарственная форма, дозировка и объем': dosageForm,
      'Номер регистрационного удостоверения/орфанный': regNumber,
    };
  }
}
