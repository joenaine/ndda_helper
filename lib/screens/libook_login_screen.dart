import 'dart:async';
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
  String? _error;
  bool _isProcessingCallback = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _startTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    // 45 second timeout for authentication
    _timeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!_isProcessingCallback && mounted) {
        setState(() {
          _error = 'Login timeout.\n\nThe authentication process took too long.\n\nPlease check your internet connection and try again.';
        });
      }
    });
  }

  Future<void> _initWebView() async {
    try {
      final authUrl = await _authService.getAuthorizationUrl();

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('📄 Page started loading: $url');
            },
            onPageFinished: (String url) async {
              print('✅ Page finished loading: $url');
              
              // Handle NextAuth signin page - click the provider button
              if (url.contains('utd.libook.xyz/api/auth/signin')) {
                print('🔘 On signin page, clicking provider button...');
                await Future.delayed(const Duration(milliseconds: 500));
                
                try {
                  await _controller!.runJavaScript('''
                    (function() {
                      console.log('🔍 Looking for signin button...');
                      
                      // Try to find and click the Libook provider button
                      const buttons = document.querySelectorAll('button, a');
                      console.log('Found buttons:', buttons.length);
                      
                      for (let btn of buttons) {
                        const text = btn.textContent || btn.innerText || '';
                        console.log('Button text:', text);
                        if (text.toLowerCase().includes('libook') || text.toLowerCase().includes('sign in')) {
                          console.log('🎯 Found signin button, clicking...');
                          btn.click();
                          return;
                        }
                      }
                      
                      // If no button found, try form submission
                      const form = document.querySelector('form');
                      if (form) {
                        console.log('📝 Found form, submitting...');
                        form.submit();
                      } else {
                        console.log('❌ No button or form found');
                      }
                    })();
                  ''');
                  print('✅ Signin button click script injected');
                } catch (e) {
                  print('⚠️ Could not click signin button: $e');
                }
              }
              // Auto-fill and submit credentials if on login page (or authorize page with embedded login)
              else if (url.contains('dispatcher.libook.xyz/login') || url.contains('dispatcher.libook.xyz/revo/authorize')) {
                print('🔐 Detected login page! Auto-filling credentials...');
                await Future.delayed(const Duration(milliseconds: 800));
                
                try {
                  // Hardcoded credentials for automatic login
                  const email = 'joenaine10@gmail.com';
                  const password = '990325Jan#';
                  
                  await _controller!.runJavaScript('''
                    (function() {
                      console.log('🔍 Checking for login form...');
                      
                      if (window.flutterAutoLoginDone) {
                        console.log('⚠️ Auto-login already attempted');
                        return;
                      }
                      window.flutterAutoLoginDone = true;
                      
                      const emailInput = document.querySelector('input[name="username"], input[type="email"]');
                      const passwordInput = document.querySelector('input[name="password"], input[type="password"]');
                      const submitButton = document.querySelector('button[type="submit"], input[type="submit"]');
                      
                      console.log('📝 Email input found:', !!emailInput);
                      console.log('🔒 Password input found:', !!passwordInput);
                      console.log('🔘 Submit button found:', !!submitButton);
                      
                      if (emailInput && passwordInput) {
                        emailInput.value = '$email';
                        passwordInput.value = '$password';
                        console.log('✅ Credentials auto-filled');
                        
                        // Auto-submit the form
                        if (submitButton) {
                          setTimeout(() => {
                            console.log('🚀 Clicking submit button...');
                            submitButton.click();
                          }, 300);
                        } else {
                          console.log('⚠️ No submit button, trying form submit...');
                          const form = document.querySelector('form');
                          if (form) {
                            setTimeout(() => form.submit(), 300);
                          }
                        }
                      } else {
                        console.log('❌ Could not find login form inputs');
                      }
                    })();
                  ''');
                  print('✅ Auto-login script injected');
                } catch (e) {
                  print('⚠️ Could not auto-fill: $e');
                }
              } else {
                print('ℹ️ Not a login page, skipping auto-fill');
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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize login: $e';
        });
      }
    }
  }

  Future<void> _handleCallback(String url) async {
    try {
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

        // Cancel timeout timer
        _timeoutTimer?.cancel();

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
          // Hidden WebView - handles authentication in background
          if (_controller != null)
            Opacity(
              opacity: 0.0, // Completely invisible
              child: IgnorePointer(
                child: WebViewWidget(controller: _controller!),
              ),
            ),
          // Full-screen loading overlay
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
          else
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Logging in securely...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please wait',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

