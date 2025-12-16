import 'package:flutter/material.dart';
import 'package:nddahelper/services/haptic_service.dart';
import 'package:nddahelper/widgets/medical_disclaimer_banner.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HapticService _hapticService = HapticService();
  bool _notificationsEnabled = false;
  bool _hapticsEnabled = true;

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
          // Medical Disclaimer
          const MedicalDisclaimerBanner(),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSection(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            children: [
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text(
                  'Receive updates about drug registry changes and reminders',
                ),
                value: _notificationsEnabled,
                onChanged: (value) {
                  _hapticService.selectionClick();
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                activeTrackColor: Colors.black,
                activeThumbColor: Colors.white,
              ),
            ],
          ),

          const SizedBox(height: 16),

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

          // About & Legal Section
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
}
