import 'package:flutter/material.dart';

class ScoreBox extends StatelessWidget {
  const ScoreBox({super.key, required this.score});

  final int score;

  double get _normalized => score / 5.0;

  Color get _color {
    final t = (_normalized + 1) / 2;
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
        _normalized == 0 ? "0" : _normalized.toStringAsFixed(1),
        style: TextStyle(fontWeight: FontWeight.bold, color: _color),
      ),
    );
  }
}
