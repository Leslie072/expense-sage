import 'package:expense_sage/bloc/cubit/auth_cubit.dart';
import 'package:expense_sage/screens/responsive_main_screen.dart';
import 'package:expense_sage/screens/auth/login_screen.dart';
import 'package:expense_sage/screens/auth/two_factor_verification_screen.dart';
import 'package:expense_sage/screens/admin/admin_dashboard_screen.dart';
import 'package:expense_sage/model/user.model.dart';
import 'package:expense_sage/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    // Defer authentication check to allow UI to render first
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<AuthCubit>().checkAuthStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: MediaQuery.of(context).platformBrightness));

    return BlocBuilder<AuthCubit, AuthState>(builder: (context, authState) {
      return MaterialApp(
        title: 'Expense Sage',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: _buildHome(authState),
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
      );
    });
  }

  Widget _buildHome(AuthState authState) {
    if (authState is AuthLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'Expense Sage',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (authState is AuthAuthenticated) {
      // Show admin dashboard for admin users
      if (authState.user.userType == UserType.admin) {
        return AdminDashboardScreen(adminUser: authState.user);
      }
      // Show regular app for personal and business users
      return const ResponsiveMainScreen();
    }

    if (authState is AuthRequires2FA) {
      return const TwoFactorVerificationScreen();
    }

    // AuthUnauthenticated, AuthError, or AuthInitial
    return const LoginScreen();
  }
}
