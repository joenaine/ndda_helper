import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../models/drug_model.dart';

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
    final bytes = utf8.encode(csv);
    final fileName =
        'ndda_selected_drugs_${DateTime.now().millisecondsSinceEpoch}.csv';

    // Handle export based on platform
    if (kIsWeb) {
      // Web platform - use blob download
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = fileName;

      html.document.body?.children.add(anchor);
      anchor.click();

      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile platform - create XFile from bytes and share
      try {
        // Create XFile directly from bytes - this works across all mobile platforms
        final xFile = XFile.fromData(
          bytes,
          mimeType: 'text/csv',
          name: fileName,
        );

        // Share the file so user can save/view it
        await Share.shareXFiles(
          [xFile],
          subject: 'NDDA Selected Drugs Export',
          text: 'Exported ${drugs.length} drug(s) from NDDA Register',
        );
      } catch (e) {
        // If sharing fails, try to save file first and then share
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(bytes);
          final xFile = XFile(file.path, mimeType: 'text/csv');
          await Share.shareXFiles(
            [xFile],
            subject: 'NDDA Selected Drugs Export',
            text: 'Exported ${drugs.length} drug(s) from NDDA Register',
          );
        } catch (e2) {
          // Last resort: share as text
          await Share.share(csv, subject: 'NDDA Selected Drugs Export');
        }
      }
    }
  }
}
