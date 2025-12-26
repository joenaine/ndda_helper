# Libook/UpToDate Integration - Implementation Guide

## Step-by-Step Implementation

### Step 1: Add Dependencies

Update `pubspec.yaml`:

```yaml
dependencies:
  # Existing dependencies...
  
  # Add these for Libook integration:
  oauth2: ^2.0.2
  webview_flutter: ^4.4.2
  crypto: ^3.0.3
  url_launcher: ^6.2.2
```

Run: `flutter pub get`

---

### Step 2: Create Data Models

#### File: `lib/models/libook_user.dart`

```dart
class LibookUser {
  final String id;
  final String name;
  final String email;
  final List<LibookGroup> groups;

  LibookUser({
    required this.id,
    required this.name,
    required this.email,
    required this.groups,
  });

  factory LibookUser.fromJson(Map<String, dynamic> json) {
    return LibookUser(
      id: json['sub'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      groups: (json['groups'] as List?)
              ?.map((g) => LibookGroup.fromJson(g))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub': id,
      'name': name,
      'email': email,
      'groups': groups.map((g) => g.toJson()).toList(),
    };
  }

  bool get hasActiveSubscription {
    return groups.any((g) => g.isActive);
  }

  DateTime? get subscriptionExpiryDate {
    final activeSubs = groups.where((g) => g.isActive).toList();
    if (activeSubs.isEmpty) return null;
    activeSubs.sort((a, b) => b.expiryDate.compareTo(a.expiryDate));
    return activeSubs.first.expiryDate;
  }

  String get accessLevel {
    final activeSub = groups.firstWhere(
      (g) => g.isActive,
      orElse: () => LibookGroup.empty(),
    );
    return activeSub.accessLevel;
  }
}

class LibookGroup {
  final int resellerId;
  final String database;
  final String accessLevel;
  final DateTime registryDate;
  final DateTime expiryDate;
  final bool isActive;

  LibookGroup({
    required this.resellerId,
    required this.database,
    required this.accessLevel,
    required this.registryDate,
    required this.expiryDate,
    required this.isActive,
  });

  factory LibookGroup.fromJson(Map<String, dynamic> json) {
    return LibookGroup(
      resellerId: json['reseller_id'] ?? 0,
      database: json['database'] ?? '',
      accessLevel: json['accesslevel'] ?? '',
      registryDate: DateTime.parse(json['registery_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
      isActive: json['is_active'] ?? false,
    );
  }

  factory LibookGroup.empty() {
    return LibookGroup(
      resellerId: 0,
      database: '',
      accessLevel: '',
      registryDate: DateTime.now(),
      expiryDate: DateTime.now(),
      isActive: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reseller_id': resellerId,
      'database': database,
      'accesslevel': accessLevel,
      'registery_date': registryDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isExpiringSoon {
    final daysUntilExpiry = expiryDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }
}
```

---

### Step 3: Create Authentication Service

#### File: `lib/services/libook_auth_service.dart`

```dart
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

    final params = {
      'client_id': _clientId,
      'scope': _scope,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'state': state,
    };

    final uri = Uri.parse('$_authUrl/revo/authorize')
        .replace(queryParameters: params);

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

  // Fetch current session
  Future<bool> fetchSession() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/auth/session'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if user is authenticated (has 'sub' field)
        if (data['sub'] != null) {
          // Store session token from cookies if available
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
```

---

### Step 4: Create UpToDate API Service

#### File: `lib/services/uptodate_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'libook_auth_service.dart';
import '../models/drug_model.dart';

class UpToDateService {
  final LibookAuthService _authService = LibookAuthService();
  static const String _baseUrl = 'https://utd.libook.xyz';

