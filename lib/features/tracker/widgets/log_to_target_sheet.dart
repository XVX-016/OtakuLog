import 'package:flutter/material.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/core/utils/progress_utils.dart';
import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';

class LogToTargetSheet extends StatefulWidget {
  final TrackableContent content;
  final int minutesPerUnit;
  final int? maxAvailableProgress;

  const LogToTargetSheet({
    super.key,
    required this.content,
    required this.minutesPerUnit,
    this.maxAvailableProgress,
  });

  @override
  State<LogToTargetSheet> createState() => _LogToTargetSheetState();
}

class _LogToTargetSheetState extends State<LogToTargetSheet> {
  late int _target;

  bool get _isAnime => widget.content is AnimeEntity;
  int get _current => widget.content.currentProgress;
  int get _total => widget.content.totalProgress;
  int get _max =>
      getMaxAllowedProgress(widget.content, releaseCap: widget.maxAvailableProgress) ??
      (_current + 100);
  int get _delta => (_target - _current).clamp(0, _max).toInt();

  @override
  void initState() {
    super.initState();
    _target = _current + 1;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isAnime ? 'LOG TO EPISODE' : 'LOG TO CHAPTER',
              style: const TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.content.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _statTile('Current', '$_current')),
                const SizedBox(width: 12),
                Expanded(child: _statTile('New', '$_target')),
                const SizedBox(width: 12),
                Expanded(child: _statTile('Added', '+$_delta')),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _stepButton(Icons.remove, () => _adjustTarget(-1)),
                Expanded(
                  child: Slider(
                    value: _target.toDouble(),
                    min: (_current + 1).toDouble(),
                    max: _max.toDouble(),
                    divisions: (_max - _current - 1).clamp(1, 1000),
                    activeColor: AppTheme.accent,
                    onChanged: (value) {
                      setState(() {
                        _target = value.round();
                      });
                    },
                  ),
                ),
                _stepButton(Icons.add, () => _adjustTarget(1)),
              ],
            ),
            if (_total > 0)
              Text(
                'Max ${progressUnitLabel(widget.content)}: $_max',
                style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
              )
            else if (widget.maxAvailableProgress != null)
              Text(
                'Only $_max ${progressUnitLabel(widget.content)} released so far.',
                style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
              )
            else
              const Text(
                'Total is unknown, so you can keep logging forward.',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
              ),
            const SizedBox(height: 16),
            Text(
              'Estimated time: +${widget.minutesPerUnit * _delta} min',
              style: const TextStyle(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _delta <= 0 ? null : () => Navigator.pop(context, _target),
                child: const Text('LOG PROGRESS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onPressed) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.elevated,
        foregroundColor: AppTheme.primaryText,
      ),
      icon: Icon(icon),
    );
  }

  void _adjustTarget(int delta) {
    setState(() {
      _target = (_target + delta).clamp(_current + 1, _max);
    });
  }
}
