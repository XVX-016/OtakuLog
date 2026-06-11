import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/data/local/isar_service.dart';
import 'package:otakulog/data/local/retention_preferences_service.dart';
import 'package:otakulog/data/models/anime_model.dart';
import 'package:otakulog/data/models/daily_activity.dart';
import 'package:otakulog/data/models/manga_model.dart';
import 'package:otakulog/data/models/user_model.dart';
import 'package:otakulog/data/models/user_session_model.dart';
import 'package:otakulog/data/remote/backup_mapper.dart';
import 'package:otakulog/features/cloud/models/backup_payload.dart';
import 'package:otakulog/features/cloud/models/cloud_availability_state.dart';
import 'package:otakulog/features/downloads/download_queue_notifier.dart';
import 'package:otakulog/features/downloads/downloads_manager_screen.dart';
import 'package:otakulog/core/services/local_backup_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:otakulog/core/config/cloud_runtime.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _animeController = TextEditingController();
  final _chapterController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _webdavUrlController = TextEditingController();
  final _webdavUsernameController = TextEditingController();
  final _webdavPasswordController = TextEditingController();

  String _adultMode = 'off';
  String _searchMedium = 'anime';
  bool _blurCovers = false;
  bool _notificationsEnabled = true;
  bool _preferDataSaverDownloads = true;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isSigningIn = false;
  bool _isSigningUp = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isResettingLocalData = false;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isTestingWebdav = false;
  bool _isWebdavSyncing = false;
  bool? _webdavConnectionSuccess;

  bool _isGoogleDriveSyncing = false;
  String? _googleDriveEmail;
  bool _googleDriveLoadingEmail = false;

  @override
  void initState() {
    super.initState();
    _loadSecureCredentials();
    _loadGoogleDriveStatus();
  }

  Future<void> _loadSecureCredentials() async {
    try {
      final secureStorage = ref.read(secureStorageProvider);
      final url = await secureStorage.read(key: 'webdav_url') ?? '';
      final username = await secureStorage.read(key: 'webdav_username') ?? '';
      final password = await secureStorage.read(key: 'webdav_password') ?? '';
      if (mounted) {
        setState(() {
          _webdavUrlController.text = url;
          _webdavUsernameController.text = username;
          _webdavPasswordController.text = password;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadGoogleDriveStatus() async {
    if (!CloudRuntime.isGoogleDriveConfigured) return;
    setState(() => _googleDriveLoadingEmail = true);
    try {
      final email = await ref.read(googleDriveServiceProvider).getUserEmail();
      if (mounted) {
        setState(() {
          _googleDriveEmail = email;
        });
      }
    } catch (_) {} finally {
      if (mounted) {
        setState(() => _googleDriveLoadingEmail = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animeController.dispose();
    _chapterController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _webdavUrlController.dispose();
    _webdavUsernameController.dispose();
    _webdavPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final prefsAsync = ref.watch(retentionPreferencesProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('No profile found yet.',
                  style: TextStyle(color: AppTheme.secondaryText)),
            );
          }
          _seed(user, prefsAsync.valueOrNull);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _label('Profile'),
              const SizedBox(height: 10),
              _fieldLabel('Display Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _decoration('Enter your display name'),
              ),
              const SizedBox(height: 20),
              _label('Defaults'),
              const SizedBox(height: 10),
              _fieldLabel('Average Minutes Per Episode'),
              const SizedBox(height: 8),
              TextField(
                controller: _animeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _decoration('e.g. 24'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Average Minutes Per Chapter'),
              const SizedBox(height: 8),
              TextField(
                controller: _chapterController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _decoration('e.g. 15'),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Default Search Medium'),
              const SizedBox(height: 8),
              _dropdown<String>(
                value: _searchMedium,
                items: const ['anime', 'manga'],
                onChanged: (value) => setState(() => _searchMedium = value!),
              ),
              const SizedBox(height: 12),
              _fieldLabel('Adult Content Preference'),
              const SizedBox(height: 8),
              _dropdown<String>(
                value: _adultMode,
                items: const ['off', 'mixed', 'explicitOnly'],
                onChanged: (value) => setState(() => _adultMode = value!),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _blurCovers,
                activeThumbColor: AppTheme.accent,
                title: const Text('Blur covers in public mode',
                    style: TextStyle(color: AppTheme.primaryText)),
                subtitle: const Text(
                  'Hide covers in shared or public-facing moments.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                onChanged: (value) => setState(() => _blurCovers = value),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _notificationsEnabled,
                activeThumbColor: AppTheme.accent,
                title: const Text('Enable reminders',
                    style: TextStyle(color: AppTheme.primaryText)),
                subtitle: const Text(
                  'Allow one local reminder on inactive days.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                onChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _preferDataSaverDownloads,
                activeThumbColor: AppTheme.accent,
                title: const Text('Use data-saver chapter downloads',
                    style: TextStyle(color: AppTheme.primaryText)),
                subtitle: const Text(
                  'Downloads lower-size MangaDex pages for offline reading.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                onChanged: (value) =>
                    setState(() => _preferDataSaverDownloads = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _save(user),
                child: Text(_isSaving ? 'SAVING...' : 'SAVE SETTINGS'),
              ),
              const SizedBox(height: 24),
              _label('Offline'),
              const SizedBox(height: 10),
              _downloadsCard(ref),
              const SizedBox(height: 20),
              _localBackupRestoreCard(),
              const SizedBox(height: 20),
              _webdavSyncCard(prefsAsync.valueOrNull),
              if (CloudRuntime.isGoogleDriveConfigured) ...[
                const SizedBox(height: 20),
                _googleDriveSyncCard(prefsAsync.valueOrNull),
              ],
              const SizedBox(height: 24),
              _label('About'),
              const SizedBox(height: 10),
              _aboutCard(packageInfoAsync),
              const SizedBox(height: 24),
              _label('Danger Zone'),
              const SizedBox(height: 10),
              _dangerZoneCard(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error: $error',
              style: const TextStyle(color: AppTheme.secondaryText)),
        ),
      ),
    );
  }

  Widget _cloudStatusCard(CloudAvailabilityState state) {
    final (title, subtitle) = switch (state) {
      CloudAvailabilityState.disabledMissingConfig => (
          'Local-only mode',
          'Cloud is not configured in this build. Your tracker still works fully offline.',
        ),
      CloudAvailabilityState.signedOut => (
          'Cloud ready',
          'Sign in to back up your data. Your tracker stays local. Backup is optional.',
        ),
      CloudAvailabilityState.ready => (
          'Cloud connected',
          'You are signed in and can back up or restore data.',
        ),
      CloudAvailabilityState.degradedOffline => (
          'Cloud degraded',
          'Cloud features are temporarily unavailable. Local tracking still works.',
        ),
    };
    return _infoCard(title, subtitle);
  }

  Widget _authCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sign in to back up your data',
            style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your tracker stays local. Backup is optional.',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Email'),
          const SizedBox(height: 8),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.primaryText),
            decoration: _decoration('name@example.com'),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Password'),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: AppTheme.primaryText),
            decoration: _decoration('Enter your password'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSigningIn ? null : _signIn,
                  child: Text(_isSigningIn ? 'SIGNING IN...' : 'SIGN IN'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSigningUp ? null : _signUp,
                  child: Text(_isSigningUp ? 'CREATING...' : 'SIGN UP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signedInCard(String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signed in',
            style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(email, style: const TextStyle(color: AppTheme.secondaryText)),
          const SizedBox(height: 6),
          const Text(
            'Signing out will not erase your local data.',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _signOut,
              child: const Text('SIGN OUT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backupCard({
    required CloudAvailabilityState cloudState,
    required DateTime? lastBackupAt,
    required AsyncValue<BackupPreview?> backupPreviewAsync,
  }) {
    final canUseBackup = cloudState == CloudAvailabilityState.ready;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manual Cloud Backup',
            style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            lastBackupAt == null
                ? 'No successful backup yet.'
                : 'Last backup: ${DateFormat('MMM d, yyyy - h:mm a').format(lastBackupAt)}',
            style: const TextStyle(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 12),
          backupPreviewAsync.when(
            data: (preview) {
              if (preview == null) {
                return const Text('No cloud backup found yet.',
                    style: TextStyle(color: AppTheme.secondaryText));
              }
              return Text(
                'Cloud backup from ${DateFormat('MMM d, yyyy').format(preview.exportedAt)} - ${preview.libraryCount} items - ${preview.sessionsCount} sessions',
                style: const TextStyle(color: AppTheme.secondaryText),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const Text('Cloud preview unavailable.',
                style: TextStyle(color: AppTheme.secondaryText)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: canUseBackup && !_isBackingUp ? _backupNow : null,
                  child: Text(_isBackingUp ? 'BACKING UP...' : 'BACKUP NOW'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      canUseBackup && !_isRestoring ? _restoreData : null,
                  child: Text(_isRestoring ? 'RESTORING...' : 'RESTORE DATA'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(AsyncValue<dynamic> packageInfoAsync) {
    final versionText = packageInfoAsync.valueOrNull == null
        ? 'Version unavailable'
        : '${packageInfoAsync.value.version} (${packageInfoAsync.value.buildNumber})';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OtakuLog',
            style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onLongPress: () => context.push('/debug/analytics'),
            child: Text(versionText,
                style: const TextStyle(color: AppTheme.secondaryText)),
          ),
          const SizedBox(height: 10),
          const Text(
            'A local-first anime and manga tracker with quick logging, wrapped stats, and optional cloud backup.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'Privacy: your tracker works locally first. Cloud backup is optional and only used when you sign in.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
            ),
            onPressed: _sendFeedback,
            icon: const Icon(Icons.mail_outline),
            label: const Text('SEND FEEDBACK'),
          ),
        ],
      ),
    );
  }

  Widget _googleDriveSyncCard(RetentionPreferences? prefs) {
    final lastSynced = prefs?.googleDriveLastSynced;
    final lastError = prefs?.googleDriveLastError;
    final isSignedIn = _googleDriveEmail != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_to_drive_outlined, color: AppTheme.accent),
              SizedBox(width: 8),
              Text(
                'Google Drive Sync',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your database synchronized using your private Google Drive AppData folder. This storage is secure and inaccessible to other apps.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (_googleDriveLoadingEmail) ...[
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent),
              ),
            ),
            const SizedBox(height: 16),
          ] else if (!isSignedIn) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _signInGoogle,
                icon: const Icon(Icons.login_rounded),
                label: const Text('SIGN IN WITH GOOGLE'),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connected Account',
                        style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _googleDriveEmail!,
                        style: const TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.w500, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _signOutGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('SIGN OUT', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          if (lastSynced != null) ...[
            Text(
              'Last synced: ${DateFormat('MMM d, yyyy - h:mm a').format(lastSynced)}',
              style: const TextStyle(color: AppTheme.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          if (lastError != null && lastError.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sync failed: $lastError',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (isSignedIn) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGoogleDriveSyncing ? null : _showGoogleDriveSyncConfirmDialog,
                icon: _isGoogleDriveSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_sync_outlined),
                label: Text(_isGoogleDriveSyncing ? 'SYNCING...' : 'SYNC NOW'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _signInGoogle() async {
    setState(() => _googleDriveLoadingEmail = true);
    try {
      final service = ref.read(googleDriveServiceProvider);
      final account = await service.signIn();
      if (account != null) {
        setState(() {
          _googleDriveEmail = account.email;
        });
        _showMessage('Successfully signed in with Google!');
        ref.invalidate(retentionPreferencesProvider);
      }
    } catch (e) {
      _showErrorDialog('Sign In Failed', e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _googleDriveLoadingEmail = false);
      }
    }
  }

  Future<void> _signOutGoogle() async {
    setState(() => _googleDriveLoadingEmail = true);
    try {
      final service = ref.read(googleDriveServiceProvider);
      await service.signOut();
      setState(() {
        _googleDriveEmail = null;
      });
      _showMessage('Signed out of Google account.');
      ref.invalidate(retentionPreferencesProvider);
    } catch (e) {
      _showErrorDialog('Sign Out Failed', e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _googleDriveLoadingEmail = false);
      }
    }
  }

  Future<void> _showGoogleDriveSyncConfirmDialog() async {
    final isSignedIn = await ref.read(googleDriveServiceProvider).isSignedIn();
    if (!isSignedIn) {
      _showErrorDialog('Not Signed In', 'Please sign in to your Google account before syncing.');
      return;
    }

    if (!mounted) return;

    RestoreMode selectedMode = RestoreMode.merge;

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.cloud_sync_outlined, color: AppTheme.accent),
              SizedBox(width: 8),
              Text(
                'Google Drive Sync Options',
                style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose how remote cloud data should be integrated during sync down:',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              RadioListTile<RestoreMode>(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.accent,
                value: RestoreMode.merge,
                groupValue: selectedMode,
                title: const Text('Merge remote backup (Recommended)',
                    style: TextStyle(color: AppTheme.primaryText, fontSize: 14)),
                subtitle: const Text('Intelligently blends cloud backup logs with local watch history.',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                onChanged: (value) => setDialogState(() => selectedMode = value!),
              ),
              RadioListTile<RestoreMode>(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.accent,
                value: RestoreMode.replaceLocal,
                groupValue: selectedMode,
                title: const Text('Replace local data entirely',
                    style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                subtitle: const Text('Deletes current device library and forces overwrite with remote backup.',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                onChanged: (value) => setDialogState(() => selectedMode = value!),
              ),
              if (selectedMode == RestoreMode.replaceLocal) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: This overrides local database entries. Be absolutely sure!',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText)),
            ),
            ElevatedButton(
              style: selectedMode == RestoreMode.replaceLocal
                  ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C))
                  : null,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('SYNC NOW'),
            ),
          ],
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _executeGoogleDriveSync(selectedMode);
      }
    });
  }

  Future<void> _executeGoogleDriveSync(RestoreMode mode) async {
    setState(() => _isGoogleDriveSyncing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );

    try {
      await ref.read(googleDriveServiceProvider).syncNow(mode: mode);

      if (mounted) {
        Navigator.pop(context); // close loader dialog
        _showMessage('Google Drive sync complete!');

        ref.invalidate(currentUserProvider);
        ref.invalidate(combinedLibraryProvider);
        ref.invalidate(libraryAnimeProvider);
        ref.invalidate(libraryMangaProvider);
        ref.invalidate(allSessionsProvider);
        ref.invalidate(recentSessionsProvider);
        ref.invalidate(activityTimelineProvider);
        ref.invalidate(dailyActivityProvider);
        ref.invalidate(monthlyActivityProvider);
        ref.invalidate(earliestActivityDateProvider);
        ref.invalidate(retentionPreferencesProvider);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader dialog
        _showErrorDialog('Sync Failed', e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleDriveSyncing = false);
      }
    }
  }

  Widget _webdavSyncCard(RetentionPreferences? prefs) {
    final lastSynced = prefs?.webdavLastSyncedAt;
    final lastError = prefs?.webdavLastError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.cloud_queue_outlined, color: AppTheme.accent),
              SizedBox(width: 8),
              Text(
                'WebDAV / Nextcloud Sync',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep your database synchronized using private cloud storage. Connect to custom Nextcloud or WebDAV endpoints.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Server URL'),
          const SizedBox(height: 8),
          TextField(
            controller: _webdavUrlController,
            style: const TextStyle(color: AppTheme.primaryText),
            decoration: _decoration('e.g. https://nextcloud.domain.com/remote.php/dav/files/user/'),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Username'),
          const SizedBox(height: 8),
          TextField(
            controller: _webdavUsernameController,
            style: const TextStyle(color: AppTheme.primaryText),
            decoration: _decoration('Enter your username'),
          ),
          const SizedBox(height: 12),
          _fieldLabel('Password / App Token'),
          const SizedBox(height: 8),
          TextField(
            controller: _webdavPasswordController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            style: const TextStyle(color: AppTheme.primaryText),
            decoration: _decoration('Enter app password or token'),
          ),
          const SizedBox(height: 16),
          if (lastSynced != null) ...[
            Text(
              'Last synced: ${DateFormat('MMM d, yyyy - h:mm a').format(lastSynced)}',
              style: const TextStyle(color: AppTheme.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          if (lastError != null && lastError.trim().isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFB71C1C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sync failed: $lastError',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isTestingWebdav ? null : _testWebdavConnection,
                  icon: _isTestingWebdav
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accent,
                          ),
                        )
                      : (_webdavConnectionSuccess == true
                          ? const Icon(Icons.check_circle_outline, color: Colors.green)
                          : (_webdavConnectionSuccess == false
                              ? const Icon(Icons.error_outline, color: Colors.redAccent)
                              : const Icon(Icons.sync_alt_outlined))),
                  label: Text(_isTestingWebdav ? 'TESTING...' : 'TEST CONNECTION'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isWebdavSyncing ? null : _showWebdavSyncConfirmDialog,
                  icon: _isWebdavSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_sync_outlined),
                  label: Text(_isWebdavSyncing ? 'SYNCING...' : 'SYNC NOW'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testWebdavConnection() async {
    final url = _webdavUrlController.text.trim();
    final user = _webdavUsernameController.text.trim();
    final pass = _webdavPasswordController.text;

    if (url.isEmpty || user.isEmpty || pass.isEmpty) {
      _showErrorDialog('Missing Information', 'Please fill in all WebDAV connection details.');
      return;
    }

    setState(() {
      _isTestingWebdav = true;
      _webdavConnectionSuccess = null;
    });

    try {
      final success = await ref.read(webDavServiceProvider).testConnection(url, user, pass);
      if (success) {
        // Auto-save the credentials securely
        final secureStorage = ref.read(secureStorageProvider);
        await secureStorage.write(key: 'webdav_url', value: url);
        await secureStorage.write(key: 'webdav_username', value: user);
        await secureStorage.write(key: 'webdav_password', value: pass);
        ref.invalidate(retentionPreferencesProvider);

        setState(() => _webdavConnectionSuccess = true);
        _showMessage('Connection test successful! Settings auto-saved.');
      } else {
        setState(() => _webdavConnectionSuccess = false);
        _showErrorDialog('Connection Failed', 'Could not establish connection to server.');
      }
    } catch (e) {
      setState(() => _webdavConnectionSuccess = false);
      _showErrorDialog('Connection Failed', e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isTestingWebdav = false);
      }
    }
  }

  Future<void> _showWebdavSyncConfirmDialog() async {
    final url = _webdavUrlController.text.trim();
    final user = _webdavUsernameController.text.trim();
    final pass = _webdavPasswordController.text;

    if (url.isEmpty || user.isEmpty || pass.isEmpty) {
      _showErrorDialog('Credentials Missing', 'Please configure your WebDAV credentials and test connection before syncing.');
      return;
    }

    // Save credentials securely first to make sure they are active
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.write(key: 'webdav_url', value: url);
    await secureStorage.write(key: 'webdav_username', value: user);
    await secureStorage.write(key: 'webdav_password', value: pass);
    ref.invalidate(retentionPreferencesProvider);

    if (!mounted) return;

    RestoreMode selectedMode = RestoreMode.merge;

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.cloud_sync_outlined, color: AppTheme.accent),
              SizedBox(width: 8),
              Text(
                'WebDAV Sync Options',
                style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose how remote cloud data should be integrated during sync down:',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              RadioListTile<RestoreMode>(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.accent,
                value: RestoreMode.merge,
                groupValue: selectedMode,
                title: const Text('Merge remote backup (Recommended)',
                    style: TextStyle(color: AppTheme.primaryText, fontSize: 14)),
                subtitle: const Text('Intelligently blends cloud backup logs with local watch history.',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                onChanged: (value) => setDialogState(() => selectedMode = value!),
              ),
              RadioListTile<RestoreMode>(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.accent,
                value: RestoreMode.replaceLocal,
                groupValue: selectedMode,
                title: const Text('Replace local data entirely',
                    style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                subtitle: const Text('Deletes current device library and forces overwrite with remote backup.',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                onChanged: (value) => setDialogState(() => selectedMode = value!),
              ),
              if (selectedMode == RestoreMode.replaceLocal) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: This overrides local database entries. Be absolutely sure!',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText)),
            ),
            ElevatedButton(
              style: selectedMode == RestoreMode.replaceLocal
                  ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C))
                  : null,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('SYNC NOW'),
            ),
          ],
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        _executeWebdavSync(selectedMode);
      }
    });
  }

  Future<void> _executeWebdavSync(RestoreMode mode) async {
    setState(() => _isWebdavSyncing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      ),
    );

    try {
      await ref.read(webDavServiceProvider).syncNow(mode: mode);
      
      if (mounted) {
        Navigator.pop(context); // close loader dialog
        _showMessage('Cloud sync complete!');

        ref.invalidate(currentUserProvider);
        ref.invalidate(combinedLibraryProvider);
        ref.invalidate(libraryAnimeProvider);
        ref.invalidate(libraryMangaProvider);
        ref.invalidate(allSessionsProvider);
        ref.invalidate(recentSessionsProvider);
        ref.invalidate(activityTimelineProvider);
        ref.invalidate(dailyActivityProvider);
        ref.invalidate(monthlyActivityProvider);
        ref.invalidate(earliestActivityDateProvider);
        ref.invalidate(retentionPreferencesProvider);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loader dialog
        _showErrorDialog('Sync Failed', e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isWebdavSyncing = false);
      }
    }
  }

  Widget _localBackupRestoreCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sd_storage_outlined, color: AppTheme.accent),
              SizedBox(width: 8),
              Text(
                'Local Backup & Restore',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Save your data to a secure local file, or import an existing backup. Streaks, logs, library, and settings are fully preserved.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportLocalBackup,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(_isExporting ? 'EXPORTING...' : 'EXPORT BACKUP'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isImporting ? null : _importLocalBackup,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accent,
                          ),
                        )
                      : const Icon(Icons.download_for_offline_outlined),
                  label: Text(_isImporting ? 'IMPORTING...' : 'IMPORT BACKUP'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportLocalBackup() async {
    setState(() => _isExporting = true);
    try {
      final success = await ref.read(localBackupServiceProvider).exportBackup();
      if (success) {
        _showMessage('Backup exported successfully');
      }
    } catch (e) {
      _showErrorDialog('Export Failed', e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importLocalBackup() async {
    setState(() => _isImporting = true);
    try {
      final payload = await ref.read(localBackupServiceProvider).pickAndValidateBackup();
      if (payload == null) return; // User cancelled

      if (!mounted) return;

      final preview = ref.read(backupMapperProvider).buildPreview(payload);
      
      final result = await _showRestoreOptionsDialog(payload, preview);
      if (result == true) {
        _showMessage('Backup restored successfully');
        
        ref.invalidate(currentUserProvider);
        ref.invalidate(combinedLibraryProvider);
        ref.invalidate(libraryAnimeProvider);
        ref.invalidate(libraryMangaProvider);
        ref.invalidate(allSessionsProvider);
        ref.invalidate(recentSessionsProvider);
        ref.invalidate(activityTimelineProvider);
        ref.invalidate(dailyActivityProvider);
        ref.invalidate(monthlyActivityProvider);
        ref.invalidate(earliestActivityDateProvider);
      }
    } catch (e) {
      _showErrorDialog('Validation Failed', e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<bool?> _showRestoreOptionsDialog(BackupPayload payload, BackupPreview preview) {
    RestoreMode selectedMode = RestoreMode.merge;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.backup_table_outlined, color: AppTheme.accent),
              SizedBox(width: 8),
              Text(
                'Restore Backup',
                style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Review the contents of the backup file:',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👤 Display Name: ${preview.profileName ?? "Pilot"}',
                        style: const TextStyle(color: AppTheme.primaryText, height: 1.4)),
                    Text('📅 Exported At: ${DateFormat('MMM d, yyyy - h:mm a').format(preview.exportedAt)}',
                        style: const TextStyle(color: AppTheme.primaryText, height: 1.4)),
                    Text('📚 Library: ${preview.libraryCount} items',
                        style: const TextStyle(color: AppTheme.primaryText, height: 1.4)),
                    Text('⏱️ Tracking: ${preview.sessionsCount} sessions',
                        style: const TextStyle(color: AppTheme.primaryText, height: 1.4)),
                    Text('🔥 Streaks: ${preview.streaksCount} days active',
                        style: const TextStyle(color: AppTheme.primaryText, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Restore Mode:',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              RadioListTile<RestoreMode>(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.accent,
                value: RestoreMode.merge,
                groupValue: selectedMode,
                title: const Text('Merge with current data',
                    style: TextStyle(color: AppTheme.primaryText, fontSize: 14)),
                subtitle: const Text('Safely combines backup data with your local tracking history.',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                onChanged: (value) => setDialogState(() => selectedMode = value!),
              ),
              RadioListTile<RestoreMode>(
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.accent,
                value: RestoreMode.replaceLocal,
                groupValue: selectedMode,
                title: const Text('Replace local data entirely',
                    style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                subtitle: const Text('Erases current device logs and overrides with backup data.',
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
                onChanged: (value) => setDialogState(() => selectedMode = value!),
              ),
              if (selectedMode == RestoreMode.replaceLocal) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB71C1C).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: This will overwrite all your current logs. This action is irreversible!',
                          style: TextStyle(color: Colors.redAccent, fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText)),
            ),
            ElevatedButton(
              style: selectedMode == RestoreMode.replaceLocal
                  ? ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C))
                  : null,
              onPressed: () async {
                if (selectedMode == RestoreMode.replaceLocal) {
                  final doubleConfirm = await showDialog<bool>(
                    context: context,
                    builder: (innerContext) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      title: const Text('Are you absolutely sure?', style: TextStyle(color: Colors.redAccent)),
                      content: const Text(
                        'This will delete all current watched/read histories, streaks, and settings on this device and replace them. Continue?',
                        style: TextStyle(color: AppTheme.primaryText),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(innerContext, false),
                          child: const Text('NO, CANCEL'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
                          onPressed: () => Navigator.pop(innerContext, true),
                          child: const Text('YES, REPLACE ALL'),
                        ),
                      ],
                    ),
                  );
                  if (doubleConfirm != true) return;
                }

                if (!mounted) return;

                Navigator.pop(dialogContext, false);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ),
                );

                try {
                  await ref.read(localBackupServiceProvider).restoreBackup(payload, selectedMode);
                  if (mounted) {
                    Navigator.pop(context); // close loader
                    Navigator.pop(dialogContext, true); // return success
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // close loader
                    _showErrorDialog('Restore Failed', e.toString().replaceAll('Exception: ', ''));
                  }
                }
              },
              child: const Text('RESTORE DATA'),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: AppTheme.primaryText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _downloadsCard(WidgetRef ref) {
    final totalBytesAsync = ref.watch(totalDownloadedBytesProvider);
    final downloadsAsync = ref.watch(downloadedChaptersProvider);
    final count = downloadsAsync.valueOrNull?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Offline manga downloads',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count downloaded chapter${count == 1 ? '' : 's'} • ${totalBytesAsync.when(data: DownloadsManagerScreen.formatBytes, loading: () => 'Calculating...', error: (_, __) => 'Unavailable')}',
            style: const TextStyle(color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/downloads'),
              icon: const Icon(Icons.download_done_outlined),
              label: const Text('MANAGE DOWNLOADS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset local app data',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Erase this device profile, library, sessions, retention preferences, and local analytics. Cloud backups are not deleted.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.5),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
              ),
              onPressed: _isResettingLocalData ? null : _resetLocalData,
              child: Text(_isResettingLocalData
                  ? 'RESETTING...'
                  : 'RESET LOCAL DATA'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppTheme.secondaryText)),
        ],
      ),
    );
  }

  void _seed(dynamic user, dynamic prefs) {
    if (_initialized) return;
    _nameController.text = user.displayName;
    _animeController.text = user.defaultAnimeWatchTime.toString();
    _chapterController.text = user.avgChapterMinutes.toString();
    _adultMode = user.defaultAdultMode;
    _searchMedium = user.defaultSearchMedium;
    _blurCovers = user.blurCoverInPublic;
    _notificationsEnabled = prefs?.notificationsEnabled ?? true;
    _preferDataSaverDownloads = prefs?.preferDataSaverDownloads ?? true;
    _initialized = true;
  }

  Future<void> _save(dynamic user) async {
    setState(() => _isSaving = true);
    try {
      final savedUser = user.copyWith(
        name: _nameController.text.trim().isEmpty
            ? user.name
            : _nameController.text.trim(),
        updatedAt: DateTime.now(),
        defaultSearchType: _searchMedium,
        defaultContentRating: _adultMode,
        defaultAnimeWatchTime:
            int.tryParse(_animeController.text.trim()) ??
                user.defaultAnimeWatchTime,
        defaultMangaReadTime: int.tryParse(_chapterController.text.trim()) ??
            user.defaultMangaReadTime,
        filter18Plus: _blurCovers,
      );
      await ref.read(userRepositoryProvider).saveUser(savedUser);

      final prefs = await ref.read(retentionPreferencesProvider.future);
      await ref.read(retentionPreferencesServiceProvider).save(
            prefs.copyWith(
              notificationsEnabled: _notificationsEnabled,
              preferDataSaverDownloads: _preferDataSaverDownloads,
              lastAppOpenedAtIso: DateTime.now().toIso8601String(),
            ),
          );

      // Save WebDAV credentials securely
      final secureStorage = ref.read(secureStorageProvider);
      await secureStorage.write(key: 'webdav_url', value: _webdavUrlController.text.trim());
      await secureStorage.write(key: 'webdav_username', value: _webdavUsernameController.text.trim());
      await secureStorage.write(key: 'webdav_password', value: _webdavPasswordController.text);

      ref.invalidate(currentUserProvider);
      ref.invalidate(retentionPreferencesProvider);
      ref.invalidate(searchDefaultsProvider);
      ref.invalidate(retentionReminderProvider);

      _showMessage('Settings updated');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signUp() async {
    if (!_validateAuthInputs()) return;
    setState(() => _isSigningUp = true);
    try {
      await ref.read(authServiceProvider).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      ref.invalidate(authSessionProvider);
      _showMessage(
          'Account created. Check your inbox if email confirmation is enabled.');
    } catch (error) {
      ref.read(cloudDegradedProvider.notifier).state = _isOfflineError(error);
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSigningUp = false);
    }
  }

  Future<void> _signIn() async {
    if (!_validateAuthInputs()) return;
    setState(() => _isSigningIn = true);
    try {
      await ref.read(authServiceProvider).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      ref.read(cloudDegradedProvider.notifier).state = false;
      ref.invalidate(authSessionProvider);
      _showMessage('Signed in');
    } catch (error) {
      ref.read(cloudDegradedProvider.notifier).state = _isOfflineError(error);
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
      ref.read(cloudDegradedProvider.notifier).state = false;
      ref.invalidate(authSessionProvider);
      ref.invalidate(remoteBackupPreviewProvider);
      _showMessage('Signed out');
    } catch (error) {
      _showMessage(_friendlyError(error));
    }
  }

  Future<void> _resetLocalData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reset local data?'),
        content: const Text(
          'This will erase all local tracker data on this device and return you to onboarding. Cloud backups stay untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isResettingLocalData = true);
    try {
      await ref.read(reminderServiceProvider).cancelReminder();
      await IsarService.instance.writeTxn(() async {
        await IsarService.instance.animeModels.clear();
        await IsarService.instance.mangaModels.clear();
        await IsarService.instance.userSessionModels.clear();
        await IsarService.instance.userModels.clear();
        await IsarService.instance.dailyActivitys.clear();
      });
      await ref
          .read(retentionPreferencesServiceProvider)
          .save(const RetentionPreferences());
      await ref.read(downloadedChapterStoreProvider).clearAll();
      await ref.read(localAnalyticsServiceProvider).reset();
      if (ref.read(authServiceProvider).isAvailable) {
        await ref.read(authServiceProvider).signOut();
      }

      ref.invalidate(authSessionProvider);
      ref.invalidate(authUserProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(retentionPreferencesProvider);
      ref.invalidate(analyticsSnapshotProvider);
      ref.invalidate(combinedLibraryProvider);
      ref.invalidate(libraryAnimeProvider);
      ref.invalidate(libraryMangaProvider);
      ref.invalidate(allSessionsProvider);
      ref.invalidate(recentSessionsProvider);
      ref.invalidate(latestSessionByContentProvider);
      ref.invalidate(activityTimelineProvider);
      ref.invalidate(dailyActivityProvider);
      ref.invalidate(monthlyActivityProvider);
      ref.invalidate(earliestActivityDateProvider);
      ref.invalidate(userPreferenceProfileProvider);
      ref.invalidate(recommendationsProvider);
      ref.invalidate(weeklyWrappedProvider);
      ref.invalidate(monthlyWrappedProvider);
      ref.invalidate(wrappedPromptProvider);
      ref.invalidate(retentionReminderProvider);
      ref.invalidate(remoteBackupPreviewProvider);
      ref.invalidate(downloadedChaptersProvider);
      ref.invalidate(totalDownloadedBytesProvider);
      ref.invalidate(downloadQueueNotifierProvider);

      if (!mounted) return;
      _showMessage('Local app data reset');
      context.go('/launch');
    } catch (error) {
      _showMessage(_friendlyError(error));
    } finally {
      if (mounted) setState(() => _isResettingLocalData = false);
    }
  }

  Future<void> _backupNow() async {
    setState(() => _isBackingUp = true);
    try {
      final profile = await ref.read(currentUserProvider.future);
      final library = await ref.read(combinedLibraryProvider.future);
      final sessions = await ref.read(allSessionsProvider.future);
      final result = await ref.read(syncServiceProvider).pushLocalToRemote(
            profile: profile,
            library: library,
            sessions: sessions,
          );
      if (result.success) {
        await ref.read(localAnalyticsServiceProvider).track('backup_now');
        ref.invalidate(analyticsSnapshotProvider);
      }
      ref.read(cloudDegradedProvider.notifier).state = !result.success &&
          (result.message.toLowerCase().contains('internet') ||
              result.message.toLowerCase().contains('socket'));
      ref.invalidate(retentionPreferencesProvider);
      ref.invalidate(remoteBackupPreviewProvider);
      _showMessage(result.message);
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _restoreData() async {
    final remote = await ref.read(syncServiceProvider).previewRemoteBackup();
    if (remote == null) {
      _showMessage('No backup found');
      return;
    }
    if (!mounted) {
      return;
    }
    final preview = ref.read(backupMapperProvider).buildPreview(remote.payload);
    if (remote.payload.schemaVersion > BackupPayload.currentSchemaVersion) {
      _showMessage('This backup was created by a newer app version.');
      return;
    }

    final mode = await showModalBottomSheet<RestoreMode>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Restore your data',
                style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose how to apply your cloud backup to this device.',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 16),
              Text(
                'Backup from ${DateFormat('MMM d, yyyy - h:mm a').format(preview.exportedAt)}\n'
                '- ${preview.libraryCount} library items\n'
                '- ${preview.sessionsCount} sessions\n'
                '- Display name: ${preview.profileName ?? 'Unknown'}',
                style:
                    const TextStyle(color: AppTheme.primaryText, height: 1.5),
              ),
              const SizedBox(height: 18),
              _restoreOption(
                title: 'Merge with current data',
                subtitle:
                    'Recommended. Keeps this device data and combines it with the backup.',
                onTap: () => Navigator.pop(sheetContext, RestoreMode.merge),
              ),
              const SizedBox(height: 10),
              _restoreOption(
                title: 'Replace local data',
                subtitle:
                    'Erases current device data and restores only the cloud backup.',
                destructive: true,
                onTap: () =>
                    Navigator.pop(sheetContext, RestoreMode.replaceLocal),
              ),
            ],
          ),
        ),
      ),
    );

    if (mode == null) return;
    if (!mounted) {
      return;
    }
    if (mode == RestoreMode.replaceLocal) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Replace local data?'),
          content: const Text(
              'This will overwrite local profile data, library items, sessions, and retention preferences on this device.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Replace')),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isRestoring = true);
    try {
      final result =
          await ref.read(syncServiceProvider).pullRemoteToLocal(mode: mode);
      if (result.success) {
        await ref.read(localAnalyticsServiceProvider).track(
              mode == RestoreMode.merge
                  ? 'restore_merge'
                  : 'restore_replace_local',
            );
        ref.invalidate(analyticsSnapshotProvider);
      }
      ref.read(cloudDegradedProvider.notifier).state = !result.success &&
          (result.message.toLowerCase().contains('internet') ||
              result.message.toLowerCase().contains('socket'));
      ref.invalidate(currentUserProvider);
      ref.invalidate(retentionPreferencesProvider);
      ref.invalidate(combinedLibraryProvider);
      ref.invalidate(allSessionsProvider);
      ref.invalidate(recentSessionsProvider);
      ref.invalidate(latestSessionByContentProvider);
      ref.invalidate(activityTimelineProvider);
      ref.invalidate(dailyActivityProvider);
      ref.invalidate(userPreferenceProfileProvider);
      ref.invalidate(recommendationsProvider);
      ref.invalidate(weeklyWrappedProvider);
      ref.invalidate(monthlyWrappedProvider);
      ref.invalidate(wrappedPromptProvider);
      ref.invalidate(remoteBackupPreviewProvider);
      _showMessage(result.message);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  Future<void> _sendFeedback() async {
    final packageInfo = await ref.read(packageInfoProvider.future);
    final authUser = ref.read(authUserProvider);
    final user = await ref.read(currentUserProvider.future);
    final subject =
        Uri.encodeComponent('OtakuLog feedback ${packageInfo.version}');
    final body = Uri.encodeComponent(
      'App version: ${packageInfo.version} (${packageInfo.buildNumber})\n'
      'Profile: ${user?.displayName ?? 'Unknown'}\n'
      'Signed in: ${authUser?.email ?? 'No'}\n\n'
      'What works well?\n\n'
      'What feels confusing?\n\n'
      'What would you add?\n',
    );
    final mailto = Uri.parse('mailto:xvx016xc@gmail.com?subject=$subject&body=$body');

    if (await canLaunchUrl(mailto)) {
      await launchUrl(mailto);
      return;
    }

    await Clipboard.setData(
      ClipboardData(
        text:
            'OtakuLog feedback ${packageInfo.version}\n\nWhat works well?\n\nWhat feels confusing?\n\nWhat would you add?\n',
      ),
    );
    if (!mounted) {
      return;
    }
    _showMessage('No mail app found. Feedback template copied to clipboard.');
  }

  Widget _restoreOption({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: destructive
                  ? Colors.redAccent.withValues(alpha: 0.3)
                  : Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: destructive ? Colors.redAccent : AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(color: AppTheme.secondaryText)),
          ],
        ),
      ),
    );
  }

  bool _validateAuthInputs() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Enter both email and password');
      return false;
    }
    return true;
  }

  bool _isOfflineError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('socket') ||
        message.contains('network') ||
        message.contains('internet');
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('AuthRetryableFetchException')) {
      return 'Could not reach Supabase. Check your internet connection.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _label(String value) {
    return Text(
      value.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _fieldLabel(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: AppTheme.primaryText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: AppTheme.secondaryText),
      filled: true,
      fillColor: AppTheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.surface,
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(item.toString(),
                        style: const TextStyle(color: AppTheme.primaryText)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
