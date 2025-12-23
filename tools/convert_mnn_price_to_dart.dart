import 'dart:convert';
import 'dart:io';

/// Script to convert mnn_price.json to Dart code for better performance
/// Only includes entries that have a price
/// Run: dart run tools/convert_mnn_price_to_dart.dart
void main() async {
  print('Reading mnn_price.json...');
  final jsonFile = File('assets/mnn_price.json');
  if (!await jsonFile.exists()) {
    print('Error: assets/mnn_price.json not found');
    exit(1);
  }

  final jsonString = await jsonFile.readAsString();
  final List<dynamic> jsonList = jsonDecode(jsonString);

  print('Filtering entries with prices...');
  int entriesWithPrice = 0;
  final List<Map<String, dynamic>> filteredEntries = [];

  for (final entry in jsonList) {
    final price = entry['Предельная цена по МНН']?.toString().trim();
    if (price != null && price.isNotEmpty) {
      filteredEntries.add(entry as Map<String, dynamic>);
      entriesWithPrice++;
    }
  }

  print(
    'Converting ${filteredEntries.length} entries (with prices) to Dart code...',
  );

  final buffer = StringBuffer();
  buffer.writeln('// Auto-generated from mnn_price.json');
  buffer.writeln('// DO NOT EDIT MANUALLY');
  buffer.writeln('// Only entries with prices are included');
  buffer.writeln('');
  buffer.writeln("import '../models/mnn_price_entry.dart';");
  buffer.writeln('');
  buffer.writeln('/// МНН Price data as Dart constants for better performance');
  buffer.writeln('const List<MnnPriceEntry> mnnPriceData = [');

  for (int i = 0; i < filteredEntries.length; i++) {
    final entry = filteredEntries[i];

    final atcCode = entry['АТХ Код']?.toString().trim();
    final mnnOrComposition =
        entry['Наименование лекарственного средства (Международное Непатентованное Наименование или состав)']
            ?.toString()
            .trim();
    final characteristic = entry['Характеристика']?.toString().trim();
    final unitOfMeasure =
        entry['Единица измерения - штука (ампула, таблетка, капсула, флакон, бутылка, контейнер, комплект, пара, упаковка, набор, литр, шприц, шприц-ручка)']
            ?.toString()
            .trim();
    final maxPrice = entry['Предельная цена по МНН']?.toString().trim();

    buffer.write('  MnnPriceEntry(');
    if (atcCode != null && atcCode.isNotEmpty) {
      buffer.write('atcCode: ${_escapeString(atcCode)}, ');
    }
    if (mnnOrComposition != null && mnnOrComposition.isNotEmpty) {
      buffer.write('mnnOrComposition: ${_escapeString(mnnOrComposition)}, ');
    }
    if (characteristic != null && characteristic.isNotEmpty) {
      buffer.write('characteristic: ${_escapeString(characteristic)}, ');
    }
    if (unitOfMeasure != null && unitOfMeasure.isNotEmpty) {
      buffer.write('unitOfMeasure: ${_escapeString(unitOfMeasure)}, ');
    }
    if (maxPrice != null && maxPrice.isNotEmpty) {
      buffer.write('maxPrice: ${_escapeString(maxPrice)}, ');
    }
    buffer.writeln('),');

    if ((i + 1) % 1000 == 0) {
      print('Processed ${i + 1}/${filteredEntries.length} entries...');
    }
  }

  buffer.writeln('];');

  final outputFile = File('lib/data/mnn_price_data.dart');
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(buffer.toString());

  print('✓ Successfully generated ${outputFile.path}');
  print(
    '  Total entries: ${filteredEntries.length} (from ${jsonList.length} original)',
  );
}

String _escapeString(String str) {
  return "'${str.replaceAll("'", "\\'").replaceAll('\$', '\\\$')}'";
}
