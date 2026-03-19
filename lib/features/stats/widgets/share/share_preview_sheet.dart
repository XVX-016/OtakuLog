import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:otakulog/app/theme.dart';
import 'package:otakulog/core/utils/widget_capture.dart';

class SharePreviewSheet extends StatefulWidget {
  final String title;
  final Widget child;

  const SharePreviewSheet({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  State<SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<SharePreviewSheet> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isWorking = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _captureKey,
                child: widget.child,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isWorking ? null : _saveImage,
                      icon: const Icon(Icons.download_outlined),
                      label: Text(_isWorking ? 'WORKING...' : 'SAVE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isWorking ? null : _shareImage,
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('SHARE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveImage() async {
    await _handleImageOperation(share: false);
  }

  Future<void> _shareImage() async {
    await _handleImageOperation(share: true);
  }

  Future<void> _handleImageOperation({required bool share}) async {
    setState(() => _isWorking = true);
    try {
      final bytes = await captureWidget(_captureKey);
      if (bytes == null) {
        throw Exception('Could not capture image');
      }

      final directory = share
          ? await getTemporaryDirectory()
          : await getApplicationDocumentsDirectory();
      final file = File(
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes, flush: true);

      if (share) {
        await Share.shareXFiles([XFile(file.path)], text: 'My OtakuLog stats');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved image to ${file.path}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isWorking = false);
      }
    }
  }
}
