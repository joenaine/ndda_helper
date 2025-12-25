import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateAlertDialog {
  static void show(
    BuildContext context, {
    String? title,
    String? content,
    bool isRequired = false,
    String? androidLink,
    String? iosLink,
  }) {
    // Default store URLs
    String getAppUrl() {
      if (Platform.isAndroid) {
        return androidLink != null && androidLink.isNotEmpty
            ? androidLink
            : 'https://play.google.com/store/apps/details?id=com.clinpharm.kz';
      } else {
        return iosLink != null && iosLink.isNotEmpty
            ? iosLink
            : 'https://apps.apple.com/app/id6756504098';
      }
    }

    if (Platform.isAndroid) {
      showDialog(
        barrierDismissible: !isRequired,
        context: context,
        builder: (context) {
          return PopScope(
            canPop: !isRequired,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              title: Text(
                title ?? 'Update Available',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              content: content != null
                  ? Text(
                      content,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    )
                  : null,
              actionsAlignment: MainAxisAlignment.center,
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: <Widget>[
                Row(
                  children: [
                    if (!isRequired)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Отложить',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    if (!isRequired) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openUrl(getAppUrl()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Обновить',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: !isRequired,
        builder: (BuildContext context) {
          return PopScope(
            canPop: !isRequired,
            child: CupertinoAlertDialog(
              title: Text(title ?? 'Update Available'),
              content: Text(
                content ?? 'A new version is available. Please update.',
              ),
              actions: <Widget>[
                if (!isRequired)
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Later',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => _openUrl(getAppUrl()),
                  child: const Text(
                    'Update Now',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  static Future<void> _openUrl(String url) async {
    final parsedUrl = Uri.parse(url);
    if (await canLaunchUrl(parsedUrl)) {
      await launchUrl(parsedUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $parsedUrl';
    }
  }
}
