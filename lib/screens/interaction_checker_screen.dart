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

class _InteractionCheckerScreenState extends State<InteractionCheckerScreen> {
  final DrugsComService _service = DrugsComService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<DrugSuggestion> _suggestions = [];
  final List<InteractionDrug> _selectedDrugs = [];
  List<InteractionResult> _interactions = [];
  bool _isSearching = false;
  bool _isCheckingInteractions = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  String? _summaryText;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        _interactions = []; // Clear previous results
        _summaryText = null;
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
      _interactions = [];
      _summaryText = null;
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
      _interactions = [];
      _summaryText = null;
    });

    try {
      // Build drug list string
      String drugList;
      if (_selectedDrugs.length == 1 && _selectedDrugs[0].drugList != null) {
        drugList = _selectedDrugs[0].drugList!;
      } else {
        drugList = _service.buildDrugList(_selectedDrugs);
      }

      // Fetch HTML
      final htmlContent = await _service.checkInteractions(drugList);

      // Parse HTML
      final interactions = _service.parseInteractionHtml(htmlContent);

      // Extract summary from HTML
      String? summary;
      try {
        final div = html.DivElement()..innerHtml = htmlContent;
        final summaryP = div.querySelector('p.ddc-mgb-0');
        if (summaryP != null && summaryP.text != null) {
          summary = summaryP.text!.trim();
        }
      } catch (e) {
        // Ignore summary parsing errors
      }

      setState(() {
        _interactions = interactions;
        _summaryText = summary;
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

          // Results section
          Expanded(
            child: _isCheckingInteractions
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : _interactions.isEmpty
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
                : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    // Group interactions by severity
    final majorInteractions = _interactions
        .where((i) => i.severity == InteractionSeverity.major)
        .toList();
    final moderateInteractions = _interactions
        .where((i) => i.severity == InteractionSeverity.moderate)
        .toList();
    final minorInteractions = _interactions
        .where((i) => i.severity == InteractionSeverity.minor)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary
        if (_summaryText != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              _summaryText!,
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
}
