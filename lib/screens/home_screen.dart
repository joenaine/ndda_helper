import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nddahelper/widgets/app_hide_keyboard_widget.dart';
import '../models/drug_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';
import '../services/haptic_service.dart';
import '../services/knf_service.dart';
import '../services/ed_service.dart';
import '../services/mnn_price_service.dart';
import '../widgets/drug_card.dart';
import 'interaction_checker_screen.dart';
import 'settings_screen.dart';
import 'yellow_card_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final CsvService _csvService = CsvService();
  final HapticService _hapticService = HapticService();
  final KnfService _knfService = KnfService();
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
      // Preload КНФ data (instant, no async needed - data is compiled as Dart code)
      _knfService.loadKnfData();

      // Preload ЕД data (instant, no async needed - data is compiled as Dart code)
      final edService = EdService();
      edService.loadEdData();

      // Preload МНН Price data (instant, no async needed - data is compiled as Dart code)
      final mnnPriceService = MnnPriceService();
      mnnPriceService.loadMnnPriceData();

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
    _hapticService.selectionClick();
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

  Future<void> _exportSelected() async {
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

    try {
      await _csvService.exportToCSV(selectedDrugs, context: context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${selectedDrugs.length} drug(s) to CSV'),
            backgroundColor: Colors.black,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _selectAllFiltered() {
    setState(() {
      for (var drug in _filteredDrugs) {
        _selectedDrugIds.add(drug.id);
      }
    });
    _storageService.saveSelectedDrugs(_selectedDrugIds);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected ${_filteredDrugs.length} drug(s)'),
        backgroundColor: Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppHideKeyBoardWidget(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'ЛИСТ РЕГИСТРАЦИИ ЛЕКАРСТВ РК',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          actions: [
            // Yellow Card Registration button
            IconButton(
              onPressed: () {
                _hapticService.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const YellowCardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.assignment, color: Colors.black),
              tooltip: 'Yellow Card Registration',
            ),
            // Drug Interaction Checker button
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InteractionCheckerScreen(),
                ),
              ),
              icon: const Icon(Icons.medication_liquid, color: Colors.black),
              tooltip: 'Drug Interaction Checker',
            ),
            // Settings button (hidden on web)
            if (!kIsWeb)
              IconButton(
                onPressed: () {
                  _hapticService.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, color: Colors.black),
                tooltip: 'Settings',
              ),
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
            // Data Source Citation Banner (hidden on web)
            if (!kIsWeb)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.source,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Drug registry data from NDDA Kazakhstan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/about'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Citations',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                      const SizedBox(width: 8),
                      // Select All button
                      if (_filteredDrugs.isNotEmpty)
                        InkWell(
                          onTap: _selectAllFiltered,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.select_all,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Select All',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
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
      ),
    );
  }
}
