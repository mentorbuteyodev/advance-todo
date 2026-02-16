// File generated manually from google-services.json
// Firebase project: advance-todo-77cf3

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not configured for this project.');
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9eUh8djLbYPlVM5bc-KYQwG7BW42x088',
    appId: '1:162877261450:android:df812792717daa64434f73',
    messagingSenderId: '162877261450',
    projectId: 'advance-todo-77cf3',
    storageBucket: 'advance-todo-77cf3.firebasestorage.app',
  );

  // iOS config — add when you register an iOS app in Firebase Console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TODO-ADD-IOS-API-KEY',
    appId: 'TODO-ADD-IOS-APP-ID',
    messagingSenderId: '162877261450',
    projectId: 'advance-todo-77cf3',
    storageBucket: 'advance-todo-77cf3.firebasestorage.app',
    iosBundleId: 'com.example.todoTest',
  );
}
