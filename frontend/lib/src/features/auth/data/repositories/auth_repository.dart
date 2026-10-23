import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/logger_utils.dart';

/// Repository responsible for authentication logic using Firebase Phone Auth.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;

  /// Sends an OTP to the provided phone number.
  Future<String?> sendOtp(String phoneNumber, {String? fullName}) async {
    final completer = Completer<String?>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          final raw = e as dynamic;
          Log.e('AuthRepository',
              '━━━━━━━━━━ FirebaseAuth FULL ERROR ━━━━━━━━━━');
          Log.e('AuthRepository', 'Code    : ${e.code}');
          Log.e('AuthRepository', 'Message : ${e.message}');
          Log.e('AuthRepository', 'Plugin  : ${e.plugin}');
          try {
            Log.e('AuthRepository', 'Details : ${raw.details}');
          } catch (_) {}
          Log.e('AuthRepository', 'FullObj : $e');
          Log.e(
              'AuthRepository', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          completer.complete(e.message ?? 'Unknown error occurred');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          completer.complete(null); // null means success
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      Log.e('AuthRepository', 'OTP Send Error: $e');
      return e.toString();
    }

    return completer.future;
  }

  /// Verifies the OTP provided by the user.
  /// Returns `null` on success, or a human-readable error string on failure.
  Future<String?> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    if (_verificationId == null) {
      return 'Verification session missing. Please request a new OTP.';
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      Log.e(
          'AuthRepository', '━━━━━━━ verifyOtp FirebaseAuthException ━━━━━━━');
      Log.e('AuthRepository', 'Code    : ${e.code}');
      Log.e('AuthRepository', 'Message : ${e.message}');
      Log.e('AuthRepository', '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      switch (e.code) {
        case 'invalid-verification-code':
          return 'The code you entered is incorrect.';
        case 'session-expired':
        case 'invalid-verification-id':
          return 'OTP session expired. Please request a new code.';
        case 'missing-client-identifier':
          return 'App is not configured for phone auth (missing SHA-1 in Firebase).';
        case 'network-request-failed':
          return 'Network error. Check your connection and try again.';
        case 'too-many-requests':
        case 'quota-exceeded':
          return 'Too many attempts. Try again later.';
        default:
          return e.message ?? 'Verification failed (${e.code}).';
      }
    } catch (e) {
      Log.e('AuthRepository', 'verifyOtp unexpected error: $e');
      return 'Verification failed: $e';
    }
  }

  /// Resends the OTP to the provided phone number.
  Future<String?> resendOtp(String phoneNumber) async {
    return sendOtp(phoneNumber);
  }
}
