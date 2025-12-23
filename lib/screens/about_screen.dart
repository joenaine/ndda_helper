import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
          'About & Disclaimer',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medical Disclaimer Section
            _buildSection(
              title: 'Medical Disclaimer',
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              children: [
                const Text(
                  'IMPORTANT: This application is for informational purposes only and does not provide medical advice, diagnosis, or treatment.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'The information provided in this application, including drug interaction data and drug registry information, is intended for educational and reference purposes only. It is not intended to be a substitute for professional medical advice, diagnosis, or treatment.',
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition, medication, or treatment. Never disregard professional medical advice or delay in seeking it because of something you have read in this application.',
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The drug interaction information provided is based on general medical knowledge and databases, but individual reactions may vary. It is not a substitute for professional medical judgment, and should not be used to make decisions about medication use without consulting a healthcare professional.',
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  'If you think you may have a medical emergency, call your doctor or emergency services immediately. Do not rely on this application for emergency medical situations.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Sources & Citations Section
            _buildSection(
              title: 'Data Sources & Citations',
              icon: Icons.source,
              color: Colors.blue,
              children: [
                const Text(
                  'This application uses data from the following sources:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // Drugs.com Citation
                _buildCitationCard(
                  title: 'Drug Interaction Data',
                  source: 'Drugs.com',
                  url: 'https://www.drugs.com',
                  description:
                      'Drug interaction information is provided by Drugs.com, a comprehensive online drug information resource. The interaction checker uses data from Drugs.com\'s drug interaction database.',
                  onTap: () => _launchUrl('https://www.drugs.com'),
                ),

                const SizedBox(height: 12),

                // NDDA Citation
                _buildCitationCard(
                  title: 'Drug Registry Data',
                  source:
                      'National Drug and Device Agency of Kazakhstan (NDDA)',
                  url: 'https://register.ndda.kz',
                  description:
                      'Drug registration information is sourced from the official National Drug and Device Agency of Kazakhstan (NDDA) registry. This includes registration numbers, drug details, producer information, and official documentation.',
                  onTap: () => _launchUrl('https://register.ndda.kz'),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Note: While we strive to provide accurate and up-to-date information, the data is provided "as is" without warranty of any kind. Users should verify critical information with official sources and healthcare professionals.',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // App Information Section
            _buildSection(
              title: 'App Information',
              icon: Icons.info_outline,
              color: Colors.grey,
              children: [
                _buildInfoRow('Version', '1.0.0'),
                _buildInfoRow(
                  'Purpose',
                  'Drug registry lookup and interaction checking tool',
                ),
                _buildInfoRow('Platform', 'iOS, Android, Web'),
              ],
            ),

            const SizedBox(height: 24),

            // Contact/Support Section
            _buildSection(
              title: 'Support',
              icon: Icons.support_agent,
              color: Colors.green,
              children: [
                const Text(
                  'For questions about drug interactions or medical advice, please consult with a qualified healthcare professional.',
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  'For technical support or questions about the application, please contact the app developer through the App Store or Google Play Store.',
                  style: TextStyle(fontSize: 14, height: 1.6),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCitationCard({
    required String title,
    required String source,
    required String url,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              source,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF374151),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              url,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}




