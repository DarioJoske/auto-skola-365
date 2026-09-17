import 'package:flutter/material.dart';

/// Exact Figma shadows for surfaces that opt into elevation.
enum AppElevation {
  none([]),
  level1([
    BoxShadow(color: Color(0x1414213A), offset: Offset(0, 1), blurRadius: 3),
  ]),
  level2([
    BoxShadow(color: Color(0x1A14213A), offset: Offset(0, 4), blurRadius: 12),
  ]),
  level3([
    BoxShadow(color: Color(0x2914213A), offset: Offset(0, 12), blurRadius: 32),
  ]);

  const AppElevation(this.shadows);
  final List<BoxShadow> shadows;
}
