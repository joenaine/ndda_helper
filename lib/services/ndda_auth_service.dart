import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dio_helper.dart';

class NddaAuthService {
  static const String _baseUrl = 'https://www.ndda.kz';
  static const String _loginUrl = '$_baseUrl/user/login';
  static const String _yellowCardUrl = '$_baseUrl/register.php/sideeffects/new/lang/ru';

  final DioHelper _dioHelper = DioHelper.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _usernameKey = 'ndda_username';
  static const String _passwordKey = 'ndda_password';

  // Common headers for NDDA requests
  Map<String, dynamic> get _browserHeaders => {
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:146.0) Gecko/20100101 Firefox/146.0',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Origin': _baseUrl,
    'Connection': 'keep-alive',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Fetch-User': '?1',
  };

  /// Login to NDDA system
  /// Returns true if login successful, false otherwise
  /// If saveCredentials is true, credentials will be saved securely
  Future<bool> login(String username, String password, {bool saveCredentials = true}) async {
    try {
      // Prepare form data
      final formData = {
        'UserLogin[username]': username,
        'UserLogin[password]': password,
      };

      // Convert to URL-encoded format
      final encodedData = formData.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final response = await _dioHelper.post(
        _loginUrl,
        data: encodedData,
        options: Options(
          headers: {
            ..._browserHeaders,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Referer': '$_baseUrl/kabinet-dari',
          },
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Check if login was successful (302 redirect to profile page)
      if (response.statusCode == 302) {
        final location = response.headers.value('location');
        if (location != null && location.contains('/user/profile')) {
          // Save credentials if requested
          if (saveCredentials) {
            await _saveCredentials(username, password);
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }
  
  /// Save credentials securely
  Future<void> _saveCredentials(String username, String password) async {
    try {
      await _secureStorage.write(key: _usernameKey, value: username);
      await _secureStorage.write(key: _passwordKey, value: password);
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }
  
  /// Get saved credentials
  /// Returns a map with 'username' and 'password' keys, or null if not saved
  Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final username = await _secureStorage.read(key: _usernameKey);
      final password = await _secureStorage.read(key: _passwordKey);
      
      if (username != null && password != null) {
        return {'username': username, 'password': password};
      }
      return null;
    } catch (e) {
      print('Error reading credentials: $e');
      return null;
    }
  }
  
  /// Check if credentials are saved
  Future<bool> hasSavedCredentials() async {
    final credentials = await getSavedCredentials();
    return credentials != null;
  }
  
  /// Auto-login using saved credentials
  /// Returns true if login successful, false otherwise
  Future<bool> autoLogin() async {
    final credentials = await getSavedCredentials();
    if (credentials == null) return false;
    
    return await login(
      credentials['username']!,
      credentials['password']!,
      saveCredentials: false, // Already saved
    );
  }

  /// Submit yellow card (side effects report)
  /// Returns true if submission successful, false otherwise
  Future<bool> submitYellowCard(Map<String, dynamic> formData) async {
    try {
      // Convert form data to URL-encoded format
      final encodedData = formData.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');

      final response = await _dioHelper.post(
        _yellowCardUrl,
        data: encodedData,
        options: Options(
          headers: {
            ..._browserHeaders,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Referer': _yellowCardUrl,
            'Sec-Fetch-Dest': 'iframe',
          },
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Check if submission was successful
      // Typically returns 200 or 302 on success
      return response.statusCode == 200 || response.statusCode == 302;
    } catch (e) {
      print('Error submitting yellow card: $e');
      return false;
    }
  }

  /// Check if user is logged in by checking cookies
  Future<bool> isLoggedIn() async {
    try {
      final uri = Uri.parse(_baseUrl);
      final cookies = await _dioHelper.getCookies(uri);
      
      // Check if we have a session cookie
      return cookies.any((cookie) => 
        cookie.name == 'PHPSESSID' || 
        cookie.name.startsWith('70df632a8fb0cc0c01ee88db4be8c9eb')
      );
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  /// Logout by clearing cookies and saved credentials
  Future<void> logout() async {
    await _dioHelper.clearCookies();
    await clearSavedCredentials();
  }
  
  /// Clear saved credentials
  Future<void> clearSavedCredentials() async {
    try {
      await _secureStorage.delete(key: _usernameKey);
      await _secureStorage.delete(key: _passwordKey);
    } catch (e) {
      print('Error clearing credentials: $e');
    }
  }
}

