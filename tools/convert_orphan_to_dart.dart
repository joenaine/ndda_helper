import 'dart:convert';
import 'dart:io';

/// Script to convert orphan.json to Dart code for better performance
/// Run: dart run tools/convert_orphan_to_dart.dart
void main() async {
  print('Reading orphan.json...');
  final jsonFile = File('assets/orphan.json');
  if (!await jsonFile.exists()) {
    print('Error: assets/orphan.json not found');
    exit(1);
  }

  final jsonString = await jsonFile.readAsString();
  final List<dynamic> jsonList = jsonDecode(jsonString);

  print('Converting ${jsonList.length} entries to Dart code...');

  final buffer = StringBuffer();
  buffer.writeln('// Auto-generated from orphan.json');
  buffer.writeln('// DO NOT EDIT MANUALLY');
  buffer.writeln('');
  buffer.writeln("import '../models/orphan_entry.dart';");
  buffer.writeln('');
  buffer.writeln(
    '/// Orphan drug data as Dart constants for better performance',
  );
  buffer.writeln('const List<OrphanEntry> orphanData = [');

  for (int i = 0; i < jsonList.length; i++) {
    final entry = jsonList[i] as Map<String, dynamic>;

    final mnn = entry['MNN']?.toString().trim();
    final atcCode = entry['ATX']?.toString().trim();

    buffer.write('  OrphanEntry(');
    if (mnn != null && mnn.isNotEmpty) {
      buffer.write('mnn: ${_escapeString(mnn)}, ');
    }
    if (atcCode != null && atcCode.isNotEmpty) {
      buffer.write('atcCode: ${_escapeString(atcCode)}, ');
    }
    buffer.writeln('),');

    if ((i + 1) % 100 == 0) {
      print('Processed ${i + 1}/${jsonList.length} entries...');
    }
  }

  buffer.writeln('];');

  final outputFile = File('lib/data/orphan_data.dart');
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(buffer.toString());

  print('✓ Successfully generated ${outputFile.path}');
  print('  Total entries: ${jsonList.length}');
}

String _escapeString(String str) {
  return "'${str.replaceAll("'", "\\'").replaceAll('\$', '\\\$')}'";
}
