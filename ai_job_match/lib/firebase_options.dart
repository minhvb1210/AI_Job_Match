// File: lib/firebase_options.dart
// Real Firebase configuration for AI Job Match project.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDkETLLFLFYopb38VcaGIBziCBCBCAX4gA',
    appId: '1:862611767434:web:3c64942a6765d5571e6d73',
    messagingSenderId: '862611767434',
    projectId: 'ai-jobmatch-48c9c',
    authDomain: 'ai-jobmatch-48c9c.firebaseapp.com',
    storageBucket: 'ai-jobmatch-48c9c.firebasestorage.app',
    measurementId: 'G-GFLL1RTP9G',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDkETLLFLFYopb38VcaGIBziCBCBCAX4gA',
    appId: '1:862611767434:web:3c64942a6765d5571e6d73',
    messagingSenderId: '862611767434',
    projectId: 'ai-jobmatch-48c9c',
    storageBucket: 'ai-jobmatch-48c9c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDkETLLFLFYopb38VcaGIBziCBCBCAX4gA',
    appId: '1:862611767434:web:3c64942a6765d5571e6d73',
    messagingSenderId: '862611767434',
    projectId: 'ai-jobmatch-48c9c',
    storageBucket: 'ai-jobmatch-48c9c.firebasestorage.app',
    iosBundleId: 'com.example.aiJobMatch',
  );
}
