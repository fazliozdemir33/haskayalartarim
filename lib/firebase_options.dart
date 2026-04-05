import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the flutterfire cli.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the flutterfire cli.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          "DefaultFirebaseOptions haven't been configured for windows - "
          "you can reconfigure this by running the flutterfire cli.",
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the flutterfire cli.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBRwyvE1EEfVT1PLOYOg49OWv5G8gsrzNE',
    appId: '1:1012873371896:android:dedf958dd2a066db9f9b0d',
    messagingSenderId: '1012873371896',
    projectId: 'makale-aab64',
    storageBucket: 'makale-aab64.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgkeWQ9Mzuc-j0rhAtRe03Ch4ZPiOA5bQ',
    appId: '1:1012873371896:ios:dfeaf87c8ebbab1d9f9b0d',
    messagingSenderId: '1012873371896',
    projectId: 'makale-aab64',
    storageBucket: 'makale-aab64.firebasestorage.app',
    iosBundleId: 'com.detasoft.makale',
  );
}
