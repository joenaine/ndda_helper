import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nddahelper/widgets/app_hide_keyboard_widget.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/uptodate_search_result.dart';
import '../services/libook_auth_service.dart';
import '../services/libook_headless_auth.dart';
import 'libook_login_screen.dart';

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
  bool _isInitializingApiWebView = true; // Track initialization state

  @override
  void initState() {
    super.initState();
    _initApiWebView();
  }

  Future<void> _initApiWebView() async {
    print('🌐 Initializing API WebView...');

    // Create a hidden WebView that stays on the UpToDate domain
    // This WebView has all the authentication cookies
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            print('✅ API WebView loaded: $url');
            if (mounted) {
              setState(() {
                _isInitializingApiWebView = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ API WebView error: ${error.description}');
          },
        ),
      );

    _apiWebViewController = controller;

    // Load the page and wait for it
    await controller.loadRequest(Uri.parse('https://utd.libook.xyz/'));

    // Give it a moment to fully initialize
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _refreshSession() async {
    print('🔄 Refreshing session seamlessly...');

    // Try headless authentication first
    final authService = LibookAuthService();
    var credentials = await authService.getSavedCredentials();

    // If no credentials saved, use hardcoded ones
    if (credentials == null) {
      print('📝 No credentials saved, using default credentials...');
      const defaultEmail = 'joenaine10@gmail.com';
      const defaultPassword = '990325Jan#';

      // Save the default credentials for future use
      await authService.saveCredentials(defaultEmail, defaultPassword);
      credentials = {'email': defaultEmail, 'password': defaultPassword};
    }

    final headlessAuth = LibookHeadlessAuth();
    final success = await headlessAuth.loginHeadless(
      credentials['email']!,
      credentials['password']!,
    );

    if (success) {
      print('✅ Session refreshed seamlessly via headless auth');
      // Reload the API WebView with fresh cookies
      await _apiWebViewController?.loadRequest(
        Uri.parse('https://utd.libook.xyz/'),
      );
      await Future.delayed(const Duration(seconds: 1));
      return;
    }

    // Fallback to WebView reload if headless failed
    print('⚠️ Headless auth failed, falling back to WebView reload');
    await _apiWebViewController?.loadRequest(
      Uri.parse('https://utd.libook.xyz/'),
    );
    await Future.delayed(const Duration(seconds: 2));
    print('⚠️ Session refresh via WebView reload completed');
  }

  Future<void> _handleSessionExpired() async {
    if (!mounted) return;

    print('🚨 Handling expired session...');

    // Check if auto-login is enabled
    final authService = LibookAuthService();
    var credentials = await authService.getSavedCredentials();

    // If no credentials saved, use hardcoded ones and save them
    if (credentials == null) {
      print('📝 No credentials saved, using default credentials...');
      const defaultEmail = 'joenaine10@gmail.com';
      const defaultPassword = '990325Jan#';

      // Save the default credentials
      await authService.saveCredentials(defaultEmail, defaultPassword);
      credentials = {'email': defaultEmail, 'password': defaultPassword};

      print('✅ Default credentials saved for future use');
    }

    // Try seamless headless re-authentication WITHOUT showing any UI
    print('🔄 Attempting seamless headless re-authentication...');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔐 Authenticating seamlessly...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    }

    final headlessAuth = LibookHeadlessAuth();
    final success = await headlessAuth.loginHeadless(
      credentials['email']!,
      credentials['password']!,
    );

    if (success) {
      // Successfully re-authenticated, refresh the API WebView
      await _apiWebViewController?.loadRequest(
        Uri.parse('https://utd.libook.xyz/'),
      );
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Logged in seamlessly!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Headless failed, fall back to WebView
    print('⚠️ Headless auth failed, falling back to WebView login...');
    if (mounted) {
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const LibookLoginScreen(),
          fullscreenDialog: true,
        ),
      );

      if (result == true) {
        await _refreshSession();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Re-authentication successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
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

  Future<void> _performSearch(String query, {bool isRetry = false}) async {
    print('🔎 _performSearch called with: "$query" (retry: $isRetry)');

    if (query.isEmpty) {
      print('⚠️ Query is empty, clearing results');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Wait if still initializing
    if (_isInitializingApiWebView) {
      print('⏳ API WebView still initializing, waiting...');
      // Wait up to 3 seconds
      for (int i = 0; i < 30; i++) {
        if (!_isInitializingApiWebView) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (_isInitializingApiWebView) {
        print('❌ API WebView initialization timeout');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Still initializing... Please wait'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
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
        (function() {
          console.log('🔍 Starting search for: ${Uri.encodeComponent(query)}');
          window.flutterSearchResults = null;
          window.flutterSearchError = null;
          
          (async function() {
            try {
              console.log('📡 Making fetch request...');
              const response = await fetch('https://utd.libook.xyz/api/search/autocomplete?term=${Uri.encodeComponent(query)}', {
                credentials: 'include',
                headers: {
                  'Accept': 'application/json',
                }
              });
              
              console.log('📊 Response status:', response.status);
              const text = await response.text();
              console.log('📄 Response text length:', text.length);
              console.log('📄 Response preview:', text.substring(0, 100));
              
              // Check if response is HTML (session expired)
              if (text.startsWith('<!DOCTYPE') || text.startsWith('<html')) {
                console.error('❌ Session expired - got HTML instead of JSON');
                window.flutterSearchError = 'SESSION_EXPIRED';
                window.flutterSearchResults = '[]';
                return;
              }
              
              const data = JSON.parse(text);
              window.flutterSearchResults = JSON.stringify(data);
              console.log('✅ Search got ' + data.length + ' results');
              console.log('✅ Stored in window.flutterSearchResults');
            } catch (e) {
              console.error('❌ Search error:', e);
              console.error('❌ Error details:', e.message);
              window.flutterSearchError = e.toString();
              window.flutterSearchResults = '[]';
            }
          })();
        })();
      ''');

      // Give JavaScript a moment to start executing
      await Future.delayed(const Duration(milliseconds: 200));

      // Wait for the fetch to complete
      // Poll for results with timeout
      String? resultsJson;
      String? errorMessage;

      print('⏰ Polling for JavaScript results...');
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 150));

        // Check for errors first
        try {
          final error = await _apiWebViewController!.runJavaScriptReturningResult(
            'typeof window.flutterSearchError !== "undefined" && window.flutterSearchError !== null ? window.flutterSearchError : "NO_ERROR"',
          );
          final errorStr = error.toString();
          print('Poll $i - Error check: $errorStr');

          if (errorStr != 'NO_ERROR' && errorStr.contains('SESSION_EXPIRED')) {
            errorMessage = 'SESSION_EXPIRED';
            break;
          }
        } catch (e) {
          print('⚠️ Error checking error variable: $e');
        }

        // Check for results
        try {
          final result = await _apiWebViewController!.runJavaScriptReturningResult(
            'typeof window.flutterSearchResults !== "undefined" && window.flutterSearchResults !== null ? window.flutterSearchResults : "STILL_LOADING"',
          );
          final resultStr = result.toString();
          print(
            'Poll $i - Result: ${resultStr.length > 50 ? "${resultStr.substring(0, 50)}..." : resultStr}',
          );

          if (resultStr != 'STILL_LOADING' &&
              resultStr != 'null' &&
              resultStr != '<null>') {
            resultsJson = resultStr;
            print('✅ Got results on poll attempt $i');
            break;
          }
        } catch (e) {
          print('⚠️ Error checking results variable: $e');
        }
      }

      // Handle session expiry
      if (errorMessage == 'SESSION_EXPIRED') {
        print('⚠️ Session expired detected');

        if (!isRetry) {
          // Try to refresh session and retry once
          print('🔄 Attempting to refresh session...');
          await _refreshSession();

          // Retry the search
          return await _performSearch(query, isRetry: true);
        } else {
          // Already retried, session is really expired
          print('❌ Session still expired after refresh');
          _handleSessionExpired();

          if (mounted) {
            setState(() {
              _searchResults = [];
              _isSearching = false;
            });
          }
          return;
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

        print(
          '📄 Clean JSON: ${jsonString.substring(0, jsonString.length > 100 ? 100 : jsonString.length)}...',
        );

        final List<dynamic> data = json.decode(jsonString);
        final results = data
            .map(
              (item) =>
                  UpToDateSearchResult.fromJson(item as Map<String, dynamic>),
            )
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
    return AppHideKeyBoardWidget(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('UpToDate'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          actions: [
            // Refresh session button
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () async {
                await _refreshSession();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Session refreshed'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              tooltip: 'Refresh Session',
            ),
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
            // Initialization banner
            if (_isInitializingApiWebView)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.orange.shade100,
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Initializing search engine...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

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
            Expanded(child: _buildContent()),
          ],
        ),
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
                child: CircularProgressIndicator(color: Colors.black),
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
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    // Show empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Search for drugs, conditions, or topics',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Start typing to see suggestions',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
