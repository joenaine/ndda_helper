import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import '../models/drug_model.dart';

class CsvService {
  // Export selected drugs to CSV
  void exportToCSV(List<Drug> drugs) {
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
      ],
    ];

    // Add drug data
    for (var drug in drugs) {
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
      ]);
    }

    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(rows);

    // Create blob and download for web
    final bytes = utf8.encode(csv);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download =
          'ndda_selected_drugs_${DateTime.now().millisecondsSinceEpoch}.csv';

    html.document.body?.children.add(anchor);
    anchor.click();

    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }
}
