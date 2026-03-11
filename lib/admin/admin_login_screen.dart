import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gajanan_maharaj_sevekari/admin/admin_session_service.dart';
import 'package:gajanan_maharaj_sevekari/l10n/app_localizations.dart';
import 'package:gajanan_maharaj_sevekari/utils/routes.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kIsWeb) {
        setState(() {
          _errorMessage = localizations.googleSignInWebNotSupported;
          _isLoading = false;
        });
        return;
      }

      // Trigger the authentication flow (google_sign_in v7 API)
      final googleUser = await GoogleSignIn.instance.authenticate();

      // idToken is available directly on account.authentication in v7
      final googleAuth = googleUser.authentication;

      // Create a Firebase credential using the idToken
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null && user.email != null) {
        // Check if the user's email is in the allowlist
        final DocumentSnapshot allowlistDoc = await _firestore
            .collection('admin_allowlist')
            .doc(user.email)
            .get();

        if (allowlistDoc.exists) {
          // Access granted - Log the login event
          await _logLoginEvent(user.email!);

          if (!mounted) return;
          AdminSessionService.startSession();
          Navigator.pushReplacementNamed(context, Routes.adminDashboard);
        } else {
          // Access denied - email not in allowlist
          await _auth.signOut();
          await GoogleSignIn.instance.signOut();
          setState(() {
            _errorMessage = localizations.accessDeniedNotAuthorized;
          });
        }
      } else {
        setState(() {
          _errorMessage = localizations.errorRetrieveEmail;
        });
      }
    } on GoogleSignInException catch (e) {
      // User cancelled or sign-in was interrupted — don't show an error
      if (e.code != GoogleSignInExceptionCode.canceled &&
          e.code != GoogleSignInExceptionCode.interrupted) {
        debugPrint('Error signing in with Google: $e');
        setState(() {
          _errorMessage = localizations.signInError;
        });
      }
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      setState(() {
        _errorMessage = localizations.signInError;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logLoginEvent(String email) async {
    try {
      debugPrint('Attempting to log LOGIN event for $email...');
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 30)); // 1 month TTL

      await _firestore.collection('admin_audit_logs').add({
        'admin_email': email,
        'action': 'LOGIN',
        'timestamp': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      });
      debugPrint('SUCCESS: Audit log written to Firestore.');
    } catch (e) {
      debugPrint('Failed to write audit log: $e');
      // We don't block login if audit log fails, but it's noted.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.adminAccess),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.home,
              (route) => false,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: theme.cardTheme.elevation ?? 4,
            color: theme.cardTheme.color,
            shape:
                theme.cardTheme.shape ??
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations.adminRestrictedArea,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.adminSignInInstruction,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 48),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton.icon(
                      onPressed: _signInWithGoogle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.login),
                      label: Text(
                        'Sign in with Google',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      localizations.cancel,
                      style: TextStyle(color: theme.colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
