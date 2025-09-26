import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const _cardRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // Use image assets (order flips in RTL).
    final items = [
      const _FeatureCard(imageAsset: 'assets/images/no_wifi.jpg', title: 'تعلّم بلا إنترنت'),
      const _FeatureCard(imageAsset: 'assets/images/book.png',    title: 'محتوى أساسي ومجاني'),
      const _FeatureCard(imageAsset: 'assets/images/test.png',    title: 'اختبارات قصيرة لقياس التقدم'),
      const _FeatureCard(imageAsset: 'assets/images/safe.png',    title: 'آمن للأطفال'),
    ];
    final children = isRtl ? items.reversed.toList() : items;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white, // section card
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'ميزات',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Palette.text),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              final crossAxisCount = w >= 1100 ? 4 : (w >= 700 ? 2 : 1);
              return Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  physics: const NeverScrollableScrollPhysics(),
                  children: children,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  const _FeatureCard({required this.imageAsset, required this.title});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: title,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FeaturesSection._cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image instead of icon
            Flexible(
              child: Image.asset(
                imageAsset,
                height: 92,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: Palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
