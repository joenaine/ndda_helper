import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nddahelper/services/haptic_service.dart';
import 'package:nddahelper/services/ndda_auth_service.dart';
import 'package:nddahelper/widgets/medical_disclaimer_banner.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HapticService _hapticService = HapticService();
  final NddaAuthService _authService = NddaAuthService();
  bool _hapticsEnabled = true;
  bool _isLoggedIn = false;
  bool _checkingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _checkingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Medical Disclaimer (hidden on web)
          if (!kIsWeb) ...[
            const MedicalDisclaimerBanner(),
            const SizedBox(height: 24),
          ],

          // Haptics Section
          _buildSection(
            title: 'Haptic Feedback',
            icon: Icons.vibration,
            children: [
              SwitchListTile(
                title: const Text('Enable Haptic Feedback'),
                subtitle: const Text(
                  'Feel vibrations when interacting with the app',
                ),
                value: _hapticsEnabled,
                onChanged: (value) {
                  _hapticService.selectionClick();
                  setState(() {
                    _hapticsEnabled = value;
                  });
                },
                activeTrackColor: Colors.black,
                activeThumbColor: Colors.white,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // About & Legal Section (hidden on web)
          if (!kIsWeb)
            _buildSection(
              title: 'About & Legal',
              icon: Icons.info_outline,
              children: [
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Medical Disclaimer & Citations'),
                  subtitle: const Text('View full disclaimer and data sources'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _hapticService.selectionClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

          // if (!kIsWeb) const SizedBox(height: 16),

          // const SizedBox(height: 16),

          // NDDA Account Section
          // _buildSection(
          //   title: 'NDDA Account',
          //   icon: Icons.account_circle,
          //   children: [
          //     if (_checkingAuth)
          //       const ListTile(
          //         leading: CircularProgressIndicator(strokeWidth: 2),
          //         title: Text('Checking login status...'),
          //       )
          //     else if (_isLoggedIn) ...[
          //       ListTile(
          //         leading: const Icon(Icons.check_circle, color: Colors.green),
          //         title: const Text('Logged In'),
          //         subtitle: const Text('Connected to NDDA system'),
          //       ),
          //       const Divider(height: 1),
          //       ListTile(
          //         leading: const Icon(Icons.logout, color: Colors.red),
          //         title: const Text('Logout'),
          //         subtitle: const Text('Sign out from NDDA'),
          //         trailing: const Icon(Icons.chevron_right),
          //         onTap: () => _showLogoutConfirmation(),
          //       ),
          //     ] else ...[
          //       ListTile(
          //         leading: const Icon(Icons.error_outline, color: Colors.orange),
          //         title: const Text('Not Logged In'),
          //         subtitle: const Text('Login required for Yellow Card submission'),
          //       ),
          //       const Divider(height: 1),
          //       ListTile(
          //         leading: const Icon(Icons.login, color: Colors.blue),
          //         title: const Text('Login to NDDA'),
          //         subtitle: const Text('Enter your NDDA credentials'),
          //         trailing: const Icon(Icons.chevron_right),
          //         onTap: () => _showLoginDialog(),
          //       ),
          //     ],
          //   ],
          // ),
          const SizedBox(height: 16),

          // App Info Section
          _buildSection(
            title: 'App Information',
            icon: Icons.apps,
            children: [
              const ListTile(
                leading: Icon(Icons.tag),
                title: Text('Version'),
                trailing: Text('1.0.0'),
              ),
              const ListTile(
                leading: Icon(Icons.code),
                title: Text('Build Number'),
                trailing: Text('2'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.black, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Future<void> _showLoginDialog() async {
    _hapticService.selectionClick();

    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.login, color: Colors.blue),
              SizedBox(width: 8),
              Text('Login to NDDA'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                enabled: !isLoading,
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (usernameController.text.isEmpty ||
                          passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter username and password'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final success = await _authService.login(
                          usernameController.text,
                          passwordController.text,
                        );

                        if (success) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Successfully logged in!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _checkLoginStatus();
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Login failed. Please check your credentials.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          setDialogState(() => isLoading = false);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        setDialogState(() => isLoading = false);
                      }
                    },
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );

    usernameController.dispose();
    passwordController.dispose();
  }

  Future<void> _showLogoutConfirmation() async {
    _hapticService.selectionClick();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout from NDDA?\n\n'
          'You will need to login again to submit Yellow Cards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out'),
            backgroundColor: Colors.black,
          ),
        );
        _checkLoginStatus();
      }
    }
  }
}
