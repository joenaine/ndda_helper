import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'libook_auth_service.dart';

/// Headless authentication service that performs OAuth flow without WebView
class LibookHeadlessAuth {
  final LibookAuthService _authService = LibookAuthService();
  
  /// Perform complete OAuth2 + PKCE login flow in background
  /// Returns true if successful, false otherwise
  Future<bool> loginHeadless(String email, String password) async {
    try {
      print('🔐 Starting headless authentication...');
      
      // Create HTTP client (it follows redirects by default, but we'll check each step)
      final client = http.Client();
      final cookies = <String, String>{};
      
      // Step 1: Initiate OAuth by POSTing to signin (like browser does)
      print('1️⃣ Initiating OAuth flow via POST to signin...');
      
      // First, GET the CSRF token from the signin page
      var response = await client.get(
        Uri.parse('https://utd.libook.xyz/api/auth/signin/libook'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );
      
      _extractCookies(response, cookies);
      
      // Extract next-auth CSRF token from the page or cookies
      String? csrfToken;
      if (cookies.containsKey('__Host-next-auth.csrf-token')) {
        // Token is in format: hash|hash, we need the first part
        final tokenParts = cookies['__Host-next-auth.csrf-token']!.split('%7C');
        if (tokenParts.isNotEmpty) {
          csrfToken = Uri.decodeComponent(tokenParts[0]);
        }
      }
      
      if (csrfToken == null) {
        throw Exception('Could not get next-auth CSRF token');
      }
      
      print('✅ Got next-auth CSRF token: ${csrfToken.substring(0, 10)}...');
      
      // Now POST to initiate OAuth flow
      response = await client.post(
        Uri.parse('https://utd.libook.xyz/api/auth/signin/libook'),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': _buildCookieHeader(cookies),
          'Origin': 'https://utd.libook.xyz',
          'Referer': 'https://utd.libook.xyz/api/auth/signin/libook',
        },
        body: {
          'csrfToken': csrfToken,
          'callbackUrl': 'https://utd.libook.xyz/',
        },
      );
      
      _extractCookies(response, cookies);
      print('📍 POST signin response: ${response.statusCode}');
      
      // Manually follow redirects until we reach the Django login page
      int redirectCount = 0;
      const maxRedirects = 10;
      
      while ((response.statusCode == 302 || response.statusCode == 303 || response.statusCode == 307) && redirectCount < maxRedirects) {
        redirectCount++;
        final location = response.headers['location'];
        if (location == null) {
          print('⚠️ No location header in redirect #$redirectCount');
          break;
        }
        
        final currentUrl = response.request?.url ?? Uri.parse('https://utd.libook.xyz');
        final nextUrl = _buildAbsoluteUrl(location, currentUrl);
        print('📍 Redirect #$redirectCount: ${nextUrl.scheme}://${nextUrl.host}${nextUrl.path}${nextUrl.hasQuery ? "?" + nextUrl.query : ""}');
        
        response = await client.get(
          nextUrl,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Cookie': _buildCookieHeader(cookies),
            'Referer': currentUrl.toString(),
          },
        );
        
        _extractCookies(response, cookies);
        print('    ↳ Status: ${response.statusCode}');
        
        // Check if we've reached a non-redirect page
        if (response.statusCode == 200) {
          // Check if this is the Django login page by looking for login form in HTML
          if (nextUrl.host.contains('dispatcher.libook.xyz')) {
            final htmlContent = response.body;
            if (htmlContent.contains('csrfmiddlewaretoken') && 
                (htmlContent.contains('name="username"') || htmlContent.contains('name="password"'))) {
              print('✅ Reached Django login page at ${nextUrl.path}!');
              // Check if we're at /login (proper) vs /revo/authorize (inline form)
              if (nextUrl.path.contains('/login')) {
                print('✅ At proper /login endpoint');
              } else {
                print('⚠️ At inline form (not /login), may need different handling');
              }
              break;
            } else {
              print('⚠️ Got 200 at dispatcher but no login form: ${nextUrl.path}');
            }
          } else {
            print('⚠️ Got 200 but not at dispatcher: ${nextUrl.host}${nextUrl.path}');
          }
        }
      }
      
      if (redirectCount >= maxRedirects) {
        throw Exception('Too many redirects (max $maxRedirects)');
      }
      
      if (response.statusCode != 200) {
        throw Exception('Did not get 200 OK after redirects, got ${response.statusCode}');
      }
      
      // Verify we're at the Django login page by checking for login form
      final htmlContent = response.body;
      if (!htmlContent.contains('csrfmiddlewaretoken') || 
          !(htmlContent.contains('name="username"') || htmlContent.contains('name="password"'))) {
        final finalUrl = response.request?.url.toString() ?? '';
        print('⚠️ No login form found at: $finalUrl');
        print('⚠️ Response length: ${response.body.length}');
        print('⚠️ Response preview: ${response.body.substring(0, response.body.length > 300 ? 300 : response.body.length)}');
        throw Exception('Failed to reach Django login page - no login form found');
      }
      
      print('✅ Verified Django login form is present');
      
      // Step 2: Parse login page to get CSRF token
      print('2️⃣ Parsing login page...');
      final actualUrl = response.request?.url.toString() ?? 'unknown';
      print('📍 Actual page URL: $actualUrl');
      final loginPageHtml = response.body;
      
      // Debug: Check if we got HTML
      if (!loginPageHtml.contains('<html') && !loginPageHtml.contains('<!DOCTYPE')) {
        print('⚠️ Response is not HTML, got: ${loginPageHtml.substring(0, loginPageHtml.length > 200 ? 200 : loginPageHtml.length)}');
        throw Exception('Did not receive HTML login page');
      }
      
      print('✅ Got HTML page, length: ${loginPageHtml.length}');
      
      final document = html_parser.parse(loginPageHtml);
      
      // Extract form action URL and hidden fields
      final form = document.querySelector('form');
      String? formAction;
      String? nextField;
      
      if (form != null) {
        print('✅ Found form element');
        final formHtml = form.outerHtml;
        print('📝 Form HTML preview: ${formHtml.substring(0, formHtml.length > 300 ? 300 : formHtml.length)}');
        
        formAction = form.attributes['action'];
        if (formAction != null && formAction.isNotEmpty) {
          print('📝 Form action attribute: "$formAction"');
        } else {
          print('📝 Form has no action attribute (will POST to current URL)');
        }
        
        // Check for hidden 'next' field
        final nextInput = form.querySelector('input[name="next"]');
        if (nextInput != null) {
          nextField = nextInput.attributes['value'];
          if (nextField != null && nextField.isNotEmpty) {
            print('📝 Found "next" field value: "$nextField"');
          } else {
            print('📝 Found "next" field but it\'s empty');
          }
        } else {
          print('📝 No "next" field in form');
        }
        
        // List all input fields
        final allInputs = form.querySelectorAll('input');
        print('📝 Form has ${allInputs.length} input fields:');
        for (final input in allInputs) {
          final name = input.attributes['name'] ?? 'unnamed';
          final type = input.attributes['type'] ?? 'text';
          final value = input.attributes['value'];
          print('   - $name ($type)${value != null ? ": ${value.substring(0, value.length > 20 ? 20 : value.length)}..." : ""}');
        }
      } else {
        print('⚠️ No form element found');
      }
      
      // Extract CSRF token - try multiple selectors
      var csrfInput = document.querySelector('input[name="csrfmiddlewaretoken"]');
      
      // If not found, try looking in the HTML directly with regex
      if (csrfInput == null) {
        print('⚠️ CSRF input not found with querySelector, trying regex...');
        // Try to find CSRF token in HTML using regex (for both " and ' quotes)
        final csrfRegex = RegExp(r'name="csrfmiddlewaretoken"[^>]*value="([^"]+)"');
        var match = csrfRegex.firstMatch(loginPageHtml);
        if (match == null) {
          // Try with single quotes
          final csrfRegexSingle = RegExp(r"name='csrfmiddlewaretoken'[^>]*value='([^']+)'");
          match = csrfRegexSingle.firstMatch(loginPageHtml);
        }
        if (match != null) {
          final djangoCsrfToken = match.group(1);
          if (djangoCsrfToken != null && djangoCsrfToken.isNotEmpty) {
            print('✅ Got Django CSRF token via regex: ${djangoCsrfToken.substring(0, 10)}...');
            
            // Continue with login using this token
            final currentUrl = response.request!.url;
            
            // Determine where to POST the form
            Uri loginUrl;
            if (formAction != null && formAction.isNotEmpty) {
              loginUrl = _buildAbsoluteUrl(formAction, currentUrl);
              print('📤 POSTing to form action: $loginUrl');
            } else if (currentUrl.path.contains('/revo/authorize')) {
              // Special case: inline form at /revo/authorize should POST to /login
              // with the full current path+query as the 'next' parameter
              final fullPath = currentUrl.path + (currentUrl.query.isNotEmpty ? '?${currentUrl.query}' : '');
              final nextParam = Uri.encodeComponent(fullPath);
              loginUrl = Uri.parse('https://dispatcher.libook.xyz/login?next=$nextParam');
              print('📤 POSTing to /login?next={encoded: $fullPath}');
            } else {
              loginUrl = currentUrl;
              print('📤 POSTing to current URL: $loginUrl');
            }
            
            // Build form data
            final formData = {
              'csrfmiddlewaretoken': djangoCsrfToken,
              'username': email,
              'password': password,
            };
            
            // Add 'next' field if present
            if (nextField != null && nextField.isNotEmpty) {
              formData['next'] = nextField;
              print('📝 Including "next" in form data');
            }
            
            response = await client.post(
              loginUrl,
              headers: {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
                'Content-Type': 'application/x-www-form-urlencoded',
                'Cookie': _buildCookieHeader(cookies),
                'Referer': currentUrl.toString(),
                'Origin': 'https://${currentUrl.host}',
              },
              body: formData,
            );
            
            _extractCookies(response, cookies);
            
            print('📊 Login POST response: ${response.statusCode}');
            if (response.headers['location'] != null) {
              print('📍 Redirecting to: ${response.headers['location']}');
            }
            
            // Check if login was successful by looking at cookies
            if (cookies.containsKey('rvpsess')) {
              print('✅ Got rvpsess cookie - login likely successful!');
            } else {
              print('⚠️ No rvpsess cookie after login POST');
            }
            
            // Continue to step 4
            print('3️⃣ Credentials submitted via regex token');
            // Jump to redirect following
            await _followRedirectsToSession(client, response, cookies);
            return await _fetchAndStoreSession(client, cookies);
          }
        }
        
        // Still not found, dump page content for debugging
        print('❌ CSRF token not found. Page content preview:');
        print(loginPageHtml.substring(0, loginPageHtml.length > 500 ? 500 : loginPageHtml.length));
        throw Exception('CSRF token not found in login page');
      }
      
      final djangoCsrfToken = csrfInput.attributes['value'];
      if (djangoCsrfToken == null || djangoCsrfToken.isEmpty) {
        throw Exception('Django CSRF token is empty');
      }
      
      print('✅ Got Django CSRF token: ${djangoCsrfToken.substring(0, 10)}...');
      
      // Step 3: Submit login form
      print('3️⃣ Submitting credentials...');
      final currentUrl = response.request!.url;
      
      // Determine where to POST the form
      Uri loginUrl;
      if (formAction != null && formAction.isNotEmpty) {
        loginUrl = _buildAbsoluteUrl(formAction, currentUrl);
        print('📤 POSTing to form action: $loginUrl');
      } else if (currentUrl.path.contains('/revo/authorize')) {
        // Special case: inline form at /revo/authorize should POST to /login
        // with the full current path+query as the 'next' parameter
        final fullPath = currentUrl.path + (currentUrl.query.isNotEmpty ? '?${currentUrl.query}' : '');
        final nextParam = Uri.encodeComponent(fullPath);
        loginUrl = Uri.parse('https://dispatcher.libook.xyz/login?next=$nextParam');
        print('📤 POSTing to /login?next={encoded: $fullPath}');
      } else {
        loginUrl = currentUrl;
        print('📤 POSTing to current URL: $loginUrl');
      }
      
      // Build form data
      final formData = {
        'csrfmiddlewaretoken': djangoCsrfToken,
        'username': email,
        'password': password,
      };
      
      // Add 'next' field if present
      if (nextField != null && nextField.isNotEmpty) {
        formData['next'] = nextField;
        print('📝 Including "next" in form data');
      }
      
      // Debug: Show what we're sending
      print('📤 Form data being sent:');
      print('   - csrfmiddlewaretoken: ${djangoCsrfToken.substring(0, 10)}...');
      print('   - username: $email');
      print('   - password: ${"*" * password.length}');
      if (formData.containsKey('next')) {
        print('   - next: ${formData['next']}');
      }
      print('📤 Cookies being sent: ${_buildCookieHeader(cookies)}');
      
      response = await client.post(
        loginUrl,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Cookie': _buildCookieHeader(cookies),
          'Referer': currentUrl.toString(),
          'Origin': 'https://${currentUrl.host}',
        },
        body: formData,
      );
      
