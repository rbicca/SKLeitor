import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

class LinePainter extends CustomPainter {
  LinePainter({required this.windowSize, this.closeWindow = false});

  final Size windowSize;
  final bool closeWindow;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Cores.LARANJA;
    paint.strokeWidth = 2;
    double positionH = windowSize.height / 2.5;
    canvas.drawLine(
      Offset(10, positionH),
      Offset(windowSize.width * .98, positionH),
      paint,
    );
  }

  @override
  bool shouldRepaint(LinePainter oldDelegate) =>
      oldDelegate.closeWindow != closeWindow;
}
