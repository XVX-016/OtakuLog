import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:otakulog/app/providers.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/domain/entities/user.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController =
      TextEditingController(text: '15');
  int _pageIndex = 0;
  String _medium = 'anime';
  String _adultMode = 'off';
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _introPage(
        title: 'Track anime and manga',
        body:
            'Build your library, pick up where you left off, and keep everything local-first.',
        icon: Icons.video_library_outlined,
      ),
      _introPage(
        title: 'Log fast',
        body:
            'Quick +1 logging and target-based progress updates make daily tracking frictionless.',
        icon: Icons.add_task_outlined,
      ),
      _introPage(
        title: 'See stats and wrapped',
        body:
            'Watch your streaks, trends, wrapped summaries, and optional cloud backup grow over time.',
        icon: Icons.insights_outlined,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _isSaving ? null : _skip,
                  child: const Text('SKIP'),
                ),
              ),
              const Text(
                'Welcome to OtakuLog',
                style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'A local-first anime and manga tracker with optional cloud backup.',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 260,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (value) => setState(() => _pageIndex = value),
                  itemBuilder: (_, index) => pages[index],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  pages.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: index == _pageIndex
                          ? AppTheme.accent
                          : AppTheme.elevated,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick setup',
                style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _decoration('Display name'),
              ),
              const SizedBox(height: 12),
              _dropdown(
                value: _medium,
                label: 'Preferred medium',
                items: const ['anime', 'manga'],
                onChanged: (value) => setState(() => _medium = value!),
              ),
              const SizedBox(height: 12),
              _dropdown(
                value: _adultMode,
                label: 'Adult content default',
                items: const ['off', 'mixed', 'explicitOnly'],
                onChanged: (value) => setState(() => _adultMode = value!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: _decoration('Average minutes per chapter/watch'),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'SETTING UP...' : 'START TRACKING'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _introPage({
    required String title,
    required String body,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 36),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(body,
              style:
                  const TextStyle(color: AppTheme.secondaryText, height: 1.5)),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.surface,
          items: items
              .map((item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item == 'explicitOnly' ? 'explicit only' : item,
                      style: const TextStyle(color: AppTheme.primaryText),
                    ),
                  ))
              .toList(),
          hint: Text(label),
          onChanged: onChanged,
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) {
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

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim().isEmpty
          ? 'Pilot'
          : _nameController.text.trim();
      final user = UserEntity(
        id: 'local_user',
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        defaultSearchType: _medium,
        defaultContentRating: _adultMode,
        defaultAnimeWatchTime: int.tryParse(_timeController.text.trim()) ?? 24,
        defaultMangaReadTime: int.tryParse(_timeController.text.trim()) ?? 15,
        filter18Plus: false,
      );
      await ref.read(userRepositoryProvider).saveUser(user);
      ref.invalidate(currentUserProvider);
      if (mounted) context.go('/');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _skip() async {
    _nameController.text = 'Pilot';
    _timeController.text = '15';
    await _save();
  }
}
