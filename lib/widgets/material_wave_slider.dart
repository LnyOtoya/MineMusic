import 'dart:math';
import 'package:flutter/material.dart';

class MaterialWaveSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final void Function(double)? onChanged;
  final double height;
  final double? amplitude;
  final double velocity;
  final bool paused;
  final Curve transitionCurve;
  final Duration transitionDuration;
  final bool transitionOnChange;
  final Widget Function(BuildContext)? thumbBuilder;
  final double thumbWidth;

  const MaterialWaveSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.onChanged,
    this.height = 48.0,
    this.velocity = 2600.0,
    this.paused = false,
    this.amplitude,
    this.transitionCurve = Curves.easeInOut,
    this.transitionDuration = const Duration(milliseconds: 200),
    this.transitionOnChange = true,
    this.thumbBuilder,
    this.thumbWidth = 6.0,
  });

  @override
  State<MaterialWaveSlider> createState() => MaterialWaveSliderState();
}

class MaterialWaveSliderState extends State<MaterialWaveSlider> with SingleTickerProviderStateMixin {
  double get _amplitude => widget.amplitude ?? (widget.height / 12.0);
  double get _percent => widget.value == 0.0 ? 0.0 : ((_current ?? widget.value) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double? _current;
  Color? _color;
  Path? _defaultPath;
  Widget? _defaultPaint;
  late bool _paused = widget.paused;
  late bool _running = !widget.paused;
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(covariant MaterialWaveSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_current == null) {
      if (widget.paused) {
        pause();
      } else {
        resume();
      }
    }
  }

  void pause() {
    _paused = true;
    _running = false;
    setState(() {});
  }

  void resume() {
    _paused = false;
    _running = true;
    setState(() {});
  }

  void _onPointerDown(PointerDownEvent e, BoxConstraints constraints) {
    if (widget.onChanged != null) {
      setState(() {
        if (widget.transitionOnChange && !_paused) {
          _running = false;
        }
        _current = e.localPosition.dx / constraints.maxWidth * (widget.max - widget.min);
      });
    }
  }

  void _onPointerMove(PointerMoveEvent e, BoxConstraints constraints) {
    if (widget.onChanged != null) {
      setState(() {
        if (widget.transitionOnChange && !_paused) {
          _running = false;
        }
        _current = e.localPosition.dx / constraints.maxWidth * (widget.max - widget.min);
      });
    }
  }

