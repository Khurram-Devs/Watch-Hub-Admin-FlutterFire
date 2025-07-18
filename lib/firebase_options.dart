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
    apiKey: 'AIzaSyBpueeeKUiLH7g35eRw1ccjhFOKj_LJW-E',
    appId: '1:59661554320:web:664b6b323e20cb415a3e15',
    messagingSenderId: '59661554320',
    projectId: 'watch-hub-9529d',
    authDomain: 'watch-hub-9529d.firebaseapp.com',
    storageBucket: 'watch-hub-9529d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAd43Wq3VvkRLhJ7p_P4JyBAN1HoX9HYSU',
    appId: '1:59661554320:android:853957cebee7aab75a3e15',
    messagingSenderId: '59661554320',
    projectId: 'watch-hub-9529d',
    storageBucket: 'watch-hub-9529d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD9BL4aaOhpayMoIyuTFvpuCfzl8iUEksU',
    appId: '1:59661554320:ios:2d841bcc446fc4175a3e15',
    messagingSenderId: '59661554320',
    projectId: 'watch-hub-9529d',
    storageBucket: 'watch-hub-9529d.firebasestorage.app',
    iosBundleId: 'com.example.watchHubEp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD9BL4aaOhpayMoIyuTFvpuCfzl8iUEksU',
    appId: '1:59661554320:ios:2d841bcc446fc4175a3e15',
    messagingSenderId: '59661554320',
    projectId: 'watch-hub-9529d',
    storageBucket: 'watch-hub-9529d.firebasestorage.app',
    iosBundleId: 'com.example.watchHubEp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBpueeeKUiLH7g35eRw1ccjhFOKj_LJW-E',
    appId: '1:59661554320:web:a31168a3eeaba1535a3e15',
    messagingSenderId: '59661554320',
    projectId: 'watch-hub-9529d',
    authDomain: 'watch-hub-9529d.firebaseapp.com',
    storageBucket: 'watch-hub-9529d.firebasestorage.app',
  );
}
