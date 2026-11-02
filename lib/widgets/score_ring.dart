import 'package:flutter/material.dart';

import '../app.dart';

/// Vòng tròn hiển thị điểm 0..100.
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 96, this.label, this.stroke = 9});

  final double score;
  final double size;
  final String? label;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(context, score);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: v,
              strokeWidth: stroke,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (v * 100).round().toString(),
                    style: TextStyle(fontSize: size * 0.3, fontWeight: FontWeight.w800, color: color, height: 1),
                  ),
                  if (label != null)
                    Text(label!, style: TextStyle(fontSize: size * 0.11, color: Theme.of(context).hintColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thanh điểm thành phần (Accuracy / Completeness / Fluency).
class SubScoreBar extends StatelessWidget {
  const SubScoreBar({super.key, required this.label, required this.value, this.icon});

  final String label;
  final double? value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final v = value;
    final color = v == null ? Theme.of(context).disabledColor : scoreColor(context, v);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 6)],
          SizedBox(width: 92, child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: v == null ? 0 : v / 100,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 34,
            child: Text(v == null ? '–' : v.round().toString(),
                textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
