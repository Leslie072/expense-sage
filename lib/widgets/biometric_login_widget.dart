import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BiometricLoginWidget extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const BiometricLoginWidget({
    super.key,
    this.onSuccess,
    this.onError,
  });

  @override
  State<BiometricLoginWidget> createState() => _BiometricLoginWidgetState();
}

class _BiometricLoginWidgetState extends State<BiometricLoginWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
    });

    try {
      // Simulate biometric authentication
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, you would use local_auth package
      // final LocalAuthentication auth = LocalAuthentication();
      // final bool didAuthenticate = await auth.authenticate(
      //   localizedReason: 'Please authenticate to access your account',
      //   options: const AuthenticationOptions(
      //     biometricOnly: true,
      //   ),
      // );

      // For demo purposes, we'll simulate success
      final bool didAuthenticate = true;

      if (didAuthenticate) {
        widget.onSuccess?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication successful!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        widget.onError?.call('Authentication failed');
      }
    } catch (e) {
      widget.onError?.call('Biometric authentication error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quick Access',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use biometric authentication for secure login',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isAuthenticating ? _pulseAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: _authenticateWithBiometrics,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isAuthenticating
                            ? [Colors.orange.shade400, Colors.red.shade400]
                            : [Colors.green.shade400, Colors.blue.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade200,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isAuthenticating
                          ? Icons.hourglass_empty
                          : Icons.fingerprint,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            _isAuthenticating ? 'Authenticating...' : 'Tap to authenticate',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
