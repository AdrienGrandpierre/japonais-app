import 'package:flutter/material.dart';

class ScoreBox extends StatelessWidget {
  const ScoreBox({super.key, required this.score});

  final int score;

  double get normalized => score / 5.0;

  Color get _color {
    final t = (normalized + 1) / 2;
    return Color.lerp(Colors.red, Colors.green, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 60,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        normalized == 0 ? "0" : normalized.toStringAsFixed(1),
        style: TextStyle(fontWeight: FontWeight.bold, color: _color),
      ),
    );
  }
}
