import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import '../widgets/update_alert_dialog.dart';
import 'firebase_repository.dart';

class VersionChecker {
  static final FirebaseRepository _firebaseRepository = FirebaseRepository();

  /// Check for app updates and show alert if needed
  static Future<void> checkForUpdates(BuildContext context) async {
    // Skip version check on web
    if (kIsWeb) {
      log('Skipping version check on web platform');
      return;
    }

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      log('Current app version: $currentVersion');

      final versionModel = await _firebaseRepository.getVersion();

      if (versionModel == null) {
        log('No version data found in Firebase');
        return;
      }

      final isReleased = versionModel.isReleased ?? false;
      if (!isReleased) {
        log('Update is not released yet, skipping alert');
        return;
      }

      if (Platform.isAndroid) {
        await _checkAndroidVersion(
          context,
          currentVersion,
          versionModel.androidVersion,
          versionModel.title,
          versionModel.content,
          versionModel.isRequiredAndroid ?? false,
        );
      } else if (Platform.isIOS) {
        await _checkIOSVersion(
          context,
          currentVersion,
          versionModel.iosVersion,
          versionModel.title,
          versionModel.content,
          versionModel.isRequiredIos ?? false,
        );
      }
    } catch (e, stackTrace) {
      log('Error checking version: $e', error: e, stackTrace: stackTrace);
    }
  }

  static Future<void> _checkAndroidVersion(
    BuildContext context,
    String currentVersion,
    String? firebaseVersion,
    String? title,
    String? content,
    bool isRequired,
  ) async {
    if (firebaseVersion == null || firebaseVersion.isEmpty) {
      log('No Android version specified in Firebase');
      return;
    }

    log('Firebase Android version: $firebaseVersion');
    log('Current device version: $currentVersion');

    try {
      // Use semantic version comparison for Android
      final versionOfBack = Version.parse(firebaseVersion);
      final versionOfPackage = Version.parse(currentVersion);

      if (versionOfBack > versionOfPackage) {
        log('Update available for Android');
        if (context.mounted) {
          UpdateAlertDialog.show(
            context,
            title: title ?? 'Update Available',
            content: content ??
                'A new version of the app is available. Please update to continue.',
            isRequired: isRequired,
          );
        }
      } else {
        log('App is up to date (Android)');
      }
    } catch (e) {
      log('Error comparing Android versions: $e');
    }
  }

  static Future<void> _checkIOSVersion(
    BuildContext context,
    String currentVersion,
    String? firebaseVersion,
    String? title,
    String? content,
    bool isRequired,
  ) async {
    if (firebaseVersion == null || firebaseVersion.isEmpty) {
      log('No iOS version specified in Firebase');
      return;
    }

    log('Firebase iOS version: $firebaseVersion');
    log('Current device version: $currentVersion');

    try {
      // For iOS, also use semantic version comparison
      final versionOfBack = Version.parse(firebaseVersion);
      final versionOfPackage = Version.parse(currentVersion);

      if (versionOfBack > versionOfPackage) {
        log('Update available for iOS');
        if (context.mounted) {
          UpdateAlertDialog.show(
            context,
            title: title ?? 'Update Available',
            content: content ??
                'A new version of the app is available. Please update to continue.',
            isRequired: isRequired,
          );
        }
      } else {
        log('App is up to date (iOS)');
      }
    } catch (e) {
      log('Error comparing iOS versions: $e');
    }
  }
}

