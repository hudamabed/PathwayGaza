import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

/// A reusable site header that matches your landing header styling.
/// - Works in the `Scaffold.appBar` slot (implements PreferredSizeWidget)
/// - Can optionally show language toggle and auth buttons
/// - Accepts custom trailing actions (e.g., "كتالوج الصفوف")
class SiteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isArabic;
  final VoidCallback? onToggleLanguage;

  /// When provided, shows auth buttons (Register / Login) using these callbacks.
  final VoidCallback? onRegister;
  final VoidCallback? onLogin;

  /// Optional trailing widgets (e.g., actions).
  final List<Widget>? actions;

  /// Control what appears at the center (defaults to the Palestine Learning title).
  final Widget? centerTitle;

  /// Set to false to hide the language toggle.
  final bool showLanguageToggle;

  /// Set to false to hide the auth buttons.
  final bool showAuthButtons;

  const SiteAppBar({
    super.key,
    required this.isArabic,
    this.onToggleLanguage,
    this.onRegister,
    this.onLogin,
    this.actions,
    this.centerTitle,
    this.showLanguageToggle = true,
    this.showAuthButtons = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Palette.primary,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // logo
          Image.asset('assets/images/palestine.png', height: 40, fit: BoxFit.contain),
          const SizedBox(width: 8),
          centerTitle ??
              const Text(
                'فلسطين للتعلم\nPalestine Learning',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  height: 1.15,
                ),
              ),
          const SizedBox(width: 8),
          const Icon(Icons.menu_book_rounded, color: Colors.black87),
        ],
      ),
      actions: [
        if (showLanguageToggle)
          TextButton(
            onPressed: onToggleLanguage,
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            child: Text(isArabic ? 'الإنجليزية | العربية' : 'العربية | English'),
          ),
        if (showAuthButtons) ...[
          const SizedBox(width: 6),
          TextButton(
            onPressed: onRegister,
            child: const Text('إنشاء حساب', style: TextStyle(color: Colors.black)),
          ),
          const SizedBox(width: 6),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: onLogin,
            child: const Text('تسجيل الدخول'),
          ),
        ],
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
    );
  }
}
