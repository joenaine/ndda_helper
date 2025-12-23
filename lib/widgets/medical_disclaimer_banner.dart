import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalDisclaimerBanner extends StatelessWidget {
  final bool isCompact;
  final VoidCallback? onDismiss;

  const MedicalDisclaimerBanner({
    super.key,
    this.isCompact = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade300, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'This app provides informational purposes only. Always consult a healthcare professional before making medical decisions.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.orange.shade700,
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Medical Disclaimer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  color: Colors.orange.shade700,
                  onPressed: onDismiss,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'IMPORTANT: This application is for informational purposes only and does not provide medical advice, diagnosis, or treatment.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition or treatment.\n'
            '• Never disregard professional medical advice or delay in seeking it because of something you have read in this application.\n'
            '• The drug interaction information provided is not a substitute for professional medical judgment.\n'
            '• If you think you may have a medical emergency, call your doctor or emergency services immediately.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.orange.shade900,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/about'),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('View Full Disclaimer & Citations'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade900,
            ),
          ),
        ],
      ),
    );
  }
}




