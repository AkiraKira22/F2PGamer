import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Thrown by [AuthService] for any auth failure, carrying a message that is
/// safe (and friendly) to show directly to the user.
class AuthException implements Exception {
  const AuthException(this.message, {this.cancelled = false});

  final String message;

  /// True when the user simply dismissed the Google sign-in sheet. The UI can
  /// use this to stay silent instead of showing an error.
  final bool cancelled;

  @override
  String toString() => message;
}

/// Single entry point for all authentication, wrapping [FirebaseAuth] and the
/// Google Sign-In v7 API. Use [AuthService.instance].
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _googleReady = false;

  /// OPTIONAL. On Android the Google "Web client" OAuth ID is normally picked
  /// up automatically from `google-services.json`. If [signInWithGoogle] ever
  /// fails because the ID token is null, paste that Web client ID here.
  /// Firebase Console → Authentication → Sign-in method → Google → Web SDK
  /// configuration → "Web client ID".
  static const String? _googleServerClientId = null;

  /// Emits the current user (or null when signed out). Drives the root UI.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // Email / password
  // ---------------------------------------------------------------------------

  Future<User> signInWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<User> registerWithEmail(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------------

  Future<User> signInWithGoogle() async {
    try {
      // Web uses Firebase's popup flow directly; google_sign_in's
      // authenticate() is not supported there.
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final cred = await _auth.signInWithPopup(provider);
        return cred.user!;
      }

      await _ensureGoogleInitialized();

      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication auth = account.authentication;

      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AuthException(
          'Google sign-in did not return an ID token. Make sure Google is '
          'enabled in the Firebase console and (on Android) your SHA-1 key is '
          'registered. See FIREBASE_SETUP.md.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);
      return cred.user!;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Sign-in cancelled.', cancelled: true);
      }
      throw AuthException('Google sign-in failed: ${e.description ?? e.code}');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleReady) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId,
    );
    _googleReady = true;
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    if (!kIsWeb) {
      // Clear the Google session too, so the next sign-in shows the account
      // picker again. Safe to ignore if Google was never initialized.
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found for that email. Try creating one.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Try signing in.';
      case 'weak-password':
        return 'Password is too weak (use at least 6 characters).';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but a different '
            'sign-in method.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return e.message ?? 'Authentication failed (${e.code}).';
    }
  }
}
