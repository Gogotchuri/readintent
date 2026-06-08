import "package:flutter/material.dart";
import "package:marquee/marquee.dart";

/// Shows a plain Text if it fits, or a scrolling Marquee if it overflows.
class AutoMarquee extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const AutoMarquee({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? DefaultTextStyle.of(context).style;
    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: effectiveStyle),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout();

        if (textPainter.width <= constraints.maxWidth) {
          return Text(text, style: effectiveStyle, maxLines: 1);
        }

        return SizedBox(
          height: textPainter.height,
          child: Marquee(
            text: text,
            style: effectiveStyle,
            velocity: 40,
            blankSpace: 80,
            pauseAfterRound: const Duration(seconds: 2),
            startAfter: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
