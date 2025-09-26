import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.primary,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 1000;

            // Big Palestine logo (on the RIGHT of the text in RTL)
            final logo = Semantics(
              label: 'فلسطين',
              child: Image.asset(
                'assets/images/palestine.png',
                height: isWide ? 120 : 84, // ⬅️ bigger & responsive
                fit: BoxFit.contain,
              ),
            );

            final aboutText = const Column(
              crossAxisAlignment: CrossAxisAlignment.start, // start == right in RTL
              children: [
                Text(
                  'من نحن؟',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'منصتنا التعليمية تقدم محتوى مبسط وممتع للطلاب من الصف الأول حتى الصف الثاني عشر،'
                  ' لمساعدتهم على التعلم بطرق حديثة وتفاعلية. نهدف إلى تسهيل الوصول إلى التعليم،'
                  ' تعزيز مهارات الطلاب، وتقديم تجربة تعليمية آمنة ومناسبة لجميع المراحل الدراسية.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.7,
                    color: Colors.black87,
                  ),
                ),
              ],
            );

            // Cluster: [logo | about text] — logo sits on the RIGHT in RTL
            final aboutCluster = Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                logo,
                const SizedBox(width: 16),
                Expanded(child: aboutText),
              ],
            );

            const socials = Expanded(
              flex: 2,
              child: _SocialBlock(),
            );

            // Use all available width
            return isWide
                ? Row(
                    children: [
                      Expanded(flex: 4, child: aboutCluster),
                      const SizedBox(width: 24),
                      socials,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      aboutCluster,
                      const SizedBox(height: 24),
                      const _SocialBlock(),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _SocialBlock extends StatelessWidget {
  const _SocialBlock();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // keep heading above icons, flush-left
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تابعنا على',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.2,
            ),
          ),
          SizedBox(height: 14),
          _SocialRow(),
        ],
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.start,
      runAlignment: WrapAlignment.start,
      spacing: 16,
      runSpacing: 12,
      children: const [
        _SocialBadge.facebook(),
        _SocialBadge.instagram(),
        _SocialBadge.linkedin(),
      ],
    );
  }
}

/// One badge style for all networks (consistent size, radius, shadow).
class _SocialBadge extends StatelessWidget {
  final Widget child;
  final Color? bg;
  final Gradient? gradient;
  final double size;
  final String semanticsLabel;

  const _SocialBadge._({
    required this.child,
    required this.semanticsLabel,
    this.bg,
    this.gradient,
    this.size = 56,
    Key? key,
  }) : super(key: key);

  const _SocialBadge.facebook({Key? key})
      : this._(
          semanticsLabel: 'Facebook',
          child: const Icon(Icons.facebook_rounded, size: 28, color: Colors.white),
          bg: const Color(0xFF1877F2),
          key: key,
        );

  const _SocialBadge.instagram({Key? key})
      : this._(
          semanticsLabel: 'Instagram',
          child: const Icon(Icons.camera_alt_rounded, size: 26, color: Colors.white),
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)],
          ),
          key: key,
        );

  const _SocialBadge.linkedin({Key? key})
      : this._(
          semanticsLabel: 'LinkedIn',
          child: const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text(
              'in',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          bg: const Color(0xFF0A66C2),
          key: key,
        );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
