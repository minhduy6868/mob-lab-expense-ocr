import 'package:flutter/foundation.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthGate extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  String username = '';

  void update({required AuthStatus status, String username = ''}) {
    this.status = status;
    this.username = username;
    notifyListeners();
  }
}

final authGate = AuthGate();
