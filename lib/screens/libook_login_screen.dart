import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/libook_auth_service.dart';

class LibookLoginScreen extends StatefulWidget {
  const LibookLoginScreen({super.key});

  @override
  State<LibookLoginScreen> createState() => _LibookLoginScreenState();
}

class _LibookLoginScreenState extends State<LibookLoginScreen> {
  final LibookAuthService _authService = LibookAuthService();
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _isProcessingCallback = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      final authUrl = await _authService.getAuthorizationUrl();

      // Check if we have saved credentials for auto-login
      final savedCredentials = await _authService.getSavedCredentials();

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() => _isLoading = true);
              }
            },
            onPageFinished: (String url) async {
              if (mounted) {
                setState(() => _isLoading = false);
              }

              // Auto-fill credentials if on login page
              if (savedCredentials != null && url.contains('dispatcher.libook.xyz/login')) {
                print('🔐 Auto-filling login credentials...');
                await Future.delayed(const Duration(milliseconds: 500));
                
                try {
                  // Escape any special characters in credentials for JavaScript
                  final email = savedCredentials['email']!.replaceAll("'", "\\'");
                  final password = savedCredentials['password']!.replaceAll("'", "\\'");
                  
                  await _controller!.runJavaScript('''
                    const emailInput = document.querySelector('input[name="username"], input[type="email"]');
                    const passwordInput = document.querySelector('input[name="password"], input[type="password"]');
                    const submitButton = document.querySelector('button[type="submit"], input[type="submit"]');
                    
                    if (emailInput && passwordInput) {
                      emailInput.value = '$email';
                      passwordInput.value = '$password';
                      console.log('✅ Credentials filled');
                      
                      // Auto-submit the form
                      if (submitButton) {
                        setTimeout(() => {
                          submitButton.click();
                          console.log('✅ Form submitted');
                        }, 500);
                      }
                    }
                  ''');
                  print('✅ Auto-login submitted');
                } catch (e) {
                  print('⚠️ Could not auto-fill: $e');
                }
              } else if (url.contains('dispatcher.libook.xyz/login') && savedCredentials == null) {
                // First time login - inject script to capture credentials on submit
                print('📝 Injecting credential capture script...');
                await Future.delayed(const Duration(milliseconds: 500));
                
                try {
                  await _controller!.runJavaScript('''
                    const form = document.querySelector('form');
                    if (form && !form.dataset.listenerAdded) {
                      form.dataset.listenerAdded = 'true';
                      form.addEventListener('submit', (e) => {
                        const emailInput = form.querySelector('input[name="username"], input[type="email"]');
                        const passwordInput = form.querySelector('input[name="password"], input[type="password"]');
                        
                        if (emailInput && passwordInput) {
                          window.flutterCredentials = {
                            email: emailInput.value,
                            password: passwordInput.value
                          };
                          console.log('✅ Credentials captured for saving');
                        }
                      });
                    }
                  ''');
                } catch (e) {
                  print('⚠️ Could not inject capture script: $e');
                }
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              print('Navigation to: ${request.url}');
              // Allow the OAuth flow to complete naturally
              // We'll detect success on page finish
              return NavigationDecision.navigate;
            },
            onUrlChange: (UrlChange change) {
              if (change.url != null) {
                print('URL changed to: ${change.url}');
                // Check if we've successfully landed on the UpToDate main site
                // This happens after OAuth completes and all redirects are done
                if (!_isProcessingCallback &&
                    change.url!.startsWith('https://utd.libook.xyz/') &&
                    !change.url!.contains('/api/auth/') &&
                    !change.url!.contains('signin') &&
                    !change.url!.contains('callback')) {
                  // We're at the main UpToDate site - auth succeeded!
                  print('Auth completed! Now at: ${change.url}');
                  _isProcessingCallback = true;
                  _handleCallback(change.url!);
                }
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(authUrl));

      if (mounted) {
        setState(() {
          _controller = controller;
          _isLoading = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize login: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleCallback(String url) async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      // Wait for page to fully load and JavaScript to be ready
      await Future.delayed(const Duration(milliseconds: 1500));

      if (_controller == null) {
        throw Exception('Controller not initialized');
      }

      print('Fetching session data from WebView...');

      // Since runJavaScriptReturningResult doesn't handle async properly,
      // we'll use a two-step approach:
      // 1. Execute async fetch and store result in window
      // 2. Read the stored result
      
      // Step 1: Fetch and store
      await _controller!.runJavaScript('''
(async function() {
  window.flutterSessionData = {status: 'loading'};
  try {
    console.log('Fetching session...');
    const response = await fetch('https://utd.libook.xyz/api/auth/session', {
      credentials: 'include',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });
    
    if (!response.ok) {
      console.error('Response not OK:', response.status);
      window.flutterSessionData = {status: 'error', error: 'HTTP_' + response.status};
      return;
    }
    
    const text = await response.text();
    console.log('Response text:', text);
    console.log('Text length:', text.length);
    
    // Verify it's valid JSON
    const data = JSON.parse(text);
    console.log('Parsed OK, has sub:', data.sub);
    console.log('Parsed OK, has email:', data.email);
    
    // Store in window
    window.flutterSessionData = {status: 'success', data: text};
    console.log('Stored in window.flutterSessionData');
  } catch (e) {
    console.error('Fetch error:', e);
    window.flutterSessionData = {status: 'error', error: e.toString()};
  }
})();
      ''');

      // Step 2: Wait a moment, then read the stored result
      print('Waiting for fetch to complete...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final sessionJs = await _controller!.runJavaScriptReturningResult(
        'window.flutterSessionData && window.flutterSessionData.status === "success" ? window.flutterSessionData.data : JSON.stringify(window.flutterSessionData || {error: "No data"})'
      );

      print('Raw session JS result: $sessionJs');
      print('Result type: ${sessionJs.runtimeType}');
      print('Result length: ${sessionJs.toString().length}');
      
      // The JavaScript returns the raw JSON text from response.text()
      // WebView may wrap it in quotes, so we need to handle that
      String cleanJson = sessionJs.toString();
      
      print('As string: $cleanJson');
      print('String length: ${cleanJson.length}');
      
      // Remove outer quotes if WebView added them
      if (cleanJson.startsWith('"') && cleanJson.endsWith('"')) {
        print('Removing outer quotes...');
        cleanJson = cleanJson.substring(1, cleanJson.length - 1);
        // Unescape common escape sequences
        cleanJson = cleanJson
            .replaceAll('\\\\', '\\')
            .replaceAll('\\"', '"')
            .replaceAll('\\n', '\n')
            .replaceAll('\\r', '\r')
            .replaceAll('\\t', '\t');
      }

      print('Cleaned JSON: $cleanJson');
      print('Cleaned length: ${cleanJson.length}');

      // Now parse the JSON
      final sessionData = json.decode(cleanJson) as Map<String, dynamic>;

      // Check for errors
      if (sessionData.containsKey('error')) {
        throw Exception('Session fetch error: ${sessionData['error']}');
      }

      // Check if we have valid session data
      if (sessionData['sub'] != null && sessionData['email'] != null) {
        print('✓ Valid session found for: ${sessionData['name']}');
        
        // Store the session data
        await _authService.storeUserData(sessionData);

        // Try to capture and save credentials for auto-login
        try {
          final credentialsJs = await _controller!.runJavaScriptReturningResult(
            'JSON.stringify(window.flutterCredentials || {})',
          );
          
          if (credentialsJs.toString() != '{}') {
            final cleanJson = credentialsJs.toString().replaceAll('"', '');
            if (cleanJson != '{}') {
              final credentials = json.decode(cleanJson);
              if (credentials['email'] != null && credentials['password'] != null) {
                await _authService.saveCredentials(
                  credentials['email'],
                  credentials['password'],
                );
                print('💾 Credentials saved for auto-login');
              }
            }
          }
        } catch (e) {
          print('⚠️ Could not save credentials: $e');
        }

        // Note: We cannot extract HttpOnly cookies (__Secure-next-auth.session-token)
        // from JavaScript. These cookies will remain in the WebView's cookie store.
        // For API calls, we'll need to use the WebView's JavaScript context.
        print('✅ Session authenticated successfully');
        print('⚠️ Note: Using WebView cookie store for API calls');

        if (!mounted) return;
        
        // Success! Return to account screen
        Navigator.of(context).pop(true);
      } else {
        throw Exception('Invalid session data - missing required fields');
      }
    } catch (e) {
      print('❌ Callback error: $e');
      _isProcessingCallback = false; // Reset so they can try again
      if (mounted) {
        setState(() {
          _error = 'Authentication error:\n${e.toString()}\n\nPlease try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to UpToDate'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          else if (_controller != null)
            WebViewWidget(controller: _controller!)
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            ),
          if (_isLoading && _controller != null)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

