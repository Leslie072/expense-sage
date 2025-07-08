import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:expense_sage/services/two_factor_service.dart';
import 'package:expense_sage/bloc/cubit/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _secret;
  String? _qrCodeData;
  List<String>? _backupCodes;
  bool _isLoading = false;
  bool _isSetupComplete = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _setup2FA();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _setup2FA() async {
    setState(() => _isLoading = true);
    
    try {
      final user = context.read<AuthCubit>().currentUser;
      if (user == null) return;

      final setupData = await TwoFactorService.setup2FA(user.email);
      
      setState(() {
        _secret = setupData['secret'];
        _qrCodeData = setupData['qrCodeData'];
        _backupCodes = setupData['backupCodes'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to setup 2FA: $e');
    }
  }

  Future<void> _verifyAndEnable() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final bool isValid = await TwoFactorService.verify2FACode(_codeController.text.trim());
      
      if (isValid) {
        await TwoFactorService.setTwoFactorEnabled(true);
        setState(() {
          _isSetupComplete = true;
          _currentStep = 2;
          _isLoading = false;
        });
        _showSuccess('Two-factor authentication enabled successfully!');
      } else {
        setState(() => _isLoading = false);
        _showError('Invalid verification code. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Verification failed: $e');
    }
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccess('Copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Two-Factor Authentication'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    backgroundColor: Colors.grey[300],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_currentStep == 0) _buildQRCodeStep(),
                  if (_currentStep == 1) _buildVerificationStep(),
                  if (_currentStep == 2) _buildBackupCodesStep(),
                ],
              ),
            ),
    );
  }

  Widget _buildQRCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Scan QR Code',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        const Text(
          '1. Install an authenticator app like Google Authenticator, Authy, or Microsoft Authenticator\n'
          '2. Scan the QR code below with your authenticator app\n'
          '3. If you can\'t scan, manually enter the secret key',
        ),
        
        const SizedBox(height: 24),
        
        if (_qrCodeData != null) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: QrImageView(
                data: _qrCodeData!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual Entry',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('If you can\'t scan the QR code, enter this secret manually:'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            TwoFactorService.formatSecretForDisplay(_secret ?? ''),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyToClipboard(_secret ?? ''),
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy secret',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentStep = 1);
            },
            child: const Text('Next: Verify Setup'),
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Verify Setup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Enter the 6-digit code from your authenticator app to verify the setup:',
          ),
          
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: const InputDecoration(
              labelText: 'Verification Code',
              hintText: '000000',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            maxLength: 6,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the verification code';
              }
              if (!TwoFactorService.isValidTOTPFormat(value)) {
                return 'Please enter a valid 6-digit code';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() => _currentStep = 0);
                  },
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAndEnable,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify & Enable'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCodesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Save Backup Codes',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Save these backup codes in a safe place. You can use them to access your account if you lose your authenticator device.',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        if (_backupCodes != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Backup Codes',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyToClipboard(_backupCodes!.join('\n')),
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy all codes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(_backupCodes!.map((code) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              code,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _copyToClipboard(code),
                            icon: const Icon(Icons.copy, size: 20),
                            tooltip: 'Copy code',
                          ),
                        ],
                      ),
                    ),
                  ))),
                ],
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Return true to indicate success
            },
            child: const Text('Complete Setup'),
          ),
        ),
      ],
    );
  }
}
