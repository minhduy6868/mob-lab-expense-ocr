import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloudflare_d1_client.dart';
import '../services/database_helper.dart';
import 'auth_gate.dart';
import 'expense_providers.dart';

class AuthState {
  final AuthStatus status;
  final String username;

  const AuthState(this.status, {this.username = ''});

  bool get signedIn => status == AuthStatus.signedIn;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  static const _tokenKey = 'vku_auth_token';
  static const _userKey = 'vku_auth_user_id';
  static const _nameKey = 'vku_auth_username';

  final DatabaseHelper _db = DatabaseHelper.instance;

  @override
  AuthState build() {
    Future.microtask(restore);
    return const AuthState(AuthStatus.unknown);
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final username = prefs.getString(_nameKey) ?? '';
    if (token == null || token.isEmpty) {
      _publish(const AuthState(AuthStatus.signedOut));
      return;
    }
    _db.setAccessToken(token);
    try {
      final session = await _db.currentAccount();
      await prefs.setString(_nameKey, session.username);
      _publish(AuthState(AuthStatus.signedIn, username: session.username));
    } on CloudflareD1Exception catch (error) {
      if (error.unauthorized) {
        await _clearSession(prefs);
        _publish(const AuthState(AuthStatus.signedOut));
        return;
      }
      _publish(AuthState(AuthStatus.signedIn, username: username));
    } catch (_) {
      _publish(AuthState(AuthStatus.signedIn, username: username));
    }
  }

  Future<String?> signIn({
    required String username,
    required String password,
    required bool register,
  }) async {
    try {
      final session = register
          ? await _db.registerAccount(username.trim().toLowerCase(), password)
          : await _db.loginAccount(username.trim().toLowerCase(), password);
      await _store(session);
      _publish(AuthState(AuthStatus.signedIn, username: session.username));
      ref.invalidate(expenseListProvider);
      return null;
    } on CloudflareD1Exception catch (error) {
      return error.message;
    } catch (_) {
      return 'auth_failed';
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await _db.logoutAccount();
    await _db.wipeLocalLedger();
    _db.setAccessToken(null);
    await _clearSession(prefs);
    ref.invalidate(expenseListProvider);
    _publish(const AuthState(AuthStatus.signedOut));
  }

  Future<void> _store(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final previous = prefs.getString(_userKey);
    if (previous != null && previous != session.userId) {
      await _db.wipeLocalLedger();
    }
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_userKey, session.userId);
    await prefs.setString(_nameKey, session.username);
    _db.setAccessToken(session.token);
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_nameKey);
  }

  void _publish(AuthState next) {
    state = next;
    authGate.update(
      status: next.status,
      username: next.username,
    );
  }
}
