import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions no soporta esta plataforma',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBBvSyAOf_IRRSYnA942gXl8Rq-GPvmcOY',
    appId: '1:49698697522:web:bd66c680c1774c0553672b',
    messagingSenderId: '49698697522',
    projectId: 'terraconquest-d7a39',
    authDomain: 'terraconquest-d7a39.firebaseapp.com',
    storageBucket: 'terraconquest-d7a39.firebasestorage.app',
    measurementId: 'G-JS7Z2V9KLG',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyArZVpBF0TBRXh_JBXJWLLOSSmMStkleXg',
    appId: '1:49698697522:android:dc91f5e07ec8595253672b',
    messagingSenderId: '49698697522',
    projectId: 'terraconquest-d7a39',
    storageBucket: 'terraconquest-d7a39.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA6sHt_HFxnBBl_VHi5wcMA1RoVs4oKk0Q',
    appId: '1:49698697522:ios:b43b2b474818e76253672b',
    messagingSenderId: '49698697522',
    projectId: 'terraconquest-d7a39',
    storageBucket: 'terraconquest-d7a39.firebasestorage.app',
    iosBundleId: 'com.terrainvasion.app',
  );
}