      _extractCookies(response, cookies);
      
      print('📊 Login POST response: ${response.statusCode}');
      if (response.headers['location'] != null) {
        print('📍 Redirecting to: ${response.headers['location']}');
      }
      
      // Show cookies after POST
      print('🍪 Cookies after POST:');
      cookies.forEach((name, value) {
        print('   - $name: ${value.substring(0, value.length > 20 ? 20 : value.length)}...');
      });
      
      // Check if login was successful by looking at cookies
      if (cookies.containsKey('rvpsess')) {
        print('✅ Got rvpsess cookie - login likely successful!');
      } else {
        print('⚠️ No rvpsess cookie after login POST');
      }
      
      // If redirecting back to login, show why
      final location = response.headers['location'];
      if (location != null && location.contains('/login')) {
        print('❌ Login was REJECTED - Django redirected back to /login');
        print('   This usually means:');
        print('   1. Invalid credentials');
        print('   2. CSRF token mismatch');
        print('   3. Missing required form field');
      }
      
      // Step 4: Follow redirects to complete OAuth flow
      await _followRedirectsToSession(client, response, cookies);
      return await _fetchAndStoreSession(client, cookies);
    } catch (e, stackTrace) {
      print('❌ Headless auth error: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Extract cookies from HTTP response
  void _extractCookies(http.Response response, Map<String, String> cookies) {
    final setCookieHeaders = response.headers['set-cookie'];
    if (setCookieHeaders != null) {
      // Handle multiple set-cookie headers
      final cookieStrings = setCookieHeaders.split(RegExp(r',(?=\s*\w+=)'));
      
      for (final cookieString in cookieStrings) {
        final cookie = cookieString.split(';')[0].trim();
        final parts = cookie.split('=');
        
        if (parts.length >= 2) {
          final name = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          
          if (value.isNotEmpty && value != '""') {
            cookies[name] = value;
          } else {
            // Cookie being cleared
            cookies.remove(name);
          }
        }
      }
    }
  }
  
  /// Build Cookie header string from cookies map
  String _buildCookieHeader(Map<String, String> cookies) {
    return cookies.entries
        .map((e) => '${e.key}=${e.value}')
        .join('; ');
  }
  
  /// Build absolute URL from potentially relative location
  Uri _buildAbsoluteUrl(String location, Uri baseUrl) {
    if (location.startsWith('http://') || location.startsWith('https://')) {
      return Uri.parse(location);
    }
    
    if (location.startsWith('/')) {
      // Parse relative URL to separate path and query
      final questionMarkIndex = location.indexOf('?');
      if (questionMarkIndex > 0) {
        final path = location.substring(0, questionMarkIndex);
        final query = location.substring(questionMarkIndex + 1);
        return Uri(
          scheme: baseUrl.scheme,
          host: baseUrl.host,
          port: baseUrl.port,
          path: path,
          query: query,
        );
      } else {
        return Uri(
          scheme: baseUrl.scheme,
          host: baseUrl.host,
          port: baseUrl.port,
          path: location,
        );
      }
    }
    
    return baseUrl.resolve(location);
  }
  
  /// Follow OAuth redirects until we get session token
  Future<void> _followRedirectsToSession(
    http.Client client,
    http.Response response,
    Map<String, String> cookies,
  ) async {
    print('4️⃣ Following OAuth redirects...');
    int redirectCount = 0;
    const maxRedirects = 15;
    
    while ((response.isRedirect || response.statusCode == 302) && redirectCount < maxRedirects) {
      redirectCount++;
      final location = response.headers['location'];
      if (location == null) {
        print('⚠️ No location header, stopping redirects');
        break;
      }
      
      final nextUrl = _buildAbsoluteUrl(location, response.request!.url);
      print('📍 Redirect #$redirectCount to: ${nextUrl.host}${nextUrl.path}${nextUrl.query.isNotEmpty ? "?..." : ""}');
      
      response = await client.get(
        nextUrl,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Cookie': _buildCookieHeader(cookies),
        },
      );
      
      print('    ↳ Response: ${response.statusCode}');
      _extractCookies(response, cookies);
      
      // Check if we got the final session token
      if (cookies.containsKey('__Secure-next-auth.session-token')) {
        print('✅ Got session token after $redirectCount redirects!');
        return;
      }
    }
    
    if (redirectCount >= maxRedirects) {
      print('⚠️ Hit max redirects ($maxRedirects)');
    }
    
    // Verify we have the session token
    if (!cookies.containsKey('__Secure-next-auth.session-token')) {
      print('❌ No session token found. Final cookies:');
      cookies.forEach((name, value) {
        print('   - $name: ${value.substring(0, value.length > 20 ? 20 : value.length)}...');
      });
      throw Exception('Failed to obtain session token after $redirectCount redirects');
    }
  }
  
  /// Fetch session data and store it
  Future<bool> _fetchAndStoreSession(
    http.Client client,
    Map<String, String> cookies,
  ) async {
    print('5️⃣ Fetching session data...');
    final response = await client.get(
      Uri.parse('https://utd.libook.xyz/api/auth/session'),
      headers: {
        'User-Agent': 'nddahelper-app',
        'Cookie': _buildCookieHeader(cookies),
        'Accept': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      final sessionData = json.decode(response.body);
      
      if (sessionData['sub'] != null && sessionData['email'] != null) {
        // Store user data
        await _authService.storeUserData(sessionData);
        
        // Store session cookies (just dispatcher cookies, not next-auth)
        final dispatcherCookies = <String>[];
        cookies.forEach((name, value) {
          if (name == 'csrftoken' || name == 'rvpsess') {
            dispatcherCookies.add('$name=$value');
          }
        });
        
        if (dispatcherCookies.isNotEmpty) {
          await _authService.storeSessionCookies(dispatcherCookies.join('; '));
        }
        
        print('✅ Headless authentication successful!');
        print('👤 Logged in as: ${sessionData['name']}');
        
        client.close();
        return true;
      }
    }
    
    client.close();
    throw Exception('Failed to fetch session data');
  }
}

