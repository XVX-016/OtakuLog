import 'package:flutter/material.dart';
import 'package:goon_tracker/app/theme.dart';
import 'package:goon_tracker/features/search/models/search_filters.dart';

class SearchFilterSheet extends StatefulWidget {
  final SearchFilters initialFilters;

  const SearchFilterSheet({
    super.key,
    required this.initialFilters,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  late SearchFilters _working;

  @override
  void initState() {
    super.initState();
    _working = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    final medium = _working.medium;
    final statusOptions = medium == SearchMedium.anime
        ? const [ContentStatusFilter.any, ContentStatusFilter.airing, ContentStatusFilter.finished]
        : const [ContentStatusFilter.any, ContentStatusFilter.ongoing, ContentStatusFilter.completed];

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'FILTERS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _working = SearchFilters(medium: _working.medium);
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle('Medium'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: SearchMedium.values
                    .map((medium) => _choiceChip(
                          label: _mediumLabel(medium),
                          selected: _working.medium == medium,
                          onTap: () => setState(() {
                            _working = _working.copyWith(
                              medium: medium,
                              status: ContentStatusFilter.any,
                            );
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Adult Mode'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AdultMode.values
                    .map((mode) => _choiceChip(
                          label: _adultLabel(mode),
                          selected: _working.adultMode == mode,
                          onTap: () => setState(() {
                            _working = _working.copyWith(adultMode: mode);
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Sort'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: SearchSort.values
                    .map((sort) => _choiceChip(
                          label: _sortLabel(sort),
                          selected: _working.sort == sort,
                          onTap: () => setState(() {
                            _working = _working.copyWith(sort: sort);
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Status'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: statusOptions
                    .map((status) => _choiceChip(
                          label: _statusLabel(status),
                          selected: _working.status == status,
                          onTap: () => setState(() {
                            _working = _working.copyWith(status: status);
                          }),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Tags'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kCuratedSearchTags
                    .map((tag) => _choiceChip(
                          label: tag,
                          selected: _working.includedTags.contains(tag),
                          onTap: () {
                            setState(() {
                              final nextIncluded = {..._working.includedTags};
                              final nextExcluded = {..._working.excludedTags}
                                ..remove(tag);
                              if (nextIncluded.contains(tag)) {
                                nextIncluded.remove(tag);
                              } else {
                                nextIncluded.add(tag);
                              }
                              _working = _working.copyWith(
                                includedTags: nextIncluded,
                                excludedTags: nextExcluded,
                              );
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _working),
                  child: const Text('APPLY FILTERS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.secondaryText,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : AppTheme.elevated,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primaryText : AppTheme.secondaryText,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  String _mediumLabel(SearchMedium medium) => medium == SearchMedium.anime ? 'Anime' : 'Manga';

  String _adultLabel(AdultMode mode) {
    switch (mode) {
      case AdultMode.off:
        return 'Off';
      case AdultMode.mixed:
        return 'Mixed';
      case AdultMode.explicitOnly:
        return 'Explicit Only';
    }
  }

  String _sortLabel(SearchSort sort) {
    switch (sort) {
      case SearchSort.trending:
        return 'Trending';
      case SearchSort.popular:
        return 'Popular';
      case SearchSort.updated:
        return 'Updated';
      case SearchSort.score:
        return 'Score';
    }
  }

  String _statusLabel(ContentStatusFilter status) {
    switch (status) {
      case ContentStatusFilter.any:
        return 'Any';
      case ContentStatusFilter.airing:
        return 'Airing';
      case ContentStatusFilter.finished:
        return 'Finished';
      case ContentStatusFilter.ongoing:
        return 'Ongoing';
      case ContentStatusFilter.completed:
        return 'Completed';
    }
  }
}
