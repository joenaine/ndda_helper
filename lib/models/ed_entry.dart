class EdEntry {
  final String? atcCode;
  final String? mnnOrComposition;
  final String? characteristic;
  final String? unitOfMeasure;

  const EdEntry({
    this.atcCode,
    this.mnnOrComposition,
    this.characteristic,
    this.unitOfMeasure,
  });

  factory EdEntry.fromJson(Map<String, dynamic> json) {
    return EdEntry(
      atcCode: json['АТХ Код']?.toString().trim(),
      mnnOrComposition:
          json['Наименование лекарственного средства (Международное Непатентованное Наименование или состав)']
              ?.toString()
              .trim(),
      characteristic: json['Характеристика']?.toString().trim(),
      unitOfMeasure:
          json['Единица измерения - штука (ампула, таблетка, капсула, флакон, бутылка, контейнер, комплект, пара, упаковка, набор, литр, шприц, шприц-ручка)*']
              ?.toString()
              .trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'АТХ Код': atcCode,
      'Наименование лекарственного средства (Международное Непатентованное Наименование или состав)':
          mnnOrComposition,
      'Характеристика': characteristic,
      'Единица измерения - штука (ампула, таблетка, капсула, флакон, бутылка, контейнер, комплект, пара, упаковка, набор, литр, шприц, шприц-ручка)*':
          unitOfMeasure,
    };
  }
}
