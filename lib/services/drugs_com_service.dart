import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:universal_html/html.dart' as html;
import '../models/drug_suggestion_model.dart';
import '../models/interaction_drug_model.dart';
import '../models/interaction_result_model.dart';
import 'dio_helper.dart';

class DrugsComService {
  static const String _baseUrl = 'https://www.drugs.com';
  static const String _autocompleteUrl = '$_baseUrl/api/autocomplete/';
  static const String _saveUrl = '$_baseUrl/api/interaction/list-save/';
  static const String _checkUrl = '$_baseUrl/interactions-check.php';
  static const String _interactionListUrl = '$_baseUrl/interaction/list/';

  final DioHelper _dioHelper = DioHelper.instance;
  String? _csrfToken;

  // Common headers for drugs.com requests
  Map<String, dynamic> get _browserHeaders => {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.5',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Origin': 'https://www.drugs.com',
    'Connection': 'keep-alive',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
    'Priority': 'u=0',
    'TE': 'trailers',
    'X-Client-Date': _getClientDate(),
  };

  String _getClientDate() {
    final now = DateTime.now().toUtc();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    return '$dateStr GMT';
  }

  // Fetch CSRF token from the interaction list page
  Future<String?> _fetchCsrfToken() async {
    if (_csrfToken != null) {
      return _csrfToken;
    }

    try {
      final response = await _dioHelper.get(
        _interactionListUrl,
        options: Options(
          headers: {..._browserHeaders, 'Referer': 'https://www.drugs.com/'},
        ),
      );

      if (response.statusCode == 200) {
        final htmlContent = response.data as String;

        // PRIMARY: Look for csrfToken in JavaScript config
        var csrfMatch = RegExp(
          r'"csrfToken"\s*:\s*"([a-f0-9]{40,64})"',
        ).firstMatch(htmlContent);

        if (csrfMatch != null) {
          _csrfToken = csrfMatch.group(1);
          print('✅ Found CSRF token: $_csrfToken');
          return _csrfToken;
        }

        // Try to find CSRF token in meta tag with double quotes
        var metaMatch = RegExp(
          r'<meta\s+name="csrf-token"\s+content="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(htmlContent);

        if (metaMatch != null) {
          _csrfToken = metaMatch.group(1);
          print('✅ Found CSRF token in meta: $_csrfToken');
          return _csrfToken;
        }

        // Try with single quotes
        metaMatch = RegExp(
          r"<meta\s+name='csrf-token'\s+content='([^']+)'",
          caseSensitive: false,
        ).firstMatch(htmlContent);

        if (metaMatch != null) {
          _csrfToken = metaMatch.group(1);
          print('✅ Found CSRF token in meta (single quotes): $_csrfToken');
          return _csrfToken;
        }

        // Try to find it in a script tag
        var scriptMatch = RegExp(
          r'csrf[_-]?token\s*[:=]\s*"([a-f0-9]{40,64})"',
          caseSensitive: false,
        ).firstMatch(htmlContent);

        if (scriptMatch != null) {
          _csrfToken = scriptMatch.group(1);
          print('✅ Found CSRF token in script: $_csrfToken');
          return _csrfToken;
        }

        print('❌ CSRF token not found in HTML');
      }
    } on DioException catch (e) {
      print('DioError fetching CSRF token: ${e.message}');
    } catch (e) {
      print('Error fetching CSRF token: $e');
    }

    return null;
  }

  // Search for drugs using autocomplete API
  Future<List<DrugSuggestion>> searchDrugs(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    try {
      final response = await _dioHelper.get(
        _autocompleteUrl,
        queryParameters: {'type': 'interaction', 's': query},
        options: Options(
          headers: {..._browserHeaders, 'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = response.data as Map<String, dynamic>;
        final categories = jsonData['categories'] as List<dynamic>?;

        if (categories == null || categories.isEmpty) {
          return [];
        }

        final results = <DrugSuggestion>[];
        for (var category in categories) {
          final categoryData = category as Map<String, dynamic>;
          final categoryResults = categoryData['results'] as List<dynamic>?;
          if (categoryResults != null) {
            for (var result in categoryResults) {
              results.add(
                DrugSuggestion.fromJson(result as Map<String, dynamic>),
              );
            }
          }
        }

        return results;
      } else {
        throw Exception('Failed to search drugs: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError searching drugs: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error searching drugs: $e');
      rethrow;
    }
  }

  // Save a drug to the interaction list
  Future<InteractionDrug> saveDrug(int ddcId, int brandNameId) async {
    try {
      // Fetch CSRF token if not already available
      await _fetchCsrfToken();

      if (_csrfToken == null) {
        throw Exception('Failed to obtain CSRF token');
      }

      final requestBody = {
        'interaction_list_id': 0,
        'list_name': '',
        'drugs': [
          {
            'ddc_id': ddcId,
            'brand_name_id': brandNameId,
            'interaction_list_id': 0,
          },
        ],
      };

      final response = await _dioHelper.post(
        _saveUrl,
        data: jsonEncode(requestBody),
        options: Options(
          headers: {
            ..._browserHeaders,
            'Content-Type': 'application/json',
            'X-CSRF-Token': _csrfToken,
            'Referer': 'https://www.drugs.com/interaction/list/?drug_list=',
          },
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = response.data as Map<String, dynamic>;
        final drugs = jsonData['drugs'] as List<dynamic>?;

        if (drugs != null && drugs.isNotEmpty) {
          final drugData = drugs[0] as Map<String, dynamic>;
          final drug = InteractionDrug.fromJson(drugData);

          // Store the drug_list from the response
          final drugList = jsonData['drug_list'] as String?;
          return InteractionDrug(
            ddcId: drug.ddcId,
            brandNameId: drug.brandNameId,
            drugName: drug.drugName,
            genericName: drug.genericName,
            interactionListDrugId: drug.interactionListDrugId,
            interactionListId: drug.interactionListId,
            drugList: drugList,
          );
        } else {
          throw Exception('No drug data in response');
        }
      } else {
        throw Exception('Failed to save drug: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError saving drug: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error saving drug: $e');
      rethrow;
    }
  }

  // Check interactions for a list of drugs
  Future<String> checkInteractions(String drugList) async {
    try {
      final response = await _dioHelper.get(
        _checkUrl,
        queryParameters: {'drug_list': drugList},
        options: Options(headers: _browserHeaders),
      );

      if (response.statusCode == 200) {
        return response.data as String;
      } else {
        throw Exception('Failed to check interactions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError checking interactions: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error checking interactions: $e');
      rethrow;
    }
  }

  // Parse HTML to extract interaction results
  List<InteractionResult> parseInteractionHtml(String htmlContent) {
    final results = <InteractionResult>[];

    try {
      // Create a temporary div to parse the HTML
      final div = html.DivElement()..innerHtml = htmlContent;

      // Find all interaction reference divs within the parsed content
      final interactionDivs = div.querySelectorAll('.interactions-reference');

      for (var div in interactionDivs) {
        try {
          // Extract severity
          final severitySpan = div.querySelector(
            '.status-category-major, .status-category-moderate, .status-category-minor',
          );
          InteractionSeverity severity = InteractionSeverity.unknown;
          if (severitySpan != null) {
            final classes = severitySpan.classes;
            if (classes.contains('status-category-major')) {
              severity = InteractionSeverity.major;
            } else if (classes.contains('status-category-moderate')) {
              severity = InteractionSeverity.moderate;
            } else if (classes.contains('status-category-minor')) {
              severity = InteractionSeverity.minor;
            }
          }

          // Extract title from h3
          final h3 = div.querySelector('h3');
          String title = '';
          if (h3 != null && h3.text != null) {
            title = h3.text!.trim();
            // Remove the drug vs drug icon text if present
            title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
          }

          // Extract description from p tags
          final paragraphs = div.querySelectorAll('p');
          String description = '';
          List<String> drugs = [];

          for (var p in paragraphs) {
            final text = p.text?.trim() ?? '';
            if (text.startsWith('Applies to:')) {
              // Extract drug names from "Applies to:" paragraph
              final appliesToText = text.replaceFirst('Applies to:', '').trim();
              drugs = appliesToText
                  .split(',')
                  .map((d) => d.trim())
                  .where((d) => d.isNotEmpty)
                  .toList();
            } else if (text.isNotEmpty && !text.startsWith('Applies to:')) {
              // This is the description
              if (description.isNotEmpty) {
                description += '\n\n';
              }
              description += text;
            }
          }

          // Determine category based on parent h2
          String category = 'drug-drug';
          final parentH2 = div.parent?.querySelector('h2');
          if (parentH2 != null && parentH2.text != null) {
            final h2Text = parentH2.text!.toLowerCase();
            if (h2Text.contains('food') || h2Text.contains('lifestyle')) {
              category = 'food';
            } else if (h2Text.contains('disease')) {
              category = 'disease';
            }
          }

          if (title.isNotEmpty || description.isNotEmpty) {
            results.add(
              InteractionResult(
                severity: severity,
                title: title,
                description: description,
                drugs: drugs,
                category: category,
              ),
            );
          }
        } catch (e) {
          print('Error parsing interaction div: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error parsing HTML: $e');
    }

    return results;
  }

  // Build drug list string from list of drugs
  String buildDrugList(List<InteractionDrug> drugs) {
    if (drugs.isEmpty) return '';

    // Use the drug_list from the last saved drug, or build from ddc_id and brand_name_id
    if (drugs.length == 1 && drugs[0].drugList != null) {
      return drugs[0].drugList!;
    }

    // For multiple drugs, we need to combine them
    // The format is: "ddc_id-brand_name_id,ddc_id-brand_name_id"
    return drugs.map((drug) => '${drug.ddcId}-${drug.brandNameId}').join(',');
  }
}
