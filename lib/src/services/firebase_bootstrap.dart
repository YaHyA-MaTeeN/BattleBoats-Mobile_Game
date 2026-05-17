import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  static bool _ready = false;
  static String? _error;

  static bool get isReady => _ready;
  static String? get error => _error;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _ready = true;
      _error = null;
    } on FirebaseException catch (e) {
      _ready = false;
      _error =
          'Firebase setup is incomplete (${e.code}). Configure Firebase for this app first.';
    } catch (e) {
      _ready = false;
      _error = 'Firebase setup failed: $e';
    }

    if (!_ready) {
      debugPrint(_error);
    }
  }
}
