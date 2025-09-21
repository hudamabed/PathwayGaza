import 'package:flutter/material.dart';
import 'features/landing/landing_page.dart';

/// A thin shell that just renders your landing page and
/// passes down the language toggle coming from main.dart.
class GazaLearningShell extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  const GazaLearningShell({
    super.key,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return LandingPage(
      isArabic: isArabic,
      onToggleLanguage: onToggleLanguage,
    );
  }
}
