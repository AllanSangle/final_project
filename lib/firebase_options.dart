// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDS5vyVj3jtgpSHlnElsEbGhNmkJtX50sI',
    appId: '1:1052955846721:web:c6c22fa2a7e864dbdafec0',
    messagingSenderId: '1052955846721',
    projectId: 'final-proj-mobile-devices',
    authDomain: 'final-proj-mobile-devices.firebaseapp.com',
    storageBucket: 'final-proj-mobile-devices.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCGt48GWvBywQocIhcI2CHLDYcVfFy2_3U',
    appId: '1:1052955846721:android:984b099533671eeddafec0',
    messagingSenderId: '1052955846721',
    projectId: 'final-proj-mobile-devices',
    storageBucket: 'final-proj-mobile-devices.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAqXWpfBfzfTq-wmZ1gg_zukgQa5-QHQBE',
    appId: '1:1052955846721:ios:04d557e382033a0ddafec0',
    messagingSenderId: '1052955846721',
    projectId: 'final-proj-mobile-devices',
    storageBucket: 'final-proj-mobile-devices.firebasestorage.app',
    iosBundleId: 'com.example.finalProject',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAqXWpfBfzfTq-wmZ1gg_zukgQa5-QHQBE',
    appId: '1:1052955846721:ios:04d557e382033a0ddafec0',
    messagingSenderId: '1052955846721',
    projectId: 'final-proj-mobile-devices',
    storageBucket: 'final-proj-mobile-devices.firebasestorage.app',
    iosBundleId: 'com.example.finalProject',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDS5vyVj3jtgpSHlnElsEbGhNmkJtX50sI',
    appId: '1:1052955846721:web:d67161e44d6fe2d3dafec0',
    messagingSenderId: '1052955846721',
    projectId: 'final-proj-mobile-devices',
    authDomain: 'final-proj-mobile-devices.firebaseapp.com',
    storageBucket: 'final-proj-mobile-devices.firebasestorage.app',
  );
}
