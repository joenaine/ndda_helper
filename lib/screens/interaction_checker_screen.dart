import 'package:flutter/material.dart';
import 'dart:async';
import 'package:universal_html/html.dart' as html;
import '../models/drug_suggestion_model.dart';
import '../models/interaction_drug_model.dart';
import '../models/interaction_result_model.dart';
import '../services/drugs_com_service.dart';

class InteractionCheckerScreen extends StatefulWidget {
  const InteractionCheckerScreen({super.key});

  @override
  State<InteractionCheckerScreen> createState() =>
      _InteractionCheckerScreenState();
}

class _InteractionCheckerScreenState extends State<InteractionCheckerScreen>
    with SingleTickerProviderStateMixin {
  final DrugsComService _service = DrugsComService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late TabController _tabController;

  List<DrugSuggestion> _suggestions = [];
  final List<InteractionDrug> _selectedDrugs = [];

  // Consumer data
  List<InteractionResult> _consumerInteractions = [];
  String? _consumerSummaryText;
  Map<String, dynamic> _consumerHeader = {};
  bool _isConsumerHeaderExpanded = true;

  // Professional data
  List<InteractionResult> _professionalInteractions = [];
  String? _professionalSummaryText;
  Map<String, dynamic> _professionalHeader = {};
  bool _isProfessionalHeaderExpanded = true;

  bool _isSearching = false;
  bool _isCheckingInteractions = false;
  String? _errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(_searchController.text);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _service.searchDrugs(query);
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
        _errorMessage = 'Failed to search: $e';
      });
    }
  }

  Future<void> _onDrugSelected(DrugSuggestion suggestion) async {
    // Check if drug is already added
    if (_selectedDrugs.any(
      (drug) =>
          drug.ddcId == suggestion.ddcId &&
          drug.brandNameId == suggestion.brandNameId,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Drug already added'),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _errorMessage = null;
      _searchController.clear();
      _suggestions = [];
    });

    try {
      final savedDrug = await _service.saveDrug(
        suggestion.ddcId,
        suggestion.brandNameId,
      );

      setState(() {
        _selectedDrugs.add(savedDrug);
        _consumerInteractions = [];
        _consumerSummaryText = null;
        _consumerHeader = {};
        _isConsumerHeaderExpanded = true;
        _professionalInteractions = [];
        _professionalSummaryText = null;
        _professionalHeader = {};
        _isProfessionalHeaderExpanded = true;
      });

      // Clear search focus
      _searchFocusNode.unfocus();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to add drug: $e';
      });
    }
  }

  void _removeDrug(InteractionDrug drug) {
    setState(() {
      _selectedDrugs.remove(drug);
      _consumerInteractions = [];
      _consumerSummaryText = null;
      _consumerHeader = {};
      _isConsumerHeaderExpanded = true;
      _professionalInteractions = [];
      _professionalSummaryText = null;
      _professionalHeader = {};
      _isProfessionalHeaderExpanded = true;
    });
  }

  Future<void> _checkInteractions() async {
    if (_selectedDrugs.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 2 drugs to check interactions'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() {
      _isCheckingInteractions = true;
      _errorMessage = null;
      _consumerInteractions = [];
      _consumerSummaryText = null;
      _consumerHeader = {};
      _isConsumerHeaderExpanded = true;
      _professionalInteractions = [];
      _professionalSummaryText = null;
      _professionalHeader = {};
      _isProfessionalHeaderExpanded = true;
    });

    try {
      // Build drug list string
      String drugList;
      if (_selectedDrugs.length == 1 && _selectedDrugs[0].drugList != null) {
        drugList = _selectedDrugs[0].drugList!;
      } else {
        drugList = _service.buildDrugList(_selectedDrugs);
      }

      // Fetch both consumer and professional data in parallel
      final results = await Future.wait([
        _service.checkInteractions(drugList, professional: false),
        _service.checkInteractions(drugList, professional: true),
      ]);

      final consumerHtml = results[0];
      final professionalHtml = results[1];

      // Parse consumer data
      final consumerInteractions = _service.parseInteractionHtml(consumerHtml);
      final consumerHeader = _service.parseInteractionHeader(consumerHtml);
      String? consumerSummary;
      try {
        final div = html.DivElement()..innerHtml = consumerHtml;
        final summaryP = div.querySelector('p.ddc-mgb-0');
        if (summaryP != null && summaryP.text != null) {
          consumerSummary = summaryP.text!.trim();
        }
      } catch (e) {
        // Ignore summary parsing errors
      }

      // Parse professional data
      final professionalInteractions = _service.parseInteractionHtml(
        professionalHtml,
      );
      final professionalHeader = _service.parseInteractionHeader(
        professionalHtml,
      );
      String? professionalSummary;
      try {
        final div = html.DivElement()..innerHtml = professionalHtml;
        final summaryP = div.querySelector('p.ddc-mgb-0');
        if (summaryP != null && summaryP.text != null) {
          professionalSummary = summaryP.text!.trim();
        }
      } catch (e) {
        // Ignore summary parsing errors
      }

      setState(() {
        _consumerInteractions = consumerInteractions;
        _consumerSummaryText = consumerSummary;
        _consumerHeader = consumerHeader;
        _isConsumerHeaderExpanded = true;
        _professionalInteractions = professionalInteractions;
        _professionalSummaryText = professionalSummary;
        _professionalHeader = professionalHeader;
        _isProfessionalHeaderExpanded = true;
        _isCheckingInteractions = false;
      });
    } catch (e) {
      setState(() {
        _isCheckingInteractions = false;
        _errorMessage = 'Failed to check interactions: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Drug Interaction Checker',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          // Search section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search for a drug...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 15,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF6B7280),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Color(0xFF6B7280),
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _suggestions = [];
                              });
                            },
                          )
                        : _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),

                // Suggestions dropdown
                if (_suggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            suggestion.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: suggestion.additional.isNotEmpty
                              ? Text(
                                  suggestion.additional,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                )
                              : null,
                          onTap: () => _onDrugSelected(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Selected drugs section
          if (_selectedDrugs.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Drugs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedDrugs.map((drug) {
                      return Chip(
                        label: Text(
                          drug.displayName,
                          style: const TextStyle(fontSize: 13),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeDrug(drug),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _selectedDrugs.length >= 2 && !_isCheckingInteractions
                          ? _checkInteractions
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: const Color(0xFFE5E7EB),
                      ),
                      child: _isCheckingInteractions
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Check Interactions (${_selectedDrugs.length} drug${_selectedDrugs.length == 1 ? '' : 's'})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFFFF5F5),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Tab bar
          if (_consumerInteractions.isNotEmpty ||
              _professionalInteractions.isNotEmpty)
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: Colors.black,
                indicatorWeight: 2,
                labelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Consumer'),
                  Tab(text: 'Professional'),
                ],
              ),
            ),

          // Results section
          Expanded(
            child: _isCheckingInteractions
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : (_consumerInteractions.isEmpty &&
                      _professionalInteractions.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedDrugs.isEmpty
                              ? Icons.medication_liquid
                              : Icons.search,
                          size: 48,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedDrugs.isEmpty
                              ? 'Search and add drugs to check interactions'
                              : 'Click "Check Interactions" to see results',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Consumer view
                      _buildResults(
                        _consumerInteractions,
                        _consumerSummaryText,
                        _consumerHeader,
                        isConsumer: true,
                      ),
                      // Professional view
                      _buildResults(
                        _professionalInteractions,
                        _professionalSummaryText,
                        _professionalHeader,
                        isConsumer: false,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(
    List<InteractionResult> interactions,
    String? summaryText,
    Map<String, dynamic> header, {
    required bool isConsumer,
  }) {
    // Group interactions by severity
    final majorInteractions = interactions
        .where((i) => i.severity == InteractionSeverity.major)
        .toList();
    final moderateInteractions = interactions
        .where((i) => i.severity == InteractionSeverity.moderate)
        .toList();
    final minorInteractions = interactions
        .where((i) => i.severity == InteractionSeverity.minor)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Interaction Header (Interactions between your drugs)
        if (header.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getSeverityColorFromString(
                    header['severity'],
                  ).withOpacity(0.1),
                  _getSeverityColorFromString(
                    header['severity'],
                  ).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getSeverityColorFromString(header['severity']),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  header['header'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getSeverityColorFromString(header['severity']),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        header['severity'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((header['drugs'] as List?)?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (header['drugs'] as List<dynamic>)
                        .map(
                          (drug) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _getSeverityColorFromString(
                                  header['severity'],
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              drug.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (header['description'] != null &&
                    (header['description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getSeverityColorFromString(
                          header['severity'],
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header with expansion button
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isConsumer) {
                                _isConsumerHeaderExpanded =
                                    !_isConsumerHeaderExpanded;
                              } else {
                                _isProfessionalHeaderExpanded =
                                    !_isProfessionalHeaderExpanded;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: _getSeverityColorFromString(
                                    header['severity'],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Icon(
                                  (isConsumer
                                          ? _isConsumerHeaderExpanded
                                          : _isProfessionalHeaderExpanded)
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: const Color(0xFF6B7280),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Expandable content
                        if (isConsumer
                            ? _isConsumerHeaderExpanded
                            : _isProfessionalHeaderExpanded) ...[
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              header['description'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF374151),
                                height: 1.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // Summary
        if (summaryText != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              summaryText,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),

        // Major interactions
        if (majorInteractions.isNotEmpty) ...[
          _buildSeverityHeader('Major', majorInteractions.length, Colors.red),
          const SizedBox(height: 8),
          ...majorInteractions.map(
            (interaction) => _buildInteractionCard(interaction),
          ),
          const SizedBox(height: 16),
        ],

        // Moderate interactions
        if (moderateInteractions.isNotEmpty) ...[
          _buildSeverityHeader(
            'Moderate',
            moderateInteractions.length,
            Colors.orange,
          ),
          const SizedBox(height: 8),
          ...moderateInteractions.map(
            (interaction) => _buildInteractionCard(interaction),
          ),
          const SizedBox(height: 16),
        ],

        // Minor interactions
        if (minorInteractions.isNotEmpty) ...[
          _buildSeverityHeader('Minor', minorInteractions.length, Colors.grey),
          const SizedBox(height: 8),
          ...minorInteractions.map(
            (interaction) => _buildInteractionCard(interaction),
          ),
        ],
      ],
    );
  }

  Widget _buildSeverityHeader(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionCard(InteractionResult interaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: _getSeverityColor(interaction.severity),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          interaction.title.isNotEmpty ? interaction.title : 'Interaction',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: interaction.drugs.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Applies to: ${interaction.drugs.join(', ')}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              )
            : null,
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getSeverityColor(interaction.severity).withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _getSeverityColor(interaction.severity),
              width: 1,
            ),
          ),
          child: Text(
            interaction.severityLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getSeverityColor(interaction.severity),
            ),
          ),
        ),
        children: [
          Text(
            interaction.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(InteractionSeverity severity) {
    switch (severity) {
      case InteractionSeverity.major:
        return Colors.red;
      case InteractionSeverity.moderate:
        return Colors.orange;
      case InteractionSeverity.minor:
        return Colors.grey;
      case InteractionSeverity.unknown:
        return Colors.grey;
    }
  }

  Color _getSeverityColorFromString(String? severity) {
    if (severity == null) return Colors.grey;
    switch (severity.toLowerCase()) {
      case 'major':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'minor':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
