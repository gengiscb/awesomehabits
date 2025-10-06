import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:awesomehabits/firebase_options.dart';

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // Ensure Firebase is initialized (especially important on Web hot restarts)
  Future<void> _ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInAnonymously() async {
    try {
      await _ensureInitialized();
      return await _auth.signInAnonymously();
    } catch (e) {
      throw Exception('Failed to sign in anonymously: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }
}