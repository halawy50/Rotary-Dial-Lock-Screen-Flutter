import 'dart:math';
import 'package:flutter/material.dart';
import 'rotary_lock_constants.dart';

class DialPainter extends CustomPainter {
  final double rotation;
  final double dialR;

  const DialPainter({required this.rotation, required this.dialR});

  @override
  void paint(Canvas canvas, Size size) {
    final c       = Offset(size.width / 2, size.height / 2);
    final pitchR  = dialR * 0.735;
    final holeR   = dialR * 0.16;
    final cutoutR = dialR * 0.47;

    canvas.drawCircle(
      c + const Offset(0, 4),
      dialR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rotation);
    canvas.translate(-c.dx, -c.dy);

    canvas.drawCircle(c, dialR, Paint()..color = kDialColor);
    canvas.drawCircle(c, cutoutR, Paint()..color = Colors.white);

    for (final e in kRestDeg.entries) {
      final rad = e.value * pi / 180;
      final hc  = c + Offset(pitchR * cos(rad), pitchR * sin(rad));

      canvas.drawCircle(hc, holeR, Paint()..color = Colors.white);

      final tp = TextPainter(
        text: TextSpan(
          text: '${e.key}',
          style: TextStyle(
            color: kDialColor,
            fontSize: holeR * 0.95,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, hc - Offset(tp.width / 2, tp.height / 2));
    }

    canvas.restore();

    final stopRad = kStopDeg * pi / 180;
    canvas.drawCircle(
      c + Offset(pitchR * cos(stopRad), pitchR * sin(stopRad)),
      holeR * 0.80,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(DialPainter old) =>
      old.rotation != rotation || old.dialR != dialR;
}
