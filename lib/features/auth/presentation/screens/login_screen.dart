import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paimana/core/config/app_config.dart';
import 'package:paimana/features/auth/domain/entities/auth_user.dart';
import 'package:paimana/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registering = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = ref.watch(authProvider);
    final user = session.asData?.value;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                  ),
                  const SizedBox(height: 17),
                  Text(
                    'Paimana',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A calmer way to run your tailoring shop.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (user != null) ...[
                    _ReturningUser(
                      user: user,
                      onContinue: () => context.go('/dashboard'),
                    ),
                    const SizedBox(height: 15),
                  ],
                  if (!AppConfig.hasApi) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          'Backend is not configured. You can continue offline; sign-in and cloud sync are unavailable.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(Icons.offline_bolt_outlined),
                      label: const Text('Continue offline'),
                    ),
                    const SizedBox(height: 12),
                    const _ApiSetupHint(),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _registering ? 'Create your account' : 'Welcome back',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_registering) ...[
                                TextFormField(
                                  controller: _nameController,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  decoration: const InputDecoration(
                                    labelText: 'Your name',
                                    prefixIcon: Icon(Icons.person_outline_rounded),
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().length < 2
                                      ? 'Enter your name'
                                      : null,
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                          .hasMatch(email)
                                      ? null
                                      : 'Enter a valid email address';
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: [
                                  _registering
                                      ? AutofillHints.newPassword
                                      : AutofillHints.password,
                                ],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Enter your password';
                                  }
                                  if (_registering && value.length < 10) {
                                    return 'Use at least 10 characters';
                                  }
                                  return null;
                                },
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(color: theme.colorScheme.error),
                                ),
                              ],
                              const SizedBox(height: 17),
                              FilledButton(
                                onPressed: _loading ? null : _submit,
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(_registering ? 'Create account' : 'Sign in'),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => setState(() {
                                        _registering = !_registering;
                                        _errorMessage = null;
                                      }),
                                child: Text(
                                  _registering
                                      ? 'Already have an account? Sign in'
                                      : 'New to Paimana? Create an account',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (session.hasError) ...[
                      const SizedBox(height: 10),
                      Text(
                        _errorText(session.error!),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 15),
                    const _ApiSetupHint(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      if (_registering) {
        await ref.read(authProvider.notifier).register(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await ref.read(authProvider.notifier).signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (mounted) context.go('/dashboard');
    } on DioException catch (error) {
      if (mounted) setState(() => _errorMessage = _errorText(error));
    } on FormatException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorText(Object error) {
    if (error is DioException) {
      final response = error.response?.data;
      if (response is Map<String, dynamic>) {
        final payload = response['error'];
        if (payload is Map<String, dynamic> && payload['message'] is String) {
          return payload['message'] as String;
        }
      }
      return error.message ?? 'Could not reach the Paimana server.';
    }
    return error.toString();
  }
}

class _ReturningUser extends StatelessWidget {
  const _ReturningUser({required this.user, required this.onContinue});

  final AuthUser user;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
        title: Text('Welcome back, ${user.name}'),
        subtitle: Text(user.email),
        trailing: IconButton(
          tooltip: 'Continue to your workspace',
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
        onTap: onContinue,
      ),
    );
  }
}

class _ApiSetupHint extends StatelessWidget {
  const _ApiSetupHint();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Connect to your Paimana server over a trusted HTTPS connection.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
