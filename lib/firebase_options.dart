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
    apiKey: 'AIzaSyAgln3O4xvqPKOrfw-C51xxxUlCeK3qhTY',
    appId: '1:297023252109:web:3e442a83099c21530664c4',
    messagingSenderId: '297023252109',
    projectId: 'hutechevent',
    authDomain: 'hutechevent.firebaseapp.com',
    storageBucket: 'hutechevent.firebasestorage.app',
    measurementId: 'G-NW1WD7VWVC',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCygps46OmTEBF-tnscFfDzWPLIJKQ3IqQ',
    appId: '1:297023252109:android:92ceb46b48ad40cd0664c4',
    messagingSenderId: '297023252109',
    projectId: 'hutechevent',
    storageBucket: 'hutechevent.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC-tL9y1ywPJ4GazQLpxsW_N0ZgzrJoH_A',
    appId: '1:297023252109:ios:715246fd6a0444dc0664c4',
    messagingSenderId: '297023252109',
    projectId: 'hutechevent',
    storageBucket: 'hutechevent.firebasestorage.app',
    iosBundleId: 'com.example.hutechEventFlutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC-tL9y1ywPJ4GazQLpxsW_N0ZgzrJoH_A',
    appId: '1:297023252109:ios:715246fd6a0444dc0664c4',
    messagingSenderId: '297023252109',
    projectId: 'hutechevent',
    storageBucket: 'hutechevent.firebasestorage.app',
    iosBundleId: 'com.example.hutechEventFlutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAgln3O4xvqPKOrfw-C51xxxUlCeK3qhTY',
    appId: '1:297023252109:web:d319bf35a7c717d90664c4',
    messagingSenderId: '297023252109',
    projectId: 'hutechevent',
    authDomain: 'hutechevent.firebaseapp.com',
    storageBucket: 'hutechevent.firebasestorage.app',
    measurementId: 'G-G4K4VMWT3F',
  );

}