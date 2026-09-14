import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/application/tulkhuur_controller.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../shared/widgets/app_state_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _signUpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.account)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BackendNotice(configured: backend.isConfigured),
          const SizedBox(height: 20),
          if (backend.currentUser != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      AppStrings.currentAccount,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(backend.currentUser?.email ?? AppStrings.account),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _signOut,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(AppStrings.signOut),
                    ),
                  ],
                ),
              ),
            )
          else
            Form(
              key: _formKey,
              child: Column(
                children: [
                  if (_signUpMode) ...[
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.fullName,
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (value) =>
                          (value?.trim().isEmpty ?? true)
                          ? AppStrings.requiredField
                          : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: AppStrings.email,
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) =>
                        value != null && RegExp(r'^.+@.+\..+$').hasMatch(value)
                        ? null
                        : AppStrings.invalidEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.length ?? 0) < 6
                        ? AppStrings.passwordLength
                        : null,
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: !backend.isConfigured || _loading
                        ? null
                        : (_signUpMode ? _signUp : _signIn),
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _signUpMode
                                ? Icons.person_add_alt_1_rounded
                                : Icons.login_rounded,
                          ),
                    label: Text(
                      _signUpMode ? AppStrings.signUp : AppStrings.signIn,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() => _signUpMode = !_signUpMode),
                    child: Text(
                      _signUpMode
                          ? AppStrings.haveAccount
                          : AppStrings.noAccount,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref
          .read(backendServiceProvider)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(AppStrings.signInSuccess)));
      _syncAfterAuth();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(AppStrings.signInFailed)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final signedIn = await ref
          .read(backendServiceProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            signedIn
                ? AppStrings.signUpSuccess
                : AppStrings.signUpConfirmEmail,
          ),
        ),
      );
      _syncAfterAuth();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.signUpFailed)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Нэвтэрсний дараа локал өгөгдлийг сервертэй тааруулна.
  void _syncAfterAuth() {
    final sync = ref.read(syncServiceProvider);
    if (!sync.canSync) return;
    sync.sync().then((outcome) {
      if (!mounted) return;
      ref.read(syncStatusProvider.notifier).report(outcome);
      ref.invalidate(tulkhuurControllerProvider);
    });
  }

  Future<void> _signOut() async {
    setState(() => _loading = true);
    await ref.read(backendServiceProvider).signOut();
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text(AppStrings.signOutSuccess)));
  }
}
