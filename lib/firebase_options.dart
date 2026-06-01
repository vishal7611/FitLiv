import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated manually to bypass CLI issues using your google-services.json values.
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
    apiKey: 'AIzaSyBbCBZ8Rf6dcY5SD5uK_h1PttgyWWwJLlo',
    appId: '1:143009365371:web:placeholder', // Web not registered yet, but this prevents errors
    messagingSenderId: '143009365371',
    projectId: 'fit-posture-app',
    authDomain: 'fit-posture-app.firebaseapp.com',
    storageBucket: 'fit-posture-app.firebasestorage.app',
  );

  // --- YOUR REAL ANDROID CONFIGURATION ---
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBbCBZ8Rf6dcY5SD5uK_h1PttgyWWwJLlo',
    appId: '1:143009365371:android:289bb1f53ca5587d0d91de',
    messagingSenderId: '143009365371',
    projectId: 'fit-posture-app',
    storageBucket: 'fit-posture-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBbCBZ8Rf6dcY5SD5uK_h1PttgyWWwJLlo',
    appId: '1:143009365371:ios:placeholder', // iOS not registered yet
    messagingSenderId: '143009365371',
    projectId: 'fit-posture-app',
    storageBucket: 'fit-posture-app.firebasestorage.app',
    iosBundleId: 'com.example.fit_posture_app',
  );
}