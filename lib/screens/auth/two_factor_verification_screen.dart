import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_sage/bloc/cubit/auth_cubit.dart';
import 'package:expense_sage/services/two_factor_service.dart';

class TwoFactorVerificationScreen extends StatefulWidget {
  const TwoFactorVerificationScreen({super.key});

  @override
  State<TwoFactorVerificationScreen> createState() =>
      _TwoFactorVerificationScreenState();
}

class _TwoFactorVerificationScreenState
    extends State<TwoFactorVerificationScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _useBackupCode = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String? _validateCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the verification code';
    }

    if (_useBackupCode) {
      if (!TwoFactorService.isValidBackupCodeFormat(value)) {
        return 'Please enter a valid backup code (8 digits)';
      }
    } else {
      if (!TwoFactorService.isValidTOTPFormat(value)) {
        return 'Please enter a valid 6-digit code';
      }
    }

    return null;
  }

  void _handleVerification() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().verify2FACode(_codeController.text.trim());
    }
  }

  void _toggleBackupCode() {
    setState(() {
      _useBackupCode = !_useBackupCode;
      _codeController.clear();
    });
  }

  void _handleBackToLogin() {
    context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackToLogin,
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }

          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.security,
                          size: 80,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Verification Required',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _useBackupCode
                              ? 'Enter one of your backup codes to continue'
                              : 'Enter the 6-digit code from your authenticator app',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Code Input Field
                  TextFormField(
                    controller: _codeController,
                    keyboardType: _useBackupCode
                        ? TextInputType.text
                        : TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: _useBackupCode ? 18 : 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: _useBackupCode ? 2 : 8,
                      fontFamily: _useBackupCode ? null : 'monospace',
                    ),
                    decoration: InputDecoration(
                      labelText:
                          _useBackupCode ? 'Backup Code' : 'Verification Code',
                      hintText: _useBackupCode ? '1234-5678' : '000000',
                      border: const OutlineInputBorder(),
                      counterText: '',
                      prefixIcon:
                          Icon(_useBackupCode ? Icons.backup : Icons.security),
                    ),
                    maxLength: _useBackupCode
                        ? 9
                        : 6, // 8 digits + 1 dash for backup codes
                    validator: _validateCode,
                    onFieldSubmitted: (_) => _handleVerification(),
                  ),

                  const SizedBox(height: 24),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleVerification,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Toggle between TOTP and backup code
                  Center(
                    child: TextButton(
                      onPressed: _toggleBackupCode,
                      child: Text(
                        _useBackupCode
                            ? 'Use authenticator app instead'
                            : 'Use backup code instead',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Help text
                  if (!_useBackupCode) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Need help?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• Open your authenticator app (Google Authenticator, Authy, etc.)\n'
                            '• Find the Expense Sage entry\n'
                            '• Enter the 6-digit code shown\n'
                            '• If you lost your device, use a backup code instead',
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Each backup code can only be used once. Make sure to save your remaining codes.',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Back to login
                  Center(
                    child: TextButton(
                      onPressed: _handleBackToLogin,
                      child: const Text('Back to Login'),
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
