class MnnPriceEntry {
  final String? atcCode;
  final String? mnnOrComposition;
  final String? characteristic;
  final String? unitOfMeasure;
  final String? maxPrice; // Предельная цена по МНН

  const MnnPriceEntry({
    this.atcCode,
    this.mnnOrComposition,
    this.characteristic,
    this.unitOfMeasure,
    this.maxPrice,
  });

  factory MnnPriceEntry.fromJson(Map<String, dynamic> json) {
    return MnnPriceEntry(
      atcCode: json['АТХ Код']?.toString().trim(),
      mnnOrComposition:
          json['Наименование лекарственного средства (Международное Непатентованное Наименование или состав)']
              ?.toString()
              .trim(),
      characteristic: json['Характеристика']?.toString().trim(),
      unitOfMeasure:
          json['Единица измерения - штука (ампула, таблетка, капсула, флакон, бутылка, контейнер, комплект, пара, упаковка, набор, литр, шприц, шприц-ручка)']
              ?.toString()
              .trim(),
      maxPrice: json['Предельная цена по МНН']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'АТХ Код': atcCode,
      'Наименование лекарственного средства (Международное Непатентованное Наименование или состав)':
          mnnOrComposition,
      'Характеристика': characteristic,
      'Единица измерения - штука (ампула, таблетка, капсула, флакон, бутылка, контейнер, комплект, пара, упаковка, набор, литр, шприц, шприц-ручка)':
          unitOfMeasure,
      'Предельная цена по МНН': maxPrice,
    };
  }

  /// Parse price string (e.g., "82,12" or "2 993,88") to double
  double? get priceAsDouble {
    if (maxPrice == null || maxPrice!.isEmpty) return null;
    try {
      // Replace comma with dot and remove spaces
      final cleaned = maxPrice!.replaceAll(' ', '').replaceAll(',', '.');
      return double.tryParse(cleaned);
    } catch (e) {
      return null;
    }
  }
}
