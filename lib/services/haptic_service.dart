import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  Future<void> lightImpact() async {
    if (kIsWeb) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> mediumImpact() async {
    if (kIsWeb) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavyImpact() async {
    if (kIsWeb) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> selectionClick() async {
    if (kIsWeb) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> vibrate() async {
    if (kIsWeb) return;
    await HapticFeedback.vibrate();
  }
}



