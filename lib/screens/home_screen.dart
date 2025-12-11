import 'package:flutter/material.dart';
import '../models/drug_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';
import '../widgets/drug_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final CsvService _csvService = CsvService();
  final TextEditingController _searchController = TextEditingController();

  List<Drug> _allDrugs = [];
  List<Drug> _filteredDrugs = [];
  Set<int> _selectedDrugIds = {};
  bool _isLoading = true;
  String? _errorMessage;
  bool _showSelectedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterDrugs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load drugs
      final drugs = await _apiService.getDrugs();

      // Load selected drugs
      final selectedIds = await _storageService.loadSelectedDrugs();

      setState(() {
        _allDrugs = drugs;
        _filteredDrugs = drugs;
        _selectedDrugIds = selectedIds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final drugs = await _apiService.getDrugs(forceRefresh: true);

      setState(() {
        _allDrugs = drugs;
        _filterDrugs();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data reloaded successfully'),
            backgroundColor: Colors.black,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to reload data: $e';
        _isLoading = false;
      });
    }
  }

  void _filterDrugs() {
    final query = _searchController.text;

    setState(() {
      if (_showSelectedOnly) {
        _filteredDrugs = _allDrugs
            .where((drug) => _selectedDrugIds.contains(drug.id))
            .where((drug) => drug.matchesSearch(query))
            .toList();
      } else {
        _filteredDrugs = _allDrugs
            .where((drug) => drug.matchesSearch(query))
            .toList();
      }
    });
  }

  void _toggleDrugSelection(Drug drug) {
    setState(() {
      if (_selectedDrugIds.contains(drug.id)) {
        _selectedDrugIds.remove(drug.id);
      } else {
        _selectedDrugIds.add(drug.id);
      }
    });

    _storageService.saveSelectedDrugs(_selectedDrugIds);
  }

  void _toggleShowSelected() {
    setState(() {
      _showSelectedOnly = !_showSelectedOnly;
      _filterDrugs();
    });
  }

  void _exportSelected() {
    final selectedDrugs = _allDrugs
        .where((drug) => _selectedDrugIds.contains(drug.id))
        .toList();

    if (selectedDrugs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No drugs selected for export'),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    _csvService.exportToCSV(selectedDrugs);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${selectedDrugs.length} drug(s) to CSV'),
        backgroundColor: Colors.black,
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedDrugIds.clear();
    });
    _storageService.saveSelectedDrugs(_selectedDrugIds);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selection cleared'),
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'NDDA Helper',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          // Reload button
          IconButton(
            onPressed: _isLoading ? null : _reloadData,
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Reload data',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: Column(
        children: [
          // Search bar and filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, ATC, code...',
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
                            },
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
                const SizedBox(height: 12),

                // Filter chips and stats
                Row(
                  children: [
                    // Show selected toggle
                    InkWell(
                      onTap: _toggleShowSelected,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _showSelectedOnly
                              ? Colors.black
                              : const Color(0xFFF9FAFB),
                          border: Border.all(
                            color: _showSelectedOnly
                                ? Colors.black
                                : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showSelectedOnly
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 16,
                              color: _showSelectedOnly
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Selected (${_selectedDrugIds.length})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _showSelectedOnly
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Results count
                    Text(
                      '${_filteredDrugs.length} result${_filteredDrugs.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _filteredDrugs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchController.text.isNotEmpty
                              ? Icons.search_off
                              : Icons.inbox,
                          size: 48,
                          color: const Color(0xFF6B7280),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'No results found'
                              : 'No data available',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = _filteredDrugs[index];
                      return DrugCard(
                        drug: drug,
                        isSelected: _selectedDrugIds.contains(drug.id),
                        onTap: () => _toggleDrugSelection(drug),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Floating action buttons
      floatingActionButton: _selectedDrugIds.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Clear selection
                FloatingActionButton.extended(
                  onPressed: _clearSelection,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 2,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                ),
                const SizedBox(height: 12),

                // Export button
                FloatingActionButton.extended(
                  onPressed: _exportSelected,
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.download),
                  label: Text('Export (${_selectedDrugIds.length})'),
                ),
              ],
            ),
    );
  }
}
