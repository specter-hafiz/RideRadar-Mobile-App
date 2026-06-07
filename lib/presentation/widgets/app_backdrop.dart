import 'package:flutter/material.dart';
import 'package:shuttletrack/core/utils/responsive.dart';

class AppBackdrop extends StatelessWidget {
  final Widget child;

  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.brightness == Brightness.dark
              ? const [Color(0xFF08110D), Color(0xFF0E1A15), Color(0xFF121F19)]
              : const [Color(0xFFFDFDFB), Color(0xFFF4F7F1), Color(0xFFF8FAF6)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -rs(context, 72),
            right: -rs(context, 28),
            child: _GlowBlob(
              size: rs(context, 180),
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: -rs(context, 96),
            left: -rs(context, 36),
            child: _GlowBlob(
              size: rs(context, 220),
              color: theme.colorScheme.secondary.withValues(alpha: 0.12),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
  }
}
