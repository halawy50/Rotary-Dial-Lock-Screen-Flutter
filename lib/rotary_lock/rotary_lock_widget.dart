import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'rotary_lock_constants.dart';
import 'dial_painter.dart';

class RotaryLockWidget extends StatefulWidget {
  final String correctCode;
  final VoidCallback? onUnlocked;

  const RotaryLockWidget({
    super.key,
    this.correctCode = '1234',
    this.onUnlocked,
  });

  @override
  State<RotaryLockWidget> createState() => _RotaryLockWidgetState();
}

class _RotaryLockWidgetState extends State<RotaryLockWidget>
    with SingleTickerProviderStateMixin {
  final _rotation = ValueNotifier<double>(0.0);
  final _entered  = <int>[];

  late final AnimationController _anim;

  final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 130,
    ratio: 1.0,
  );

  double? _lastAngle;
  double _maxRotation = 0;
  int? _activeDigit;
  bool _registered = false;

  bool _showError  = false;
  bool _unlocked   = false;
  bool _showUnlock = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController.unbounded(vsync: this);
    _anim.addListener(() {
      _rotation.value = _anim.value.clamp(0.0, double.infinity);
    });
  }

  @override
  void dispose() {
    _rotation.dispose();
    _anim.dispose();
    super.dispose();
  }

  double _maxRotationFor(int digit) {
    var d = (kStopDeg - kRestDeg[digit]!) % 360;
    if (d < 0) d += 360;
    return d * pi / 180;
  }

  double _angleOf(Offset center, Offset point) =>
      atan2(point.dy - center.dy, point.dx - center.dx);

  int? _hitDigit(Offset center, Offset touch, double dialR) {
    final pitchR = dialR * 0.735;
    final holeR  = dialR * 0.16;
    for (final e in kRestDeg.entries) {
      final rad = e.value * pi / 180;
      final hc  = center + Offset(pitchR * cos(rad), pitchR * sin(rad));
      if ((touch - hc).distance <= holeR * 1.3) return e.key;
    }
    return null;
  }

  void _onPanStart(DragStartDetails d, Offset center, double dialR) {
    if (_unlocked) return;
    final digit = _hitDigit(center, d.localPosition, dialR);
    if (digit == null) return;
    _anim.stop();
    _activeDigit    = digit;
    _registered     = false;
    _lastAngle      = _angleOf(center, d.localPosition);
    _maxRotation    = _maxRotationFor(digit);
    _rotation.value = 0;
  }

  void _onPanUpdate(DragUpdateDetails d, Offset center) {
    if (_lastAngle == null) return;
    final curr  = _angleOf(center, d.localPosition);
    var   delta = curr - _lastAngle!;
    if (delta >  pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;
    _lastAngle = curr;

    final v = (_rotation.value + delta).clamp(0.0, _maxRotation);
    _rotation.value = v;

    if (!_registered &&
        _activeDigit != null &&
        v >= _maxRotation - kRegisterDeg * pi / 180) {
      _registered = true;
      HapticFeedback.mediumImpact();
      _commitDigit(_activeDigit!);
    }
  }

  void _onPanEnd(DragEndDetails d) => _release();
  void _onPanCancel() => _release();

  void _release() {
    if (_lastAngle == null) return;
    _lastAngle   = null;
    _activeDigit = null;
    _anim.animateWith(SpringSimulation(_spring, _rotation.value, 0.0, 0.0));
  }

  void _commitDigit(int digit) {
    setState(() {
      _entered.add(digit);
      if (_entered.length >= widget.correctCode.length) {
        if (_entered.map((d) => '$d').join() == widget.correctCode) {
          _unlocked = true;
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 1100), () {
            if (!mounted) return;
            setState(() => _showUnlock = true);
            HapticFeedback.lightImpact();
            widget.onUnlocked?.call();
          });
        } else {
          _showError = true;
          HapticFeedback.vibrate();
          Future.delayed(const Duration(milliseconds: 900), () {
            if (!mounted) return;
            setState(() {
              _showError = false;
              _entered.clear();
            });
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
          child: Row(
            children: [
              const Text(
                'ENTER\nPASSCODE',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  color: kDialColor,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(widget.correctCode.length, (i) {
                  final filled = i < _entered.length;
                  final color  = _showError
                      ? kErrorColor
                      : (filled ? kPinColor : Colors.transparent);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(left: 9),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: _showError ? kErrorColor : kPinColor,
                        width: 1.6,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 900),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.75, end: 1.0).animate(anim),
                child: child,
              ),
            ),
            child: _unlocked
                ? Center(
                    key: ValueKey(_showUnlock ? 'unlock' : 'lock'),
                    child: Text(
                      _showUnlock ? 'Unlock System' : 'Lock',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: kDialColor,
                      ),
                    ),
                  )
                : Center(
                    key: const ValueKey('dial'),
                    child: LayoutBuilder(builder: (ctx, box) {
                      final size   = (box.maxWidth * 0.92).clamp(240.0, 400.0);
                      final center = Offset(size / 2, size / 2);
                      final dialR  = size / 2 - 6;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart:  (d) => _onPanStart(d, center, dialR),
                        onPanUpdate: (d) => _onPanUpdate(d, center),
                        onPanEnd:    _onPanEnd,
                        onPanCancel: _onPanCancel,
                        child: ValueListenableBuilder<double>(
                          valueListenable: _rotation,
                          builder: (_, rot, _) => CustomPaint(
                            size: Size(size, size),
                            painter: DialPainter(rotation: rot, dialR: dialR),
                          ),
                        ),
                      );
                    }),
                  ),
          ),
        ),
      ],
    );
  }
}
