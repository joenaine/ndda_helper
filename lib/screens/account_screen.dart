import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/libook_auth_service.dart';
import '../services/libook_headless_auth.dart';
import '../models/libook_user.dart';
import 'libook_login_screen.dart';
import 'uptodate_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final LibookAuthService _authService = LibookAuthService();
  LibookUser? _user;
  bool _isLoading = true;
  bool _autoLoginEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadAutoLoginStatus();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  Future<void> _loadAutoLoginStatus() async {
    final enabled = await _authService.isAutoLoginEnabled();
    setState(() {
      _autoLoginEnabled = enabled;
    });
  }

  Future<void> _toggleAutoLogin(bool value) async {
    await _authService.setAutoLoginEnabled(value);
    setState(() {
      _autoLoginEnabled = value;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
              ? '✅ Auto-login enabled' 
              : '🔒 Auto-login disabled (credentials cleared)',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
      _loadAutoLoginStatus();
    }
  }

  Future<void> _quickHeadlessLogin() async {
    // Show input dialog
    final emailController = TextEditingController(text: 'joenaine10@gmail.com');
    final passwordController = TextEditingController(text: '990325Jan#');
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
    
    if (result != true || !mounted) return;
    
    // Show loading
    setState(() => _isLoading = true);
    
    try {
      final headlessAuth = LibookHeadlessAuth();
      final success = await headlessAuth.loginHeadless(
        emailController.text,
        passwordController.text,
      );
      
      if (success) {
        // Save credentials for auto-login
        await _authService.saveCredentials(
          emailController.text,
          passwordController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Login successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          _loadUser();
          _loadAutoLoginStatus();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Login failed. Please check your credentials.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    _loadUser();
    _loadAutoLoginStatus();
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
                  if (_user == null)
                    _buildLoginSection()
                  else
                    _buildUserSection(),
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
              child: ElevatedButton.icon(
                onPressed: _quickHeadlessLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.flash_on, size: 20),
                label: const Text('Quick Seamless Login'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _login,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Login with Browser'),
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
                    _user!.name.isNotEmpty
                        ? _user!.name[0].toUpperCase()
                        : 'U',
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
        // Auto-login settings card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-Login Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Auto-Login'),
                  subtitle: const Text(
                    'Automatically re-authenticate when session expires',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _autoLoginEnabled,
                  onChanged: _toggleAutoLogin,
                  activeColor: Colors.green,
                ),
                if (_autoLoginEnabled)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your credentials are securely encrypted',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Open UpToDate button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UpToDateScreen(),
                ),
              );
            },
            icon: const Icon(Icons.library_books),
            label: const Text('Open UpToDate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Logout button
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

