import 'dart:convert';
import 'dart:io';

/// Script to convert knf.json to Dart code for better performance
/// Run: dart run tools/convert_knf_to_dart.dart
void main() async {
  print('Reading knf.json...');
  final jsonFile = File('assets/knf.json');
  if (!await jsonFile.exists()) {
    print('Error: assets/knf.json not found');
    exit(1);
  }

  final jsonString = await jsonFile.readAsString();
  final List<dynamic> jsonList = jsonDecode(jsonString);

  print('Converting ${jsonList.length} entries to Dart code...');

  final buffer = StringBuffer();
  buffer.writeln('// Auto-generated from knf.json');
  buffer.writeln('// DO NOT EDIT MANUALLY');
  buffer.writeln('');
  buffer.writeln("import '../models/knf_entry.dart';");
  buffer.writeln('');
  buffer.writeln('/// КНФ data as Dart constants for better performance');
  buffer.writeln('const List<KnfEntry> knfData = [');

  for (int i = 0; i < jsonList.length; i++) {
    final entry = jsonList[i] as Map<String, dynamic>;

    final number = entry['№']?.toString().trim();
    final atcCode =
        entry['Код анатомо-терапевтическо-химической (АТХ) классификации']
            ?.toString()
            .trim();
    final mnnOrGroup =
        entry['Фармакологическая группа/ Международное непатентованное наименование или состав']
            ?.toString()
            .trim();
    final tradeName = entry['Торговое наименование']?.toString().trim();
    final dosageForm = entry['Лекарственная форма, дозировка и объем']
        ?.toString()
        .trim();
    final regNumber = entry['Номер регистрационного удостоверения/орфанный']
        ?.toString()
        .trim();

    buffer.write('  KnfEntry(');
    if (number != null && number.isNotEmpty) {
      buffer.write('number: ${_escapeString(number)}, ');
    }
    if (atcCode != null && atcCode.isNotEmpty) {
      buffer.write('atcCode: ${_escapeString(atcCode)}, ');
    }
    if (mnnOrGroup != null && mnnOrGroup.isNotEmpty) {
      buffer.write('mnnOrGroup: ${_escapeString(mnnOrGroup)}, ');
    }
    if (tradeName != null && tradeName.isNotEmpty) {
      buffer.write('tradeName: ${_escapeString(tradeName)}, ');
    }
    if (dosageForm != null && dosageForm.isNotEmpty) {
      buffer.write('dosageForm: ${_escapeString(dosageForm)}, ');
    }
    if (regNumber != null && regNumber.isNotEmpty) {
      buffer.write('regNumber: ${_escapeString(regNumber)}, ');
    }
    buffer.writeln('),');

    if ((i + 1) % 1000 == 0) {
      print('Processed ${i + 1}/${jsonList.length} entries...');
    }
  }

  buffer.writeln('];');

  final outputFile = File('lib/data/knf_data.dart');
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(buffer.toString());

  print('✓ Successfully generated ${outputFile.path}');
  print('  Total entries: ${jsonList.length}');
}

String _escapeString(String str) {
  return "'${str.replaceAll("'", "\\'").replaceAll('\$', '\\\$')}'";
}
