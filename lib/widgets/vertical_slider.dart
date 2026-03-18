import 'package:flutter/material.dart';
import 'package:gestor_pqr/core/theme/app_palette.dart';

/// Slider vertical: arrastrar hacia arriba aumenta el valor, hacia abajo lo disminuye.
/// Altura por defecto 200; min/max/divisions igual que [Slider].
class VerticalSlider extends StatelessWidget {
  const VerticalSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.onChangedStart,
    this.onChangedEnd,
    this.height = 200,
    this.activeColor,
    this.inactiveColor,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChangedStart;
  final ValueChanged<double>? onChangedEnd;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: height,
      width: 48,
      child: RotatedBox(
        quarterTurns: 3, // horizontal → vertical (arriba = max, abajo = min)
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor ?? colorScheme.primary,
            inactiveTrackColor: inactiveColor ?? AppPalette.surfaceContainerHighest,
            thumbColor: activeColor ?? colorScheme.primary,
            overlayColor: (activeColor ?? colorScheme.primary).withOpacity(0.2),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            onChangeStart: onChangedStart,
            onChangeEnd: onChangedEnd,
          ),
        ),
      ),
    );
  }
}
