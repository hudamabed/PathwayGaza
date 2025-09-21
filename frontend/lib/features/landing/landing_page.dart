import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../auth/login_page.dart';            // ⬅️ route target
import 'features_section.dart';
import 'footer_section.dart';
import '../auth/signup_page.dart'; 

class LandingPage extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  const LandingPage({
    super.key,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  static const _maxWidth = 1400.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.pageBackground,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _HeaderBar(isArabic: isArabic, onToggleLanguage: onToggleLanguage),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: _maxWidth),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HeroSection(),
                                SizedBox(height: 32),
                                FeaturesSection(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const FooterSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  const _HeaderBar({
    required this.isArabic,
    required this.onToggleLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.primary,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LandingPage._maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // In RTL, first child is pinned to the RIGHT
                Image.asset('assets/images/palestine.png', height: 40, fit: BoxFit.contain),
                const SizedBox(width: 8),
                const Text(
                  'فلسطين للتعلم\nPalestine Learning',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.menu_book_rounded, color: Colors.black87),

                const Spacer(),

                TextButton(
                  onPressed: onToggleLanguage,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  child: Text(isArabic ? 'الإنجليزية | العربية' : 'العربية | English'),
                ),
                const SizedBox(width: 12),

                // ⬇️ Link both buttons to LoginPage
                TextButton(
  onPressed: () => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SignupPage()),
  ),
  child: Text(isArabic ? 'إنشاء حساب' : 'Register', style: const TextStyle(color: Colors.black)),
),

                const SizedBox(width: 6),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: Text(isArabic ? 'تسجيل الدخول' : 'Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final isWide = c.maxWidth >= 1100;

      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          const Text(
            'التعليم يستمر حتى في أصعب الظروف',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: Palette.text,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'منصة تعليمية مجانية للأطفال في غزة من الصف الأول حتى الصف 12',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 20, height: 1.7, color: Palette.subtitle),
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Palette.primary,
              foregroundColor: Palette.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
              textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            // ⬇️ CTA → LoginPage
            onPressed: () => Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const SignupPage()),
),

            child: const Text('ابدأ الآن'),
          ),
          const SizedBox(height: 16),
        ],
      );

      final art = Semantics(
        label: 'أطفال يقرؤون',
        child: Image.asset(
          'assets/images/hero_kids.png',
          height: isWide ? 420 : 260,
          fit: BoxFit.contain,
        ),
      );

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isWide
            ? Row(
                textDirection: TextDirection.rtl,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: art),
                  const SizedBox(width: 28),
                  Expanded(child: text),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  const SizedBox(height: 16),
                  Center(child: art),
                ],
              ),
      );
    });
  }
}
