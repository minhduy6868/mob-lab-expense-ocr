import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final sheet = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surface;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.splash,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: LanguagePicker(compact: true),
                        ),
                        const VkuLogo(size: 72),
                        const SizedBox(height: 16),
                        Text(
                          'VKU ĐÀ NẴNG',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.gold,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'VKU Ledger',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: AppColors.paper,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text.appSubtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.paper.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: sheet,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        children: [
                          TextField(
                            controller: _username,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: const [AutofillHints.username],
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
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => _busy ? null : _submit(),
                            decoration: InputDecoration(
                              labelText: text.password,
                              prefixIcon: const Icon(Icons.lock_rounded),
                              suffixIcon: IconButton(
                                tooltip: _obscure ? text.showPassword : text.hidePassword,
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            text.loginHint,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: theme.colorScheme.onErrorContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy ? null : _submit,
                            child: _busy
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.onPrimary,
                                    ),
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
                            child: Text(_register ? text.haveAccount : text.needAccount),
                          ),
                        ],
                      ),
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
