import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;


class GoogleAuthService extends ChangeNotifier {
  GoogleSignInAccount? _currentUser;
  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope,
    ],
  );

  GoogleSignInAccount? get currentUser => _currentUser;

  GoogleAuthService() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      notifyListeners();
    });
    _googleSignIn.signInSilently();
  }

  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print('Error signing in: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (error) {
      print('Error signing out: $error');
    }
  }

  Future<auth.AuthClient?> get authenticatedClient async {
    if (_currentUser == null) return null;
    return _googleSignIn.authenticatedClient();
  }
}

extension GoogleSignInExtensions on GoogleSignIn {
  Future<auth.AuthClient?> authenticatedClient() async {
    final GoogleSignInAccount? googleUser = await this.signInSilently();
    if (googleUser == null) {
      return null;
    }
    final auth.AccessCredentials? credentials = (await googleUser.authentication)?.toAccessCredentials();
    if (credentials == null) {
      return null;
    }
    return auth.authenticatedClient(
        http.Client(),
        credentials,
        closeUnderlyingClient: true
    );
  }
}

extension on GoogleSignInAuthentication {
  auth.AccessCredentials toAccessCredentials() {
    return auth.AccessCredentials(
      auth.AccessToken(
        'Bearer',
        accessToken!,
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
      refreshToken,
      scopes,
    );
  }
}