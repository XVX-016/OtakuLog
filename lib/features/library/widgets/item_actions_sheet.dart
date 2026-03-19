import 'package:flutter/material.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';

class ItemActionsSheet extends StatelessWidget {
  final TrackableContent item;
  final VoidCallback onQuickLog;
  final VoidCallback onLogToTarget;
  final VoidCallback onMarkCompleted;
  final VoidCallback onUpdateRating;
  final VoidCallback onRemove;

  const ItemActionsSheet({
    super.key,
    required this.item,
    required this.onQuickLog,
    required this.onLogToTarget,
    required this.onMarkCompleted,
    required this.onUpdateRating,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final unitLabel = item is AnimeEntity ? 'episode' : 'chapter';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _actionTile(
              icon: Icons.add_circle_outline,
              label: '+1 ${unitLabel[0].toUpperCase()}${unitLabel.substring(1)}',
              onTap: onQuickLog,
            ),
            _actionTile(
              icon: Icons.flag_outlined,
              label: 'Log to target',
              onTap: onLogToTarget,
            ),
            _actionTile(
              icon: Icons.check_circle_outline,
              label: 'Mark completed',
              onTap: onMarkCompleted,
            ),
            _actionTile(
              icon: Icons.star_border,
              label: 'Update rating',
              onTap: onUpdateRating,
            ),
            _actionTile(
              icon: Icons.delete_outline,
              label: 'Remove from library',
              onTap: onRemove,
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.primaryText,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}