  // Search drug in UpToDate
  Future<List<UpToDateDrugResult>> searchDrug(String query) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      // TODO: Replace with actual UpToDate API endpoint
      final response = await http.get(
        Uri.parse('$_baseUrl/api/search?q=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Parse results
        return []; // TODO: Parse actual response
      }
      return [];
    } catch (e) {
      print('Error searching UpToDate: $e');
      return [];
    }
  }

  // Get drug monograph
  Future<String?> getDrugMonograph(String drugId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      
      // TODO: Replace with actual UpToDate API endpoint
      final response = await http.get(
        Uri.parse('$_baseUrl/api/monograph/$drugId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      print('Error getting monograph: $e');
      return null;
    }
  }

  // Check drug availability in UpToDate
  Future<bool> isDrugAvailable(Drug drug) async {
    try {
      final results = await searchDrug(drug.name);
      return results.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

class UpToDateDrugResult {
  final String id;
  final String title;
  final String? description;

  UpToDateDrugResult({
    required this.id,
    required this.title,
    this.description,
  });
}
```

---

### Step 5: Create Login Screen

#### File: `lib/screens/libook_login_screen.dart`

```dart
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
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      final authUrl = await _authService.getAuthorizationUrl();

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
            },
            onNavigationRequest: (NavigationRequest request) {
              // Check if it's a callback URL
              if (request.url.startsWith(
                'https://utd.libook.xyz/api/auth/callback',
              )) {
                _handleCallback(request.url);
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(authUrl));

      setState(() {});
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize login: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleCallback(String url) async {
    try {
      setState(() => _isLoading = true);
      
      final uri = Uri.parse(url);
      final success = await _authService.handleAuthCallback(uri);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _error = 'Authentication failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error during authentication: $e';
        _isLoading = false;
      });
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
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
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
```

---

### Step 6: Create Account/Settings Screen with Libook Integration

#### File: `lib/screens/account_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/libook_auth_service.dart';
import '../models/libook_user.dart';
import 'libook_login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final LibookAuthService _authService = LibookAuthService();
  LibookUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _login() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LibookLoginScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      _loadUser();
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_user == null) _buildLoginSection() else _buildUserSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoginSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.book, size: 64, color: Colors.black),
            const SizedBox(height: 16),
            const Text(
              'Connect to UpToDate',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Access comprehensive drug information and clinical guidelines',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection() {
    final expiryDate = _user!.subscriptionExpiryDate;
    final isExpiringSoon = expiryDate != null &&
        expiryDate.difference(DateTime.now()).inDays <= 30;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.black,
                  child: Text(
                    _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _user!.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _user!.email,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _user!.hasActiveSubscription
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _user!.hasActiveSubscription
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Text(
                    _user!.hasActiveSubscription ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: _user!.hasActiveSubscription
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subscription Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Access Level', _user!.accessLevel),
                if (expiryDate != null) ...[
                  const Divider(),
                  _buildInfoRow(
                    'Expires',
                    DateFormat('MMM dd, yyyy').format(expiryDate),
                  ),
                  if (isExpiringSoon) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your subscription expires soon',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Logout'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### Step 7: Add Account Button to Home Screen

In `lib/screens/home_screen.dart`, add an account icon button to the AppBar:

```dart
AppBar(
  title: const Text('Drug Registry'),
  actions: [
    IconButton(
      icon: const Icon(Icons.account_circle),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AccountScreen(),
          ),
        );
      },
    ),
  ],
),
```

---

### Step 8: Testing Checklist

- [ ] OAuth flow initiates correctly
- [ ] Login page loads in WebView
- [ ] Successful login redirects back to app
- [ ] User session is stored securely
- [ ] User profile displays correctly
- [ ] Subscription status shows accurately
- [ ] Expiry warning appears when < 30 days
- [ ] Logout clears all stored data
- [ ] Handles network errors gracefully
- [ ] Works on both iOS and Android

---

### Step 9: Next Steps & API Discovery

1. **Test Authentication Flow**: 
   - Use the credentials from your HTTP trace
   - Verify token storage and retrieval

2. **Discover UpToDate API Endpoints**:
   - Use browser dev tools to capture API calls
   - Document available endpoints
   - Update `UpToDateService` with real endpoints

3. **Implement Drug Lookup**:
   - Map your Drug model to UpToDate search
   - Display monographs in a web view or custom UI
   - Cache frequently accessed content

4. **Add Features**:
   - Drug interaction checker
   - Dosing calculator
   - Clinical guidelines browser
   - Offline monograph storage

---

## Security Notes

⚠️ **Important**: 
- Never commit credentials to git
- Store client_id in environment variables for production
- Implement certificate pinning for production
- Add biometric authentication for sensitive data
- Regularly refresh session tokens
- Clear sensitive data on app background/close

---

## Troubleshooting

### Issue: WebView not loading
**Solution**: Ensure internet permissions in AndroidManifest.xml and Info.plist

### Issue: OAuth redirect not captured
**Solution**: Verify redirect_uri matches exactly with registered URI

### Issue: Session expires immediately
**Solution**: Check cookie handling and secure storage implementation

### Issue: CORS errors
**Solution**: Use native HTTP client, not web-based fetch

---

## Resources

- [OAuth 2.0 PKCE Flow](https://oauth.net/2/pkce/)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [WebView Flutter](https://pub.dev/packages/webview_flutter)
- [HTTP Package](https://pub.dev/packages/http)

