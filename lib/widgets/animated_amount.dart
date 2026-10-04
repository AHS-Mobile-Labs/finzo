import 'package:flutter/material.dart';
import '../utils/formatters.dart';

enum AmountDisplayMode { currency, compact, percentage, integer }

class AnimatedAmount extends StatelessWidget {
  final double value;
  final TextStyle? style;
  final AmountDisplayMode mode;
  final Duration duration;
  final Curve curve;
  final String prefix;
  final String suffix;
  final Alignment alignment;

  const AnimatedAmount({
    super.key,
    required this.value,
    this.style,
    this.mode = AmountDisplayMode.currency,
    this.duration = const Duration(milliseconds: 750),
    this.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.suffix = '',
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('anim_amt_${mode.name}_$value'),
      tween: Tween<double>(begin: value * 0.4, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animValue, child) {
        String formatted;
        switch (mode) {
          case AmountDisplayMode.currency:
            formatted = Formatters.currency(animValue);
            break;
          case AmountDisplayMode.compact:
            formatted = Formatters.compact(animValue);
            break;
          case AmountDisplayMode.percentage:
            formatted = '${animValue.toStringAsFixed(1)}%';
            break;
          case AmountDisplayMode.integer:
            formatted = animValue.round().toString();
            break;
        }

        return Text(
          '$prefix$formatted$suffix',
          style: style,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
