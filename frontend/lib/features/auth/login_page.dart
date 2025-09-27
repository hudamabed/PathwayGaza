import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/palette.dart';
import '../../main.dart' show AppRoutes;
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController(text: 'changed@example.com'); // demo default
  final _passCtrl = TextEditingController(text: '010203');              // demo default
  final _emailNode = FocusNode();
  final _passNode = FocusNode();

  bool _obscure = true;
  bool _loading = false;

  // Configurable via --dart-define (falls back to the URL you provided)
  static const String _defaultLoginUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyDSIsEsDEY74pg-FUX5d1ngqhITJKAX1bc';
  static const String _loginUrl =
      String.fromEnvironment('FIREBASE_LOGIN_URL', defaultValue: _defaultLoginUrl);

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _emailNode.dispose();
    _passNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _userCtrl.text.trim();
    final pass = _passCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _toast('الرجاء إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    setState(() => _loading = true);
    try {
      // 1) Call Firebase Auth REST API (as requested)
      final r = await http
          .post(
            Uri.parse(_loginUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': pass,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (r.statusCode != 200) {
        // Try to decode Firebase REST error
        String message = 'تعذر تسجيل الدخول. تأكد من صحة البيانات.';
        try {
          final j = jsonDecode(r.body);
          final code = j['error']?['message']?.toString() ?? '';
          message = _mapFirebaseRestError(code);
        } catch (_) {}
        _toast(message);
        return;
      }

      // 2) Establish the Firebase session for the app (plugin),
      //    so getIdToken() keeps working everywhere else.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pass,
      );

      // Optional: set a display name if it's empty (nice for header)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && (user.displayName == null || user.displayName!.trim().isEmpty)) {
        final nameGuess = email.split('@').first;
        await user.updateDisplayName(nameGuess);
      }

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
    } on FirebaseAuthException catch (e) {
      _toast(_mapFirebasePluginError(e));
    } catch (_) {
      _toast('حدث خطأ غير متوقع. حاول مجددًا.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _userCtrl.text.trim();
    if (email.isEmpty) {
      _toast('أدخل بريدك الإلكتروني أولاً.');
      _emailNode.requestFocus();
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast('تم إرسال رابط استعادة كلمة المرور إلى بريدك.');
    } on FirebaseAuthException catch (e) {
      _toast(_mapFirebasePluginError(e));
    } catch (_) {
      _toast('تعذر إرسال رابط الاستعادة حالياً.');
    }
  }

  String _mapFirebaseRestError(String code) {
    switch (code) {
      case 'EMAIL_NOT_FOUND':
        return 'البريد الإلكتروني غير مسجل.';
      case 'INVALID_PASSWORD':
        return 'كلمة المرور غير صحيحة.';
      case 'USER_DISABLED':
        return 'تم تعطيل هذا الحساب.';
      case 'INVALID_EMAIL':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        return 'محاولات عديدة فاشلة. حاول لاحقاً.';
      default:
        return 'تعذر تسجيل الدخول. ($code)';
    }
  }

  String _mapFirebasePluginError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب.';
      case 'user-not-found':
        return 'البريد الإلكتروني غير مسجل.';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة.';
      case 'too-many-requests':
        return 'محاولات عديدة فاشلة. حاول لاحقاً.';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت.';
      default:
        return 'خطأ: ${e.message ?? e.code}';
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Palette.pageBackground,
        body: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.asset('assets/images/school.png', fit: BoxFit.cover),
            ),
            // 50% overlay to hit the requested opacity
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.50)),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header strip (#4A90E280)
                        const _HeaderBanner(flagHeight: 64), // control logo size here

                        // Dialog container (#D1E0F280)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0x80D1E0F2), // 50%
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              // Fixed spec width 990; clamp on smaller screens
                              final double fieldWidth = c.maxWidth >= 1000
                                  ? 990.0
                                  : (c.maxWidth - 48).clamp(280.0, 990.0).toDouble();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'سجّل دخولك وواصل طريقك نحو المعرفة',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Palette.text,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Label ABOVE fields
                                  const _FieldLabel('البريد الإلكتروني'),
                                  Center(
                                    child: SizedBox(
                                      width: fieldWidth,
                                      height: 66,
                                      child: _buildTextField(
                                        _userCtrl,
                                        obscure: false,
                                        node: _emailNode,
                                        keyboardType: TextInputType.emailAddress,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  const _FieldLabel('كلمة المرور'),
                                  Center(
                                    child: SizedBox(
                                      width: fieldWidth,
                                      height: 66,
                                      child: _buildTextField(
                                        _passCtrl,
                                        obscure: _obscure,
                                        withToggle: true,
                                        node: _passNode,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Right-aligned links (black label + blue action)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _InlineAction(
                                      blackText: 'هل نسيت كلمة المرور؟',
                                      blueAction: 'اضغط هنا',
                                      onTap: _loading ? null : _handleForgotPassword,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _InlineAction(
                                      blackText: 'هل هذه المرة الاولى لك؟',
                                      blueAction: 'سارع بإنشاء حسابك',
                                      onTap: _loading
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => const SignupPage(),
                                                ),
                                              );
                                            },
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // Big Arabic CTA button (bg #4A90E2BA, black text)
                                  Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: 360,
                                        maxWidth: fieldWidth,
                                      ),
                                      child: SizedBox(
                                        height: 64,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(0xBA4A90E2), // 73%
                                            foregroundColor: Colors.black, // black text
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(22),
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          onPressed: _loading ? null : _handleLogin,
                                          child: _loading
                                              ? Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: const [
                                                    SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Text('جاري تسجيل الدخول...'),
                                                  ],
                                                )
                                              : const Text('تسجيل الدخول'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController ctrl, {
    required bool obscure,
    bool withToggle = false,
    FocusNode? node,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: node,
      obscureText: obscure,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      onFieldSubmitted: (_) {
        if (node == _emailNode) {
          _passNode.requestFocus();
        }
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
        suffixIcon: withToggle
            ? IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              )
            : null,
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final double flagHeight; // control Palestine logo size here
  const _HeaderBanner({this.flagHeight = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x804A90E2), // #4A90E280 @ 50%
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          Image.asset('assets/images/palestine.png', height: flagHeight, fit: BoxFit.contain),
          const SizedBox(width: 10),
          const Text(
            'فلسطين للتعلم\nPalestine Learning',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, right: 6),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _InlineAction extends StatelessWidget {
  final String blackText;
  final String blueAction;
  final VoidCallback? onTap;

  const _InlineAction({
    required this.blackText,
    required this.blueAction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Text(
          blackText,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: Palette.primary, // #4A90E2
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 0),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            blueAction,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