  void _onPointerUp(PointerUpEvent e, BoxConstraints constraints) {
    if (widget.onChanged != null) {
      setState(() {
        if (widget.transitionOnChange && !_paused) {
          _running = true;
        }
        _current = null;
      });
      final value = e.localPosition.dx / constraints.maxWidth * (widget.max - widget.min);
      widget.onChanged?.call(value.clamp(widget.min, widget.max));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      const multiplier = 1 << 32;
      final distance = widget.height * multiplier;
      final duration = widget.velocity * multiplier;
      _controller.animateTo(
        distance,
        duration: Duration(milliseconds: duration.round()),
        curve: Curves.linear,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaults = theme.useMaterial3 ? _SliderDefaultsM3(context) : _SliderDefaultsM2(context);

    SliderThemeData sliderTheme = SliderTheme.of(context);
    sliderTheme = sliderTheme.copyWith(
      trackHeight: sliderTheme.trackHeight ?? defaults.trackHeight,
      activeTrackColor: sliderTheme.activeTrackColor ?? defaults.activeTrackColor,
      inactiveTrackColor: sliderTheme.inactiveTrackColor ?? defaults.inactiveTrackColor,
      secondaryActiveTrackColor: sliderTheme.secondaryActiveTrackColor ?? defaults.secondaryActiveTrackColor,
      disabledActiveTrackColor: sliderTheme.disabledActiveTrackColor ?? defaults.disabledActiveTrackColor,
      disabledInactiveTrackColor: sliderTheme.disabledInactiveTrackColor ?? defaults.disabledInactiveTrackColor,
      disabledSecondaryActiveTrackColor: sliderTheme.disabledSecondaryActiveTrackColor ?? defaults.disabledSecondaryActiveTrackColor,
      activeTickMarkColor: sliderTheme.activeTickMarkColor ?? defaults.activeTickMarkColor,
      inactiveTickMarkColor: sliderTheme.inactiveTickMarkColor ?? defaults.inactiveTickMarkColor,
      disabledActiveTickMarkColor: sliderTheme.disabledActiveTickMarkColor ?? defaults.disabledActiveTickMarkColor,
      disabledInactiveTickMarkColor: sliderTheme.disabledInactiveTickMarkColor ?? defaults.disabledInactiveTickMarkColor,
      thumbColor: sliderTheme.thumbColor ?? defaults.thumbColor,
      disabledThumbColor: sliderTheme.disabledThumbColor ?? defaults.disabledThumbColor,
      valueIndicatorTextStyle: sliderTheme.valueIndicatorTextStyle ?? defaults.valueIndicatorTextStyle,
    );

    if (_color != sliderTheme.activeTrackColor) {
      _defaultPath = null;
      _defaultPaint = null;
    }

    _color ??= sliderTheme.activeTrackColor;
    _defaultPath ??= SinePainter.calculatePath(widget.height / 25.0, _amplitude, 0.0, widget.height, widget.height);
    _defaultPaint ??= CustomPaint(
      key: const ValueKey(true),
      painter: SinePainter(
        color: sliderTheme.activeTrackColor!,
        delta: widget.height / 25.0,
        phase: 0.0,
        amplitude: _amplitude,
        strokeWidth: sliderTheme.trackHeight!,
        path: _defaultPath,
      ),
      size: Size(widget.height, widget.height),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Listener(
            onPointerDown: (e) => _onPointerDown(e, constraints),
            onPointerMove: (e) => _onPointerMove(e, constraints),
            onPointerUp: (e) => _onPointerUp(e, constraints),
            child: Container(
              color: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRect(
                    clipper: RectClipper(_percent),
                    child: SizedBox(
                      width: constraints.maxWidth,
                      height: widget.height,
                      child: ListView.builder(
                        controller: _controller,
                        itemExtent: widget.height,
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.horizontal,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, _) => TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: _running ? _amplitude : 0.0,
                            end: _running ? _amplitude : 0.0,
                          ),
                          curve: widget.transitionCurve,
                          duration: widget.transitionDuration,
                          builder: (context, value, _) {
                            if (value == _amplitude) {
                              return _defaultPaint!;
                            }
                            return CustomPaint(
                              key: ValueKey(value),
                              painter: SinePainter(
                                color: sliderTheme.activeTrackColor!,
                                delta: widget.height / 25.0,
                                phase: 0.0,
                                amplitude: value,
                                strokeWidth: sliderTheme.trackHeight!,
                              ),
                              size: Size(widget.height, widget.height),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * _percent - widget.thumbWidth / 2.0,
                    right: 0.0,
                    child: Container(
                      color: sliderTheme.inactiveTrackColor!,
                      height: sliderTheme.trackHeight!,
                    ),
                  ),
                  Positioned(
                    left: (constraints.maxWidth * _percent - widget.thumbWidth / 3.0).limit(constraints.maxWidth * _percent - widget.thumbWidth),
                    child: widget.thumbBuilder?.call(context) ??
                        Container(
                          width: widget.thumbWidth,
                          height: widget.height * 0.6,
                          decoration: BoxDecoration(
                            color: sliderTheme.thumbColor!,
                            borderRadius: BorderRadius.circular(
                              widget.thumbWidth / 2.0,
                            ),
                          ),
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SinePainter extends CustomPainter {
  final Color color;
  final double delta;
  final double phase;
  final double amplitude;
  final StrokeCap strokeCap;
  final double strokeWidth;
  final Path? path;

  SinePainter({
    required this.color,
    this.delta = 2.0,
    this.phase = pi,
    this.amplitude = 16.0,
    this.strokeCap = StrokeCap.butt,
    this.strokeWidth = 2.0,
    this.path,
  });

  static Path calculatePath(double delta, double amplitude, double phase, double width, double height) {
    final path = Path();
    for (double x = 0.0; x <= width + delta; x += delta) {
      final y = height / 2.0 + amplitude * sin(x / width * 2 * pi + phase);
      if (x == 0.0) {
        path.moveTo(x, y);
      }
      path.lineTo(x, y);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = strokeCap
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      path ?? calculatePath(delta, amplitude, phase, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    final previous = (oldDelegate as SinePainter);
    return color != previous.color || delta != previous.delta || phase != previous.phase || amplitude != previous.amplitude || strokeCap != previous.strokeCap || strokeWidth != previous.strokeWidth;
  }
}

class RectClipper extends CustomClipper<Rect> {
  final double percent;

  const RectClipper(this.percent);

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0.0, 0.0, size.width * percent, size.height);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => (oldClipper as RectClipper).percent != percent;
}

class _SliderDefaultsM3 extends SliderThemeData {
  _SliderDefaultsM3(this.context) : super(trackHeight: 2.5);

  final BuildContext context;
  late final ColorScheme _colors = Theme.of(context).colorScheme;

  @override
  Color? get activeTrackColor => _colors.primary;

  @override
  Color? get inactiveTrackColor => _colors.primary.withValues(alpha: 0.38);

  @override
  Color? get secondaryActiveTrackColor => _colors.primary.withValues(alpha: 0.54);

  @override
  Color? get disabledActiveTrackColor => _colors.onSurface.withValues(alpha: 0.38);

  @override
  Color? get disabledInactiveTrackColor => _colors.onSurface.withValues(alpha: 0.12);

  @override
  Color? get disabledSecondaryActiveTrackColor => _colors.onSurface.withValues(alpha: 0.12);

  @override
  Color? get activeTickMarkColor => _colors.onPrimary.withValues(alpha: 0.38);

  @override
  Color? get inactiveTickMarkColor => _colors.onSurfaceVariant.withValues(alpha: 0.38);

  @override
  Color? get disabledActiveTickMarkColor => _colors.onSurface.withValues(alpha: 0.38);

  @override
  Color? get disabledInactiveTickMarkColor => _colors.onSurface.withValues(alpha: 0.38);

  @override
  Color? get thumbColor => _colors.primary;

  @override
  Color? get disabledThumbColor => Color.alphaBlend(_colors.onSurface.withValues(alpha: 0.38), _colors.surface);

  @override
  Color? get overlayColor => WidgetStateColor.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.dragged)) {
          return _colors.primary.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return _colors.primary.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return _colors.primary.withValues(alpha: 0.12);
        }

        return Colors.transparent;
      });

  @override
  TextStyle? get valueIndicatorTextStyle => Theme.of(context).textTheme.labelMedium!.copyWith(
        color: _colors.onPrimary,
      );
}

class _SliderDefaultsM2 extends SliderThemeData {
  _SliderDefaultsM2(this.context)
      : _colors = Theme.of(context).colorScheme,
        super(trackHeight: 2.5);

  final BuildContext context;
  final ColorScheme _colors;

  @override
  Color? get activeTrackColor => _colors.primary;

  @override
  Color? get inactiveTrackColor => _colors.primary.withValues(alpha: 0.24);

  @override
  Color? get secondaryActiveTrackColor => _colors.primary.withValues(alpha: 0.54);

  @override
  Color? get disabledActiveTrackColor => _colors.onSurface.withValues(alpha: 0.32);

  @override
  Color? get disabledInactiveTrackColor => _colors.onSurface.withValues(alpha: 0.12);

  @override
  Color? get disabledSecondaryActiveTrackColor => _colors.onSurface.withValues(alpha: 0.12);

  @override
  Color? get activeTickMarkColor => _colors.onPrimary.withValues(alpha: 0.54);

  @override
  Color? get inactiveTickMarkColor => _colors.primary.withValues(alpha: 0.54);

  @override
  Color? get disabledActiveTickMarkColor => _colors.onPrimary.withValues(alpha: 0.12);

  @override
  Color? get disabledInactiveTickMarkColor => _colors.onSurface.withValues(alpha: 0.12);

  @override
  Color? get thumbColor => _colors.primary;

  @override
  Color? get disabledThumbColor => Color.alphaBlend(_colors.onSurface.withValues(alpha: .38), _colors.surface);

  @override
  Color? get overlayColor => _colors.primary.withValues(alpha: 0.12);

  @override
  TextStyle? get valueIndicatorTextStyle => Theme.of(context).textTheme.bodyLarge!.copyWith(color: _colors.onPrimary);
}

extension on double {
  double limit(double value) => max(min(this, value), 0.0);
}
