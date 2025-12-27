import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/uptodate_search_result.dart';

class UpToDateScreen extends StatefulWidget {
  const UpToDateScreen({super.key});

  @override
  State<UpToDateScreen> createState() => _UpToDateScreenState();
}

class _UpToDateScreenState extends State<UpToDateScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UpToDateSearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  UpToDateSearchResult? _selectedResult;
  WebViewController? _contentWebViewController;
  WebViewController? _apiWebViewController; // Hidden WebView for API calls
  bool _isLoadingWebView = false;

  @override
  void initState() {
    super.initState();
    _initApiWebView();
  }

  void _initApiWebView() {
    // Create a hidden WebView that stays on the UpToDate domain
    // This WebView has all the authentication cookies
    _apiWebViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://utd.libook.xyz/'));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounce?.cancel();

    // Debounce search by 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    print('🔎 _performSearch called with: "$query"');
    
    if (query.isEmpty) {
      print('⚠️ Query is empty, clearing results');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (_apiWebViewController == null) {
      print('❌ API WebView not initialized yet, waiting...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (_apiWebViewController == null) {
        print('❌ Still no API WebView, aborting');
        return;
      }
    }

    print('⏳ Starting search via WebView...');
    setState(() => _isSearching = true);

    try {
      // Use JavaScript to make the API call within the WebView context
      // This way all cookies (including HttpOnly) are included
      await _apiWebViewController!.runJavaScript('''
        window.flutterSearchResults = null;
        (async function() {
          try {
            const response = await fetch('https://utd.libook.xyz/api/search/autocomplete?term=${Uri.encodeComponent(query)}', {
              credentials: 'include',
              headers: {
                'Accept': 'application/json',
              }
            });
            const data = await response.json();
            window.flutterSearchResults = JSON.stringify(data);
            console.log('Search got ' + data.length + ' results');
          } catch (e) {
            console.error('Search error:', e);
            window.flutterSearchResults = '[]';
          }
        })();
      ''');

      // Wait for the fetch to complete
      // Poll for results with timeout
      String? resultsJson;
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final result = await _apiWebViewController!.runJavaScriptReturningResult(
          'window.flutterSearchResults',
        );
        if (result.toString() != 'null') {
          resultsJson = result.toString();
          break;
        }
      }

      if (resultsJson == null) {
        throw Exception('No results returned after 2 seconds');
      }

      print('📡 Raw results: $resultsJson');

      if (resultsJson != 'null') {
        String jsonString = resultsJson;
        
        // The result is a JSON string wrapped in quotes: "[{...}]"
        // We need to:
        // 1. Remove outer quotes if present
        // 2. Parse the JSON
        
        if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
          // Remove outer quotes
          jsonString = jsonString.substring(1, jsonString.length - 1);
          print('🧹 Removed outer quotes');
        }
        
        // Unescape the backslashes (\")
        jsonString = jsonString.replaceAll(r'\"', '"');
        jsonString = jsonString.replaceAll(r'\\', r'\');
        
        print('📄 Clean JSON: ${jsonString.substring(0, jsonString.length > 100 ? 100 : jsonString.length)}...');
        
        final List<dynamic> data = json.decode(jsonString);
        final results = data
            .map((item) => UpToDateSearchResult.fromJson(item as Map<String, dynamic>))
            .toList();

        print('📦 Got ${results.length} results');

        if (mounted) {
          setState(() {
            _searchResults = results;
            _isSearching = false;
          });
          print('✅ Updated UI with ${results.length} results');
        }
      } else {
        throw Exception('No results returned');
      }
    } catch (e, stackTrace) {
      print('❌ Search error: $e');
      print('Stack: $stackTrace');
      
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onResultTap(UpToDateSearchResult result) {
    setState(() {
      _selectedResult = result;
      _searchResults = [];
      _searchController.clear();
    });

    // Load the result in WebView
    _loadResultInWebView(result);
  }

  void _loadResultInWebView(UpToDateSearchResult result) {
    setState(() => _isLoadingWebView = true);

    // Create or update WebView controller
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() => _isLoadingWebView = true);
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoadingWebView = false);
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://utd.libook.xyz/contents/search?search=${Uri.encodeComponent(result.english)}',
        ),
      );

    setState(() {
      _contentWebViewController = controller;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _selectedResult = null;
      _contentWebViewController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UpToDate'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedResult != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearSearch,
              tooltip: 'Clear',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search UpToDate...',
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black54),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show WebView if result is selected
    if (_selectedResult != null && _contentWebViewController != null) {
      return Stack(
        children: [
          WebViewWidget(controller: _contentWebViewController!),
          if (_isLoadingWebView)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              ),
            ),
        ],
      );
    }

    // Show search results
    if (_searchResults.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final result = _searchResults[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: InkWell(
              onTap: () => _onResultTap(result),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.display,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (result.english != result.display) ...[
                            const SizedBox(height: 4),
                            Text(
                              result.english,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Show loading indicator
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.black,
        ),
      );
    }

    // Show empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for drugs, conditions, or topics',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start typing to see suggestions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

