import 'dart:convert';
import 'dart:io';

/// Script to convert ed.json to Dart code for better performance
/// Run: dart run tools/convert_ed_to_dart.dart
void main() async {
  print('Reading ed.json...');
  final jsonFile = File('assets/ed.json');
  if (!await jsonFile.exists()) {
    print('Error: assets/ed.json not found');
    exit(1);
  }

  final jsonString = await jsonFile.readAsString();
  final List<dynamic> jsonList = jsonDecode(jsonString);

  print('Converting ${jsonList.length} entries to Dart code...');

  final buffer = StringBuffer();
  buffer.writeln('// Auto-generated from ed.json');
  buffer.writeln('// DO NOT EDIT MANUALLY');
  buffer.writeln('');
  buffer.writeln("import '../models/ed_entry.dart';");
  buffer.writeln('');
  buffer.writeln(
    '/// ЕД (Единый Дистрибьютор) data as Dart constants for better performance',
  );
  buffer.writeln('const List<EdEntry> edData = [');

  for (int i = 0; i < jsonList.length; i++) {
    final entry = jsonList[i] as Map<String, dynamic>;

    final atcCode = entry['АТХ Код']?.toString().trim();
    final mnnOrComposition =
        entry['Наименование лекарственного средства (Международное Непатентованное Наименование или состав)']
            ?.toString()
            .trim();
    final characteristic = entry['Характеристика']?.toString().trim();
    final unitOfMeasure =
        entry['Единица измерения - штука (ампула, таблетка, капсула, флакон, бутылка, контейнер, комплект, пара, упаковка, набор, литр, шприц, шприц-ручка)*']
            ?.toString()
            .trim();

    buffer.write('  EdEntry(');
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
    buffer.writeln('),');

    if ((i + 1) % 1000 == 0) {
      print('Processed ${i + 1}/${jsonList.length} entries...');
    }
  }

  buffer.writeln('];');

  final outputFile = File('lib/data/ed_data.dart');
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(buffer.toString());

  print('✓ Successfully generated ${outputFile.path}');
  print('  Total entries: ${jsonList.length}');
}

String _escapeString(String str) {
  return "'${str.replaceAll("'", "\\'").replaceAll('\$', '\\\$')}'";
}
