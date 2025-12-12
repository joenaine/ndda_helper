import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<void> exportToCSVMobile(String csv) async {
  try {
    // Get temporary directory
    final directory = await getTemporaryDirectory();
    final fileName =
        'ndda_selected_drugs_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');

    // Write CSV to file
    await file.writeAsString(csv);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'NDDA Drugs Export',
      text: 'NDDA selected drugs export',
    );
  } catch (e) {
    throw Exception('Failed to export CSV: $e');
  }
}
