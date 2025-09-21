import 'package:flutter/material.dart';

/// Global color tokens
class Palette {
  // Brand
  static const Color primary = Color(0xFF4A90E2);     // header, footer, buttons
  static const Color onPrimary = Colors.white;

  // App surfaces
  // 7% alpha background of #4A90E2  → ARGB: 0x12 4A90E2
  static const Color pageBackground = Color(0x124A90E2);

  // Text
  static const Color text = Color(0xFF1F1F1F);
  static const Color subtitle = Color(0xFF5E5E5E);
}
