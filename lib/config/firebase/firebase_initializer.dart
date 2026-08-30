import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseInitializer {
  static Future<FirebaseApp> initialize() {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
