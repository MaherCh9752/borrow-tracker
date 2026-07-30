import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pending_invite_model.dart';
import '../providers/auth_provider.dart';
import '../services/invite_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _inviteService = InviteService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  PendingInvite? _verifiedInvite;
  bool _isVerifyingInvite = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyInviteCode() async {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isVerifyingInvite = true);

    try {
      final invite = await _inviteService.lookupByCode(code);
      if (!mounted) return;

      if (invite != null) {
        setState(() {
          _verifiedInvite = invite;
          _displayNameController.text = invite.targetPersonName;
        });
        _showSuccess('Invite code verified! Name filled in.');
      } else {
        setState(() => _verifiedInvite = null);
        _showError('Invalid or expired invite code.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _verifiedInvite = null);
        _showError('Failed to verify code. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isVerifyingInvite = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isLogin) {
      success = await authProvider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
        invite: _verifiedInvite,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && mounted) {
      // Navigation handled by main.dart authWrapper
    } else if (!success && mounted) {
      _showError(authProvider.error ?? 'An error occurred.');
    }
  }

  void _showError(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController();

    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email address',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, emailController.text.trim()),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    if (email != null && email.isNotEmpty && mounted) {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.resetPassword(email);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset email sent.'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          _showError(authProvider.error ?? 'Failed to send reset email.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Borrow Tracker',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Sign in to continue' : 'Create a new account',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!_isLogin)
                    TextFormField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: _verifiedInvite != null
                            ? IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                tooltip: 'Filled from invite code',
                                onPressed: null,
                              )
                            : null,
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name.';
                        }
                        return null;
                      },
                    ),
                  if (!_isLogin) const SizedBox(height: 16),
                  if (!_isLogin)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _inviteCodeController,
                            decoration: InputDecoration(
                              labelText: 'Invite Code (optional)',
                              hintText: 'e.g. ABC123',
                              prefixIcon: const Icon(Icons.vpn_key),
                              suffixIcon: _verifiedInvite != null
                                  ? const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20)
                                  : null,
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onChanged: (_) {
                              if (_verifiedInvite != null) {
                                setState(() => _verifiedInvite = null);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 56,
                          child: _isVerifyingInvite
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _verifiedInvite != null
                                      ? null
                                      : _verifyInviteCode,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                  child: const Text('Verify'),
                                ),
                        ),
                      ],
                    ),
                  if (!_isLogin) const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email.';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password.';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Sign In' : 'Sign Up',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLogin)
                    TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _formKey.currentState?.reset();
                            _verifiedInvite = null;
                            _inviteCodeController.clear();
                          });
                          context.read<AuthProvider>().clearError();
                        },
                        child: Text(_isLogin ? 'Sign Up' : 'Sign In'),
                      ),
                    ],
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
