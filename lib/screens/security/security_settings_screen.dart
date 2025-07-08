import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_sage/bloc/cubit/auth_cubit.dart';
import 'package:expense_sage/services/two_factor_service.dart';
import 'package:expense_sage/screens/security/two_factor_setup_screen.dart';
import 'package:expense_sage/widgets/dialog/confirm.modal.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _is2FAEnabled = false;
  String _biometricDescription = '';
  int _remainingBackupCodes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() => _isLoading = true);
    
    try {
      final authCubit = context.read<AuthCubit>();
      
      final biometricAvailable = await authCubit.isBiometricAvailable();
      final biometricEnabled = await authCubit.isBiometricEnabled();
      final biometricDesc = await authCubit.getBiometricDescription();
      final twoFactorEnabled = await TwoFactorService.isTwoFactorEnabled();
      final backupCodesCount = await TwoFactorService.getRemainingBackupCodesCount();
      
      setState(() {
        _isBiometricAvailable = biometricAvailable;
        _isBiometricEnabled = biometricEnabled;
        _biometricDescription = biometricDesc;
        _is2FAEnabled = twoFactorEnabled;
        _remainingBackupCodes = backupCodesCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load security settings: $e');
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    final authCubit = context.read<AuthCubit>();
    
    final success = await authCubit.setBiometricEnabled(enabled);
    
    if (success) {
      setState(() => _isBiometricEnabled = enabled);
      _showSuccess(enabled 
          ? 'Biometric authentication enabled' 
          : 'Biometric authentication disabled');
    } else {
      _showError(enabled 
          ? 'Failed to enable biometric authentication' 
          : 'Failed to disable biometric authentication');
    }
  }

  Future<void> _setup2FA() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const TwoFactorSetupScreen(),
      ),
    );
    
    if (result == true) {
      _loadSecuritySettings(); // Refresh settings
    }
  }

  Future<void> _disable2FA() async {
    ConfirmModal.showConfirmDialog(
      context,
      title: "Disable Two-Factor Authentication?",
      content: const Text(
        "This will make your account less secure. Are you sure you want to disable two-factor authentication?",
      ),
      onConfirm: () async {
        Navigator.of(context).pop();
        
        // Require authentication before disabling
        final authCubit = context.read<AuthCubit>();
        final authenticated = await authCubit.authenticateForSensitiveOperation(
          reason: 'Please authenticate to disable two-factor authentication',
        );
        
        if (authenticated) {
          await TwoFactorService.disable2FA();
          _loadSecuritySettings();
          _showSuccess('Two-factor authentication disabled');
        } else {
          _showError('Authentication required to disable 2FA');
        }
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  Future<void> _regenerateBackupCodes() async {
    ConfirmModal.showConfirmDialog(
      context,
      title: "Regenerate Backup Codes?",
      content: const Text(
        "This will invalidate all existing backup codes and generate new ones. Make sure to save the new codes.",
      ),
      onConfirm: () async {
        Navigator.of(context).pop();
        
        try {
          final newCodes = await TwoFactorService.regenerateBackupCodes();
          _loadSecuritySettings();
          
          // Show new backup codes
          _showBackupCodes(newCodes);
        } catch (e) {
          _showError('Failed to regenerate backup codes: $e');
        }
      },
      onCancel: () => Navigator.of(context).pop(),
    );
  }

  void _showBackupCodes(List<String> codes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Backup Codes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Save these backup codes in a safe place:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              ...codes.map((code) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                  ),
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Biometric Authentication Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fingerprint, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Biometric Authentication',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isBiometricAvailable
                              ? 'Use $_biometricDescription to unlock the app'
                              : 'Biometric authentication is not available on this device',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Enable Biometric Login'),
                          subtitle: Text(_isBiometricEnabled 
                              ? 'Biometric authentication is enabled' 
                              : 'Biometric authentication is disabled'),
                          value: _isBiometricEnabled,
                          onChanged: _isBiometricAvailable 
                              ? (value) => _toggleBiometric(value)
                              : null,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Two-Factor Authentication Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Two-Factor Authentication',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add an extra layer of security to your account with time-based codes from an authenticator app',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_is2FAEnabled) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 12),
                                Text(
                                  'Two-factor authentication is enabled',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          ListTile(
                            leading: const Icon(Icons.backup),
                            title: const Text('Backup Codes'),
                            subtitle: Text('$_remainingBackupCodes codes remaining'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: _regenerateBackupCodes,
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _disable2FA,
                              icon: const Icon(Icons.security_outlined),
                              label: const Text('Disable 2FA'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _setup2FA,
                              icon: const Icon(Icons.security),
                              label: const Text('Setup Two-Factor Authentication'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Security Tips
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tips_and_updates, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Security Tips',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('• Use a strong, unique password for your account'),
                        const SizedBox(height: 4),
                        const Text('• Enable both biometric and two-factor authentication'),
                        const SizedBox(height: 4),
                        const Text('• Keep your backup codes in a safe place'),
                        const SizedBox(height: 4),
                        const Text('• Don\'t share your authentication codes with anyone'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
