// lib/features/auth/signup_page.dart
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/theme/palette.dart';
import '../../main.dart' show AppRoutes;

/// ======================== API CONFIG ========================
/// Use --dart-define=API_BASE=http://localhost:8000  (or your gateway like http://localhost:3000/api)
/// Defaults: web -> http://localhost:8000 , mobile/emulator -> http://10.0.2.2:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE',
  defaultValue: kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000',
);

class ProfileApi {
  static Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _asJson(http.Response r) {
    try {
      if (r.body.isEmpty) return {};
      final v = jsonDecode(r.body);
      if (v is Map<String, dynamic>) return v;
      if (v is List) return {'_list': v};
      return {};
    } catch (_) {
      return {};
    }
  }

  /// PATCH /users/profile/
  static Future<void> patchProfile({
    required String username,
    required String birthDate, // yyyy-mm-dd
    required int gradeId,
    required String email,
  }) async {
    final url = Uri.parse('${apiBaseUrl.replaceAll(RegExp(r"/$"), "")}/users/profile/');
    final res = await http
        .patch(
          url,
          headers: await _headers(),
          body: jsonEncode({
            'username': username,
            'birth_date': birthDate,
            'grade_id': gradeId,
            'email': email,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final j = _asJson(res);
      final msg = j['detail']?.toString() ??
          j['message']?.toString() ??
          'تعذر حفظ الملف الشخصي (${res.statusCode}).';
      throw Exception(msg);
    }
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String? _grade; // 'الصف 1' .. 'الصف 12'
  bool _busy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  int _gradeIdFromLabel(String? label) {
    if (label == null) return 1;
    final m = RegExp(r'(\d{1,2})').firstMatch(label);
    return (m != null) ? int.tryParse(m.group(1)!) ?? 1 : 1;
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    final dob = _dobCtrl.text.trim();
    final gradeId = _gradeIdFromLabel(_grade);

    if (name.isEmpty) return _toast('يرجى إدخال الاسم');
    if (email.isEmpty || !email.contains('@')) return _toast('يرجى إدخال بريد صحيح');
    if (pass.length < 6) return _toast('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    if (pass != confirm) return _toast('كلمتا المرور غير متطابقتين');
    if (_grade == null) return _toast('يرجى اختيار الصف الدراسي');
    if (dob.isEmpty) return _toast('يرجى اختيار تاريخ الميلاد');

    setState(() => _busy = true);
    try {
      // 1) Create Firebase account
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      await cred.user?.updateDisplayName(name);

      // 2) Best-effort PATCH to backend; do not block success flow
      String? profileWarning;
      try {
        await ProfileApi.patchProfile(
          username: name,
          birthDate: dob,
          gradeId: gradeId,
          email: email,
        );
      } on TimeoutException {
        profileWarning = 'تم إنشاء الحساب، لكن حفظ الملف الشخصي استغرق وقتًا طويلًا.';
      } catch (e) {
        profileWarning = 'تم إنشاء الحساب، لكن تعذر حفظ الملف الشخصي: $e';
      }

      if (!mounted) return;

      // 3) Success SnackBar (include any warning)
      final msg = profileWarning == null
          ? 'تم إنشاء الحساب بنجاح! يمكنك تسجيل الدخول الآن.'
          : '$profileWarning\nيمكنك متابعة تسجيل الدخول الآن.';
      final controller = ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
      );

      // 4) Sign out then navigate to Login after SnackBar closes
      await FirebaseAuth.instance.signOut();
      await controller.closed;
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
    } on FirebaseAuthException catch (e) {
      _toast(_friendlyFirebaseError(e));
    } catch (e) {
      _toast(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'الحساب موجود بالفعل بهذا البريد.';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة، جرّب كلمة أقوى.';
      case 'operation-not-allowed':
        return 'التسجيل بالبريد غير مفعّل في الإعدادات.';
      default:
        return 'خطأ غير متوقع: ${e.message ?? e.code}';
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
            Positioned.fill(
              child: Image.asset('assets/images/stu_signup.jpg', fit: BoxFit.cover),
            ),
            Positioned.fill(child: Container(color: Colors.white.withOpacity(0.50))),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, root) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _HeaderBanner(flagHeight: 64),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0x80D1E0F2),
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
                            child: Form(
                              key: _formKey,
                              child: LayoutBuilder(
                                builder: (context, c) {
                                  final bool isWide = c.maxWidth >= 900;
                                  final double fieldWidth =
                                      isWide ? (c.maxWidth - 24) / 2 : (c.maxWidth - 0);
                                  const double fieldHeight = 66;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'أهلاً بك في منصة غزة للتعلم يسعدنا انضمامك إلينا',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Palette.text,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 24,
                                        runSpacing: 14,
                                        children: [
                                          _Labeled(
                                            label: 'اسم الطالب',
                                            width: fieldWidth,
                                            child: SizedBox(
                                              height: fieldHeight,
                                              child: _textField(
                                                controller: _nameCtrl,
                                                keyboardType: TextInputType.name,
                                              ),
                                            ),
                                          ),
                                          _Labeled(
                                            label: 'البريد الإلكتروني',
                                            width: fieldWidth,
                                            child: SizedBox(
                                              height: fieldHeight,
                                              child: _textField(
                                                controller: _emailCtrl,
                                                keyboardType: TextInputType.emailAddress,
                                              ),
                                            ),
                                          ),
                                          _Labeled(
                                            label: 'كلمة المرور',
                                            width: fieldWidth,
                                            child: SizedBox(
                                              height: fieldHeight,
                                              child: _passwordField(controller: _passCtrl),
                                            ),
                                          ),
                                          _Labeled(
                                            label: 'تأكيد كلمة المرور',
                                            width: fieldWidth,
                                            child: SizedBox(
                                              height: fieldHeight,
                                              child: _passwordField(controller: _confirmCtrl),
                                            ),
                                          ),
                                          _Labeled(
                                            label: 'الصف الدراسي',
                                            width: fieldWidth,
                                            child: SizedBox(
                                              height: fieldHeight,
                                              child: _gradeDropdown(
                                                value: _grade,
                                                onChanged: (v) => setState(() => _grade = v),
                                              ),
                                            ),
                                          ),
                                          _Labeled(
                                            label: 'تاريخ الميلاد',
                                            width: fieldWidth,
                                            child: SizedBox(
                                              height: fieldHeight,
                                              child: _dateField(
                                                controller: _dobCtrl,
                                                onPick: () async {
                                                  final now = DateTime.now();
                                                  final initial = DateTime(now.year - 10, now.month, now.day);
                                                  final picked = await showDatePicker(
                                                    context: context,
                                                    initialDate: initial,
                                                    firstDate: DateTime(1995),
                                                    lastDate: now,
                                                    locale: const Locale('ar'),
                                                    helpText: 'اختر تاريخ الميلاد',
                                                    builder: (ctx, child) {
                                                      return Directionality(
                                                        textDirection: TextDirection.rtl,
                                                        child: Theme(
                                                          data: Theme.of(ctx).copyWith(
                                                            dialogTheme: DialogThemeData(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                            ),
                                                          ),
                                                          child: child!,
                                                        ),
                                                      );
                                                    },
                                                  );
                                                  if (picked != null) {
                                                    _dobCtrl.text =
                                                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Center(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(minWidth: 360, maxWidth: 560),
                                          child: SizedBox(
                                            height: 64,
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: const Color(0xBA4A90E2),
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(22),
                                                ),
                                                textStyle: const TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              onPressed: _busy ? null : _submit,
                                              child: _busy
                                                  ? const SizedBox(
                                                      height: 26, width: 26,
                                                      child: CircularProgressIndicator(strokeWidth: 3),
                                                    )
                                                  : const Text('إنشاء حساب'),
                                            ),
                                          ),
                                        ),
                                      ),

                                      // >>> NEW: small "already have an account?" button
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'لديك حساب بالفعل؟',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pushNamedAndRemoveUntil(
                                                AppRoutes.login,
                                                (r) => false,
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Palette.primary,
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                              minimumSize: const Size(0, 0),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: const Text(
                                              'سجّل الدخول',
                                              style: TextStyle(
                                                decoration: TextDecoration.underline,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------- widgets & helpers ----------------------- */

class _HeaderBanner extends StatelessWidget {
  final double flagHeight;
  const _HeaderBanner({this.flagHeight = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0x804A90E2),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
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
            style: TextStyle(color: Colors.black87, fontSize: 16, height: 1.2, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  final double width;
  const _Labeled({required this.label, required this.child, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 6),
            child: Text(label, textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
          ),
          child,
        ],
      ),
    );
  }
}

Widget _textField({required TextEditingController controller, TextInputType? keyboardType}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.right,
    decoration: const InputDecoration(
      filled: true, fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide.none),
    ),
  );
}

Widget _passwordField({required TextEditingController controller}) => _PasswordField(controller: controller);

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordField({required this.controller});
  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide.none),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}

Widget _gradeDropdown({required String? value, required ValueChanged<String?> onChanged}) {
  final items = List<String>.generate(12, (i) => 'الصف ${i + 1}');
  return DropdownButtonFormField<String>(
    value: value,
    items: items.map((g) => DropdownMenuItem<String>(value: g, child: Text(g, textDirection: TextDirection.rtl))).toList(),
    onChanged: onChanged,
    decoration: const InputDecoration(
      filled: true, fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide.none),
    ),
    isExpanded: true,
    icon: const Icon(Icons.keyboard_arrow_down),
  );
}

Widget _dateField({required TextEditingController controller, required VoidCallback onPick}) {
  return TextFormField(
    controller: controller,
    readOnly: true,
    onTap: onPick,
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.right,
    decoration: const InputDecoration(
      filled: true, fillColor: Colors.white, hintText: 'yyyy-mm-dd',
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)), borderSide: BorderSide.none),
      suffixIcon: Icon(Icons.date_range),
    ),
  );
}
