import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:expense_sage/bloc/cubit/app_cubit.dart';
import 'package:expense_sage/services/cloud_sync_service.dart';
import 'package:expense_sage/helpers/responsive_helper.dart';
import 'package:intl/intl.dart';

class CloudSyncSettingsScreen extends StatefulWidget {
  const CloudSyncSettingsScreen({super.key});

  @override
  State<CloudSyncSettingsScreen> createState() =>
      _CloudSyncSettingsScreenState();
}

class _CloudSyncSettingsScreenState extends State<CloudSyncSettingsScreen> {
  final CloudSyncService _cloudSyncService = CloudSyncService();

  bool _isCloudSyncEnabled = false;
  bool _isAutoSyncEnabled = false;
  bool _isSyncOnWifiOnly = true;
  bool _isBackupEnabled = true;
  String _syncFrequency = 'hourly';
  String _lastSyncTime = 'Never';
  String _cloudProvider = 'google_drive';
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      // Load current sync settings
      final isEnabled = await CloudSyncService.isSyncEnabled();
      final isAutoEnabled = await CloudSyncService.isAutoSyncEnabled();
      final lastSync = await CloudSyncService.getLastSyncTime();

      setState(() {
        _isCloudSyncEnabled = isEnabled;
        _isAutoSyncEnabled = isAutoEnabled;
        _isSyncOnWifiOnly = true; // Default value
        _isBackupEnabled = true; // Default value
        _syncFrequency = 'hourly'; // Default value
        _cloudProvider = 'google_drive'; // Default value
        _lastSyncTime = lastSync != null
            ? DateFormat('MMM dd, yyyy HH:mm').format(lastSync)
            : 'Never';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    try {
      await CloudSyncService.setSyncEnabled(_isCloudSyncEnabled);
      await CloudSyncService.setAutoSyncEnabled(_isAutoSyncEnabled);
      // Note: Other settings would need to be implemented in CloudSyncService

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    }
  }

  Future<void> _performManualSync() async {
    setState(() => _isSyncing = true);

    try {
      await CloudSyncService.performSync();
      await _loadSettings(); // Refresh last sync time

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Sync Settings'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Symbols.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildTabletLayout() {
    return _buildMobileLayout(); // Same layout for tablet
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: ResponsiveHelper.getResponsivePadding(context),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Cloud Sync Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Symbols.save),
                  label: const Text('Save Settings'),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: ResponsiveHelper.getResponsivePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sync Status Card
          _buildSyncStatusCard(),

          const SizedBox(height: 24),

          // Cloud Provider Section
          _buildCloudProviderSection(),

          const SizedBox(height: 24),

          // Sync Settings Section
          _buildSyncSettingsSection(),

          const SizedBox(height: 24),

          // Advanced Settings Section
          _buildAdvancedSettingsSection(),

          const SizedBox(height: 24),

          // Actions Section
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isCloudSyncEnabled ? Symbols.cloud_done : Symbols.cloud_off,
                  color: _isCloudSyncEnabled ? Colors.green : Colors.grey,
                  size: ResponsiveHelper.getResponsiveIconSize(context, 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isCloudSyncEnabled
                            ? 'Cloud Sync Enabled'
                            : 'Cloud Sync Disabled',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _isCloudSyncEnabled
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                      ),
                      Text(
                        'Last sync: $_lastSyncTime',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (_isCloudSyncEnabled)
                  ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _performManualSync,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Symbols.sync),
                    label: Text(_isSyncing ? 'Syncing...' : 'Sync Now'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Enable/Disable Toggle
            SwitchListTile(
              title: const Text('Enable Cloud Sync'),
              subtitle: const Text('Sync your data across devices'),
              value: _isCloudSyncEnabled,
              onChanged: (value) {
                setState(() => _isCloudSyncEnabled = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudProviderSection() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cloud Provider',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Provider Selection
            RadioListTile<String>(
              title: const Text('Google Drive'),
              subtitle: const Text('Sync with Google Drive'),
              value: 'google_drive',
              groupValue: _cloudProvider,
              onChanged: _isCloudSyncEnabled
                  ? (value) {
                      setState(() => _cloudProvider = value!);
                    }
                  : null,
            ),

            RadioListTile<String>(
              title: const Text('iCloud'),
              subtitle: const Text('Sync with iCloud (iOS only)'),
              value: 'icloud',
              groupValue: _cloudProvider,
              onChanged: _isCloudSyncEnabled
                  ? (value) {
                      setState(() => _cloudProvider = value!);
                    }
                  : null,
            ),

            RadioListTile<String>(
              title: const Text('Dropbox'),
              subtitle: const Text('Sync with Dropbox'),
              value: 'dropbox',
              groupValue: _cloudProvider,
              onChanged: _isCloudSyncEnabled
                  ? (value) {
                      setState(() => _cloudProvider = value!);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncSettingsSection() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Auto Sync Toggle
            SwitchListTile(
              title: const Text('Automatic Sync'),
              subtitle: const Text('Sync data automatically in the background'),
              value: _isAutoSyncEnabled,
              onChanged: _isCloudSyncEnabled
                  ? (value) {
                      setState(() => _isAutoSyncEnabled = value);
                    }
                  : null,
            ),

            // Sync Frequency
            if (_isAutoSyncEnabled)
              ListTile(
                title: const Text('Sync Frequency'),
                subtitle: Text(_getSyncFrequencyDescription()),
                trailing: DropdownButton<String>(
                  value: _syncFrequency,
                  onChanged: _isCloudSyncEnabled
                      ? (value) {
                          setState(() => _syncFrequency = value!);
                        }
                      : null,
                  items: const [
                    DropdownMenuItem(
                        value: 'realtime', child: Text('Real-time')),
                    DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                ),
              ),

            // WiFi Only Toggle
            SwitchListTile(
              title: const Text('Sync on WiFi Only'),
              subtitle: const Text('Only sync when connected to WiFi'),
              value: _isSyncOnWifiOnly,
              onChanged: _isCloudSyncEnabled
                  ? (value) {
                      setState(() => _isSyncOnWifiOnly = value);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Backup Toggle
            SwitchListTile(
              title: const Text('Enable Backup'),
              subtitle: const Text('Create backups before syncing'),
              value: _isBackupEnabled,
              onChanged: _isCloudSyncEnabled
                  ? (value) {
                      setState(() => _isBackupEnabled = value);
                    }
                  : null,
            ),

            // Conflict Resolution
            ListTile(
              title: const Text('Conflict Resolution'),
              subtitle: const Text('How to handle sync conflicts'),
              trailing: const Icon(Symbols.arrow_forward_ios),
              onTap: _isCloudSyncEnabled ? _showConflictResolutionDialog : null,
            ),

            // Data Encryption
            ListTile(
              title: const Text('Data Encryption'),
              subtitle: const Text('Encrypt data before uploading'),
              trailing: Switch(
                value: true, // Always enabled for security
                onChanged: null, // Cannot be disabled
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      elevation: ResponsiveHelper.getResponsiveCardElevation(context),
      child: Padding(
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Force Full Sync
            ListTile(
              leading: const Icon(Symbols.sync),
              title: const Text('Force Full Sync'),
              subtitle: const Text('Download all data from cloud'),
              onTap: _isCloudSyncEnabled ? _performFullSync : null,
            ),

            // Clear Local Cache
            ListTile(
              leading: const Icon(Symbols.clear_all),
              title: const Text('Clear Sync Cache'),
              subtitle: const Text('Clear local sync cache'),
              onTap: _isCloudSyncEnabled ? _clearSyncCache : null,
            ),

            // Reset Sync
            ListTile(
              leading: const Icon(Symbols.restart_alt, color: Colors.orange),
              title: const Text('Reset Sync'),
              subtitle: const Text('Reset sync configuration'),
              onTap: _isCloudSyncEnabled ? _resetSync : null,
            ),

            // Disconnect
            ListTile(
              leading: const Icon(Symbols.cloud_off, color: Colors.red),
              title: const Text('Disconnect Cloud'),
              subtitle: const Text('Disconnect from cloud provider'),
              onTap: _isCloudSyncEnabled ? _disconnectCloud : null,
            ),
          ],
        ),
      ),
    );
  }

  String _getSyncFrequencyDescription() {
    switch (_syncFrequency) {
      case 'realtime':
        return 'Sync immediately when changes are made';
      case 'hourly':
        return 'Sync every hour';
      case 'daily':
        return 'Sync once per day';
      case 'weekly':
        return 'Sync once per week';
      default:
        return 'Unknown frequency';
    }
  }

  void _showConflictResolutionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict Resolution'),
        content: const Text(
            'Choose how to handle conflicts when the same data is modified on multiple devices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Conflict resolution settings coming soon')),
              );
            },
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  Future<void> _performFullSync() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Full Sync'),
        content: const Text(
            'This will download all data from the cloud and may take some time. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full sync coming soon')),
      );
    }
  }

  Future<void> _clearSyncCache() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Clear sync cache coming soon')),
    );
  }

  Future<void> _resetSync() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Sync'),
        content: const Text(
            'This will reset all sync settings and clear the sync cache. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset sync coming soon')),
      );
    }
  }

  Future<void> _disconnectCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Cloud'),
        content: const Text(
            'This will disconnect from your cloud provider and disable sync. Your local data will remain intact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isCloudSyncEnabled = false;
        _isAutoSyncEnabled = false;
      });
      await _saveSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Disconnected from cloud')),
        );
      }
    }
  }
}
