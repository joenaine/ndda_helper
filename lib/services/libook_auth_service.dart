import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/libook_user.dart';

class LibookAuthService {
  static const String _baseUrl = 'https://utd.libook.xyz';
  static const String _authUrl = 'https://dispatcher.libook.xyz';
  static const String _clientId = 'YYrrB62w9z5OmQ1sP6vBfqyKFP7IA2yjN8Jqt0ae';
  static const String _redirectUri = '$_baseUrl/api/auth/callback/libook';
  static const String _scope = 'read write groups';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _keySessionToken = 'libook_session_token';
  static const String _keyUserData = 'libook_user_data';
  static const String _keyCodeVerifier = 'libook_code_verifier';

  // PKCE Helper: Generate code verifier
  String _generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  // PKCE Helper: Generate code challenge from verifier
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  // Generate OAuth URL with PKCE
  Future<String> getAuthorizationUrl() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    final state = _generateCodeVerifier(); // Random state for CSRF protection

    // Store for later use
    await _storage.write(key: _keyCodeVerifier, value: codeVerifier);
    await _storage.write(key: 'libook_state', value: state);

    // Build the authorization URL with PKCE parameters
    // These parameters are used by the OAuth flow
    final authParams = {
      'client_id': _clientId,
      'scope': _scope,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
    };

    // Build the full authorization URI (used internally by the OAuth flow)
    Uri.parse('$_authUrl/revo/authorize').replace(queryParameters: authParams);

    // Return the signin URL that will redirect to the auth endpoint
    return '$_baseUrl/api/auth/signin/libook';
  }

  // Handle OAuth callback with authorization code
  Future<bool> handleAuthCallback(Uri callbackUri) async {
    final code = callbackUri.queryParameters['code'];
    final state = callbackUri.queryParameters['state'];

    if (code == null || state == null) {
      throw Exception('Invalid callback parameters');
    }

    // Verify state
    final storedState = await _storage.read(key: 'libook_state');
    if (state != storedState) {
      throw Exception('State mismatch - possible CSRF attack');
    }

    // Exchange code for session
    return await _exchangeCodeForSession(code);
  }

  Future<bool> _exchangeCodeForSession(String code) async {
    try {
      // In a real implementation, this would exchange the code
      // For now, we'll fetch the session directly
      return await fetchSession();
    } catch (e) {
      print('Error exchanging code: $e');
      return false;
    }
  }

  // Store session cookies extracted from WebView
  Future<void> storeSessionCookies(String cookies) async {
    await _storage.write(key: _keySessionToken, value: cookies);
    print('Stored cookies: $cookies');
  }

  // Store user data directly from WebView session
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _keyUserData, value: json.encode(userData));
    print('Stored user data for: ${userData['name']}');
  }

  // Fetch current session
  Future<bool> fetchSession() async {
    try {
      // Get stored cookies
      final storedCookies = await _storage.read(key: _keySessionToken);
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      
      if (storedCookies != null) {
        headers['Cookie'] = storedCookies;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/session'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if user is authenticated (has 'sub' field)
        if (data['sub'] != null) {
          // Update cookies if new ones provided
          final cookies = response.headers['set-cookie'];
          if (cookies != null) {
            await _storage.write(key: _keySessionToken, value: cookies);
          }

          // Store user data
          await _storage.write(key: _keyUserData, value: json.encode(data));
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error fetching session: $e');
      return false;
    }
  }

  // Get current user
  Future<LibookUser?> getCurrentUser() async {
    try {
      final userData = await _storage.read(key: _keyUserData);
      if (userData == null) return null;

      final data = json.decode(userData);
      return LibookUser.fromJson(data);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null && user.hasActiveSubscription;
  }

  // Logout
  Future<void> logout() async {
    try {
      // Call logout endpoint
      await http.post(
        Uri.parse('$_baseUrl/api/auth/signout'),
      );
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      // Clear local storage regardless of API response
      await _storage.delete(key: _keySessionToken);
      await _storage.delete(key: _keyUserData);
      await _storage.delete(key: _keyCodeVerifier);
      await _storage.delete(key: 'libook_state');
    }
  }

  // Get authorization headers for API calls
  Future<Map<String, String>> getAuthHeaders() async {
    final sessionToken = await _storage.read(key: _keySessionToken);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (sessionToken != null) {
      headers['Cookie'] = sessionToken;
    }

    return headers;
  }
}

