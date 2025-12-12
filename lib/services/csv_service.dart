import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/drug_model.dart';

// Conditional imports
import 'csv_service_stub.dart'
    if (dart.library.html) 'csv_service_web.dart'
    if (dart.library.io) 'csv_service_mobile.dart';

class CsvService {
  // Export selected drugs to CSV
  Future<void> exportToCSV(List<Drug> drugs) async {
    if (drugs.isEmpty) {
      return;
    }

    // Define CSV headers
    List<List<dynamic>> rows = [
      [
        'ID',
        'Reg Number',
        'Name',
        'ATC Name',
        'ATC Code',
        'Drug Type',
        'Dosage Form',
        'Producer (RU)',
        'Producer (ENG)',
        'Country',
        'Reg Date',
        'Expiration Date',
        'Reg Term',
        'ND Number',
        'Generic',
        'GMP',
        'Recipe Required',
        'OHLP Download Link',
      ],
    ];

    // Add drug data
    for (var drug in drugs) {
      final ohlpLink =
          'https://register.ndda.kz/register-backend/RegisterService/GetRegisterOhlpFile?registerId=${drug.id}&lang=ru';
      rows.add([
        drug.id,
        drug.regNumber,
        drug.name,
        drug.atcName ?? '',
        drug.code ?? '',
        drug.drugTypesName,
        drug.dosageFormName ?? drug.shortName ?? '',
        drug.producerNameRu,
        drug.producerNameEng,
        drug.countryNameRu,
        drug.regDate,
        drug.expirationDate,
        drug.regTerm,
        drug.ndNumber ?? '',
        drug.genericSign ? 'Yes' : 'No',
        drug.gmpSign ? 'Yes' : 'No',
        drug.recipeSign ? 'Yes' : 'No',
        ohlpLink,
      ]);
    }

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(rows);

    // Platform-specific export
    if (kIsWeb) {
      await exportToCSVWeb(csv);
    } else {
      await exportToCSVMobile(csv);
    }
  }
}
