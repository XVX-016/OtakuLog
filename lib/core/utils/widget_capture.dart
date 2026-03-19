import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Future<Uint8List?> captureWidget(GlobalKey key, {double pixelRatio = 3}) async {
  final context = key.currentContext;
  if (context == null) return null;

  final boundary = context.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return null;
  if (boundary.debugNeedsPaint) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return captureWidget(key, pixelRatio: pixelRatio);
  }

  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}
