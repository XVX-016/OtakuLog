import 'package:flutter/material.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/core/widgets/gt_ui_components.dart';
import 'package:otakulog/features/search/models/search_filters.dart';
import 'package:otakulog/features/search/models/search_result_item.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResultItem item;
  final VoidCallback onTap;
  final bool compact;
  final String? subtitleOverride;

  const SearchResultCard({
    super.key,
    required this.item,
    required this.onTap,
    this.compact = false,
    this.subtitleOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SizedBox(
        width: 164,
        child: GTCard(
          onTap: onTap,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 0.72,
            child: Stack(
              children: [
                Positioned.fill(
                  child: GTCoverImage(
                    imageUrl: item.content.coverImage,
                    title: item.content.title,
                    badge:
                        item.medium == SearchMedium.anime ? 'ANIME' : 'MANGA',
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x66000000),
                          Color(0xD9000000),
                        ],
                        stops: [0.35, 0.68, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.content.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitleOverride ?? _countLabel(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2E2E8),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GTCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GTCoverImage(
              imageUrl: item.content.coverImage,
              title: item.content.title,
              width: 86,
              height: 124,
              badge: item.medium == SearchMedium.anime ? 'ANIME' : 'MANGA',
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.content.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.primaryText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (item.inLibrary)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'In Library',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metaChip(_countLabel()),
                      if (item.score != null)
                        _metaChip('Score ${item.score!.toStringAsFixed(1)}'),
                      if (item.statusLabel != null &&
                          item.statusLabel!.isNotEmpty)
                        _metaChip(item.statusLabel!),
                    ],
                  ),
                  if (item.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.tags.take(3).join(' | '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.accent.withOpacity(0.94),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if ((item.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.secondaryText,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _countLabel() {
    final mediumLabel = item.medium == SearchMedium.anime ? 'eps' : 'chs';
    if (item.totalCount == null || item.totalCount == 0) {
      return item.medium == SearchMedium.anime
          ? 'Episodes unknown'
          : 'Chapters unknown';
    }
    return '${item.totalCount} $mediumLabel';
  }
}
