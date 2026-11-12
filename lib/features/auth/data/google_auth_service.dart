import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around the `google_sign_in` plugin (v7 API). Deliberately
/// untested glue — like `deep_link_listener.dart`'s `app_links` wiring —
/// since it talks to a real native SDK; `AuthApi.loginWithGoogle` and
/// `AuthNotifier.loginWithGoogle` carry the actual testable logic.
abstract class GoogleAuthService {
  /// Returns a Google ID token for [serverClientId] (the **web** client id
  /// from `/settings/public.google_client_id`, API.md §2), or null if the
  /// user cancelled.
  Future<String?> signIn({required String serverClientId});
}

class GoogleAuthServiceImpl implements GoogleAuthService {
  String? _initializedFor;

  @override
  Future<String?> signIn({required String serverClientId}) async {
    if (_initializedFor != serverClientId) {
      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
      _initializedFor = serverClientId;
    }
    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken;
  }
}
