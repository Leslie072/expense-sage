import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/bloc/cubit/auth_cubit.dart';
import 'package:expense_sage/helpers/responsive_helper.dart';
import 'package:expense_sage/helpers/currency.helper.dart';
import 'package:expense_sage/services/export_service.dart';
import 'package:expense_sage/services/backup_service.dart';
import 'package:expense_sage/dao/payment_dao.dart';
import 'package:expense_sage/dao/category_dao.dart';
import 'package:expense_sage/dao/account_dao.dart';
import 'package:expense_sage/screens/settings/settings.screen.dart';
import 'package:expense_sage/screens/security/security_settings_screen.dart';
import 'package:expense_sage/screens/database_inspector_screen.dart';

class EnhancedSettingsScreen extends StatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  State<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends State<EnhancedSettingsScreen> {
  final PaymentDao _paymentDao = PaymentDao();
  final CategoryDao _categoryDao = CategoryDao();
  final AccountDao _accountDao = AccountDao();

  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return const SettingsScreen(); // Use existing mobile layout
  }

  Widget _buildTabletLayout() {
    return _buildEnhancedLayout();
  }

  Widget _buildDesktopLayout() {
    return _buildEnhancedLayout();
  }

  Widget _buildEnhancedLayout() {
    return Scaffold(
      body: SingleChildScrollView(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(),

            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

            // App Settings Section
            _buildAppSettingsSection(),

            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

            // Data Management Section
            _buildDataManagementSection(),

            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

            // Security Section
            _buildSecuritySection(),

            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

            // About Section
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 20),
                  ),
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            BlocBuilder<AppCubit, AppState>(
              builder: (context, state) {
                return Row(
                  children: [
                    CircleAvatar(
                      radius:
                          ResponsiveHelper.getResponsiveIconSize(context, 30),
                      child: Text(
                        state.username?.substring(0, 1).toUpperCase() ?? 'U',
                        style: TextStyle(
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 24),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                        width:
                            ResponsiveHelper.getResponsiveSpacing(context, 16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.username ?? 'User',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                          context, 18),
                                ),
                          ),
                          Text(
                            'Currency: ${state.currency ?? 'USD'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                          context, 14),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _editProfile,
                      icon: Icon(
                        Symbols.edit,
                        size:
                            ResponsiveHelper.getResponsiveIconSize(context, 24),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 20),
                  ),
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            _buildSettingsTile(
              icon: Symbols.palette,
              title: 'Theme',
              subtitle: 'System default',
              onTap: _changeTheme,
            ),
            _buildSettingsTile(
              icon: Symbols.language,
              title: 'Language',
              subtitle: 'English',
              onTap: _changeLanguage,
            ),
            _buildSettingsTile(
              icon: Symbols.currency_exchange,
              title: 'Currency',
              subtitle: context.read<AppCubit>().state.currency ?? 'USD',
              onTap: _changeCurrency,
            ),
            _buildSettingsTile(
              icon: Symbols.notifications,
              title: 'Notifications',
              subtitle: 'Manage notification preferences',
              onTap: _manageNotifications,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 20),
                  ),
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            _buildSettingsTile(
              icon: Symbols.download,
              title: 'Export Data',
              subtitle: 'Export your data to CSV or PDF',
              onTap: _showExportOptions,
              trailing: _isExporting ? const CircularProgressIndicator() : null,
            ),
            _buildSettingsTile(
              icon: Symbols.upload,
              title: 'Import Data',
              subtitle: 'Import data from backup file',
              onTap: _importData,
              trailing: _isImporting ? const CircularProgressIndicator() : null,
            ),
            _buildSettingsTile(
              icon: Symbols.backup,
              title: 'Backup & Restore',
              subtitle: 'Create and manage backups',
              onTap: _showBackupOptions,
            ),
            _buildSettingsTile(
              icon: Symbols.sync,
              title: 'Sync Settings',
              subtitle: 'Manage data synchronization',
              onTap: _manageSyncSettings,
            ),
            _buildSettingsTile(
              icon: Symbols.storage,
              title: 'Database Inspector',
              subtitle: 'View database tables and data',
              onTap: _openDatabaseInspector,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 20),
                  ),
            ),
            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 16)),
            _buildSettingsTile(
              icon: Symbols.security,
              title: 'Security Settings',
              subtitle: 'Manage biometric and 2FA',
              onTap: _openSecuritySettings,
            ),
            _buildSettingsTile(
              icon: Symbols.password,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: _changePassword,
            ),
            _buildSettingsTile(
              icon: Symbols.privacy_tip,
              title: 'Privacy Settings',
              subtitle: 'Manage your privacy preferences',
              onTap: _managePrivacy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 20),
                  ),
            ),

            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 16)),

            _buildSettingsTile(
              icon: Symbols.info,
              title: 'App Version',
              subtitle: '1.0.1',
              onTap: null,
            ),

            _buildSettingsTile(
              icon: Symbols.help,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: _showHelp,
            ),

            _buildSettingsTile(
              icon: Symbols.description,
              title: 'Terms & Privacy',
              subtitle: 'Read our terms and privacy policy',
              onTap: _showTermsAndPrivacy,
            ),

            SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(context, 24)),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: ResponsiveHelper.getResponsiveButtonHeight(context),
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: ResponsiveHelper.getResponsiveIconSize(context, 24),
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            ),
      ),
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.getResponsiveSpacing(context, 8),
        vertical: ResponsiveHelper.getResponsiveSpacing(context, 4),
      ),
    );
  }

  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: context.read<AppCubit>().state.username,
        );

        return AlertDialog(
          title: const Text('Edit Profile'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  context.read<AppCubit>().updateUsername(controller.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _changeTheme() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme selection coming soon')),
    );
  }

  void _changeLanguage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Language selection coming soon')),
    );
  }

  void _changeCurrency() async {
    final currencies = await CurrencyHelper.getAllCurrencies();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Currency'),
          content: SizedBox(
            width: ResponsiveHelper.getResponsiveDialogWidth(context),
            height: 400,
            child: ListView.builder(
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                return ListTile(
                  leading: Text(
                    currency.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(currency.name),
                  subtitle: Text('${currency.code} (${currency.symbol})'),
                  onTap: () {
                    context.read<AppCubit>().updateCurrency(currency.code);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _manageNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification settings coming soon')),
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Export to CSV'),
                subtitle:
                    const Text('Export transactions, categories, and accounts'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportToCSV();
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Export to PDF'),
                subtitle: const Text('Generate a comprehensive report'),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportToPDF();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _exportToCSV() async {
    setState(() => _isExporting = true);

    try {
      final currency = context.read<AppCubit>().state.currency ?? 'USD';
      final payments = await _paymentDao.find();
      final categories = await _categoryDao.find();
      final accounts = await _accountDao.find();

      final paymentsPath = await ExportService.exportPaymentsToCSV(
        payments,
        currency: currency,
      );

      final categoriesPath = await ExportService.exportCategoriesToCSV(
        categories,
        currency: currency,
      );

      final accountsPath = await ExportService.exportAccountsToCSV(
        accounts,
        currency: currency,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data exported successfully!\n'
              'Payments: ${paymentsPath?.split('/').last ?? 'Failed'}\n'
              'Categories: ${categoriesPath?.split('/').last ?? 'Failed'}\n'
              'Accounts: ${accountsPath?.split('/').last ?? 'Failed'}',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _exportToPDF() async {
    setState(() => _isExporting = true);

    try {
      final currency = context.read<AppCubit>().state.currency ?? 'USD';
      final userName = context.read<AppCubit>().state.username;
      final payments = await _paymentDao.find();
      final categories = await _categoryDao.find();
      final accounts = await _accountDao.find();

      final dateRange = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );

      final pdfPath = await ExportService.savePDFReport(
        payments: payments,
        categories: categories,
        accounts: accounts,
        dateRange: dateRange,
        currency: currency,
        userName: userName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pdfPath != null
                  ? 'PDF report saved: ${pdfPath.split('/').last}'
                  : 'Failed to generate PDF report',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _importData() async {
    setState(() => _isImporting = true);

    try {
      final filePath = await BackupService.pickBackupFile();
      if (filePath == null) {
        setState(() => _isImporting = false);
        return;
      }

      final isValid = await BackupService.validateBackupFile(filePath);
      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid backup file')),
          );
        }
        setState(() => _isImporting = false);
        return;
      }

      final success = await BackupService.restoreFromBackup(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Data imported successfully' : 'Failed to import data',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showBackupOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup management coming soon')),
    );
  }

  void _manageSyncSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sync settings coming soon')),
    );
  }

  void _openSecuritySettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SecuritySettingsScreen(),
      ),
    );
  }

  void _changePassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change password coming soon')),
    );
  }

  void _managePrivacy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy settings coming soon')),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Help & support coming soon')),
    );
  }

  void _showTermsAndPrivacy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terms & privacy coming soon')),
    );
  }

  void _openDatabaseInspector() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DatabaseInspectorScreen(),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthCubit>().logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
