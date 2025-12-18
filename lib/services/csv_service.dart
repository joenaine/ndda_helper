import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import '../models/drug_model.dart';

class CsvService {
  // Export selected drugs to CSV
  Future<void> exportToCSV(List<Drug> drugs, {BuildContext? context}) async {
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
      // Mobile platform - write to temporary directory first, then share
      // This ensures the file is accessible for sharing on iOS
      try {
        // Get temporary directory for file sharing
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');

        // Write bytes to file
        await file.writeAsBytes(bytes);

        // Verify file exists before sharing
        if (await file.exists()) {
          final xFile = XFile(file.path, mimeType: 'text/csv', name: fileName);

          // Get share position origin for iOS (required for iPad)
          Rect? sharePositionOrigin;
          if (context != null && !kIsWeb) {
            try {
              final size = MediaQuery.of(context).size;
              // Use bottom center position (where FAB typically is)
              // Ensure the rect is within screen bounds and non-zero
              const width = 112.0;
              const height = 56.0;
              final x = (size.width / 2 - width / 2).clamp(
                0.0,
                size.width - width,
              );
              final y = (size.height - height - 20).clamp(
                0.0,
                size.height - height,
              );
              if (x >= 0 &&
                  y >= 0 &&
                  width > 0 &&
                  height > 0 &&
                  x + width <= size.width &&
                  y + height <= size.height) {
                sharePositionOrigin = Rect.fromLTWH(x, y, width, height);
              }
            } catch (_) {
              // If MediaQuery fails, use null (will use default)
            }
          }

          // Share the file
          await Share.shareXFiles(
            [xFile],
            subject: 'NDDA Selected Drugs Export',
            text: 'Exported ${drugs.length} drug(s) from NDDA Register',
            sharePositionOrigin: sharePositionOrigin,
          );
        } else {
          // If file doesn't exist, fall back to text sharing
          await Share.share(csv, subject: 'NDDA Selected Drugs Export');
        }
      } catch (e) {
        // If sharing fails, try Documents directory as fallback
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(bytes);

          if (await file.exists()) {
            final xFile = XFile(
              file.path,
              mimeType: 'text/csv',
              name: fileName,
            );

            // Get share position origin for iOS (required for iPad)
            Rect? sharePositionOrigin;
            if (context != null && !kIsWeb) {
              try {
                final size = MediaQuery.of(context).size;
                // Use bottom center position (where FAB typically is)
                // Ensure the rect is within screen bounds and non-zero
                const width = 112.0;
                const height = 56.0;
                final x = (size.width / 2 - width / 2).clamp(
                  0.0,
                  size.width - width,
                );
                final y = (size.height - height - 20).clamp(
                  0.0,
                  size.height - height,
                );
                if (x >= 0 &&
                    y >= 0 &&
                    width > 0 &&
                    height > 0 &&
                    x + width <= size.width &&
                    y + height <= size.height) {
                  sharePositionOrigin = Rect.fromLTWH(x, y, width, height);
                }
              } catch (_) {
                // If MediaQuery fails, use null (will use default)
              }
            }

            await Share.shareXFiles(
              [xFile],
              subject: 'NDDA Selected Drugs Export',
              text: 'Exported ${drugs.length} drug(s) from NDDA Register',
              sharePositionOrigin: sharePositionOrigin,
            );
          } else {
            // Last resort: share as text
            await Share.share(csv, subject: 'NDDA Selected Drugs Export');
          }
        } catch (e2) {
          // Last resort: share as text
          await Share.share(csv, subject: 'NDDA Selected Drugs Export');
        }
      }
    }
  }
}
