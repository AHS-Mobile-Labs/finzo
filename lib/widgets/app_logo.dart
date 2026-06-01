import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  static const assetPath = 'assets/laucher_icon_img/In use/Finzo Logo.png';

  final double size;
  final double radius;
  final EdgeInsetsGeometry padding;

  const AppLogo({
    super.key,
    this.size = 48,
    double? radius,
    this.padding = EdgeInsets.zero,
  }) : radius = radius ?? size * .24;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        padding: padding,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: scheme.outlineVariant.withAlpha(60)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(assetPath, fit: BoxFit.cover),
      ),
    );
  }
}
