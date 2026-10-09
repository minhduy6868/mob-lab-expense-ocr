import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../l10n/app_text.dart';
import '../state/auth_controller.dart';
import '../widgets/language_picker.dart';
import '../widgets/vku_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = AppText.of(context);
    final username = _username.text.trim().toLowerCase();
    final password = _password.text;
    if (!RegExp(r'^[a-z0-9_]{3,24}$').hasMatch(username)) {
      setState(() => _error = text.usernameInvalid);
      return;
    }
    if (password.length < 6) {
      setState(() => _error = text.passwordShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final code = await ref.read(authProvider.notifier).signIn(
          username: username,
          password: password,
          register: _register,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = code == null ? null : AppText.of(context).authError(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = AppText.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(alignment: Alignment.centerRight, child: LanguagePicker()),
                  const SizedBox(height: 24),
                  const Center(child: VkuLogo(size: 96)),
                  const SizedBox(height: 16),
                  Text(
                    'VKU Ledger',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text.appSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: SizedBox(
                      width: 48,
                      height: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: text.username,
                      prefixIcon: const Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _busy ? null : _submit(),
                    decoration: InputDecoration(
                      labelText: text.password,
                      prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? text.showPassword : text.hidePassword,
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text.loginHint,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_register ? text.createAccount : text.logIn),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _register = !_register;
                              _error = null;
                            }),
                    child: Text(_register ? text.haveAccount : '${text.needAccount} ${text.createAccount}'),
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
