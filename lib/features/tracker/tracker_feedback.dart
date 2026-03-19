import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otakulog/features/tracker/tracker_notifier.dart';

Future<void> showTrackerFeedback(
  BuildContext context,
  WidgetRef ref,
  TrackerActionResult? result,
) async {
  if (result == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        result.message,
        style: const TextStyle(color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      showCloseIcon: true,
      closeIconColor: Colors.black87,
      action: result.undoAction == null
          ? null
          : SnackBarAction(
              label: 'UNDO',
              textColor: const Color(0xFF9E1B32),
              onPressed: () {
                ref
                    .read(trackerNotifierProvider.notifier)
                    .undoAction(result.undoAction!);
              },
            ),
    ),
  );
}

Future<void> showTrackerMessage(
  BuildContext context, {
  required String message,
}) async {
  if (!context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      showCloseIcon: true,
      closeIconColor: Colors.black87,
    ),
  );
}
