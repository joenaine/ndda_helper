import 'package:flutter/material.dart';
import '../models/meddra_model.dart';
import '../services/meddra_service.dart';

class MedDraSelectorDialog extends StatefulWidget {
  final String title;

  const MedDraSelectorDialog({
    super.key,
    this.title = 'Выберите диагноз из справочника MedDRA',
  });

  @override
  State<MedDraSelectorDialog> createState() => _MedDraSelectorDialogState();
}

class _MedDraSelectorDialogState extends State<MedDraSelectorDialog> {
  List<MedDraModel> _data = [];
  List<MedDraModel> _filteredData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterData);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final data = await MedDraService.fetchMedDraData();
      setState(() {
        _data = data;
        _filteredData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredData = _data;
      } else {
        _filteredData = _data.where((item) {
          final text = item.text?.toLowerCase() ?? '';
          final abrev = item.abrev?.toLowerCase() ?? '';
          final code = item.code?.toLowerCase() ?? '';
          
          // Also search in child nodes
          bool hasMatchInNodes = false;
          if (item.nodes != null) {
            hasMatchInNodes = item.nodes!.any((node) {
              final nodeText = node.text?.toLowerCase() ?? '';
              final nodeAbrev = node.abrev?.toLowerCase() ?? '';
              final nodeCode = node.code?.toLowerCase() ?? '';
              return nodeText.contains(query) ||
                  nodeAbrev.contains(query) ||
                  nodeCode.contains(query);
            });
          }
          
          return text.contains(query) ||
              abrev.contains(query) ||
              code.contains(query) ||
              hasMatchInNodes;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Поиск',
                hintText: 'Введите название, код или аббревиатуру',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки данных',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _loadData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_filteredData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Ничего не найдено',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredData.length,
      itemBuilder: (context, index) {
        final item = _filteredData[index];
        return _buildMedDraItem(item);
      },
    );
  }

  Widget _buildMedDraItem(MedDraModel item) {
    final hasNodes = item.nodes != null && item.nodes!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          hasNodes ? Icons.folder : Icons.description,
          color: hasNodes ? Colors.blue : Colors.grey,
        ),
        title: Text(
          item.text ?? 'N/A',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            if (item.abrev != null && item.abrev!.isNotEmpty) ...[
              Text(
                item.abrev!,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (item.code != null && item.code!.isNotEmpty)
              Text(
                'Код: ${item.code}',
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
        trailing: !hasNodes
            ? TextButton(
                onPressed: () => _selectItem(item.text ?? ''),
                child: const Text('Выбрать'),
              )
            : null,
        children: hasNodes
            ? [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    children: item.nodes!.map((node) {
                      return ListTile(
                        leading: const Icon(Icons.description, size: 20),
                        title: Text(node.text ?? 'N/A'),
                        subtitle: Row(
                          children: [
                            if (node.abrev != null &&
                                node.abrev!.isNotEmpty) ...[
                              Text(
                                node.abrev!,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (node.code != null && node.code!.isNotEmpty)
                              Text(
                                'Код: ${node.code}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: TextButton(
                          onPressed: () => _selectItem(node.text ?? ''),
                          child: const Text('Выбрать'),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ]
            : [],
      ),
    );
  }

  void _selectItem(String text) {
    Navigator.of(context).pop(text);
  }
}

// Helper function to show the dialog
Future<String?> showMedDraSelector(
  BuildContext context, {
  String title = 'Выберите диагноз из справочника MedDRA',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => MedDraSelectorDialog(title: title),
  );
}

