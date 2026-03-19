import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/domain/entities/user.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _chapterController = TextEditingController();
  String _adultMode = 'off';
  String _searchMedium = 'anime';
  bool _blurCovers = false;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text(
                'No profile found yet.',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
            );
          }

          _seedFields(user);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _sectionLabel('Profile'),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _inputDecoration('Display name'),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Defaults'),
              const SizedBox(height: 10),
              _dropdownCard<String>(
                label: 'Default Search Medium',
                value: _searchMedium,
                items: const ['anime', 'manga'],
                onChanged: (value) => setState(() => _searchMedium = value!),
              ),
              const SizedBox(height: 12),
              _dropdownCard<String>(
                label: 'Default Adult Mode',
                value: _adultMode,
                items: const ['off', 'mixed', 'explicitOnly'],
                onChanged: (value) => setState(() => _adultMode = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _chapterController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _inputDecoration('Average minutes per chapter'),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _blurCovers,
                activeColor: AppTheme.accent,
                title: const Text(
                  'Blur covers in public mode',
                  style: TextStyle(color: AppTheme.primaryText),
                ),
                subtitle: const Text(
                  'Hide covers when you want a lower-profile home and library view.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                onChanged: (value) => setState(() => _blurCovers = value),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : () => _save(user),
                child: Text(_isSaving ? 'SAVING...' : 'SAVE SETTINGS'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: AppTheme.secondaryText),
          ),
        ),
      ),
    );
  }

  void _seedFields(UserEntity user) {
    if (_initialized) return;
    _nameController.text = user.displayName;
    _chapterController.text = user.avgChapterMinutes.toString();
    _adultMode = user.defaultAdultMode;
    _searchMedium = user.defaultSearchMedium;
    _blurCovers = user.blurCoverInPublic;
    _initialized = true;
  }

  Future<void> _save(UserEntity user) async {
    setState(() => _isSaving = true);
    try {
      final savedUser = user.copyWith(
        name: _nameController.text.trim().isEmpty ? user.name : _nameController.text.trim(),
        updatedAt: DateTime.now(),
        defaultSearchType: _searchMedium,
        defaultContentRating: _adultMode,
        defaultMangaReadTime: int.tryParse(_chapterController.text.trim()) ?? user.defaultMangaReadTime,
        filter18Plus: _blurCovers,
      );

      await ref.read(userRepositoryProvider).saveUser(savedUser);
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.secondaryText,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _dropdownCard<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.surface,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    item.toString(),
                    style: const TextStyle(color: AppTheme.primaryText),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
