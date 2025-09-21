import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

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

  String? _grade; // الصف الدراسي (1–12)

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Palette.pageBackground,
        body: Stack(
          children: [
            // Background image (50% opacity overall)
            Positioned.fill(
              child: Image.asset('assets/images/stu_signup.jpg', fit: BoxFit.cover),
            ),
            Positioned.fill(child: Container(color: Colors.white.withOpacity(0.50))),

            // Center the dialog; no scrolling: we rely on a responsive 1/2-column layout
            SafeArea(
              child: LayoutBuilder(
                builder: (context, root) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header strip – 50% brand
                          const _HeaderBanner(flagHeight: 64),

                          // Dialog (50% #D1E0F2)
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
                                  // We’ll use two columns when wide enough to reduce height
                                  final bool isWide = c.maxWidth >= 900;
                                  final double fieldWidth = isWide
                                      ? (c.maxWidth - 24) / 2 // 24 spacing between the two cols
                                      : (c.maxWidth - 0);
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

                                      // The fields grid (1 column on small, 2 columns on wide)
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
                                                  final initial =
                                                      DateTime(now.year - 10, now.month, now.day);
                                                  final picked = await showDatePicker(
                                                    context: context,
                                                    initialDate: initial,
                                                    firstDate: DateTime(1995),
                                                    lastDate: now,
                                                    locale: const Locale('ar'),
                                                    helpText: 'اختر تاريخ الميلاد',
                                                    builder: (ctx, child) {
                                                      // ensure Arabic direction + a subtle rounded sheet
                                                      return Directionality(
                                                        textDirection: TextDirection.rtl,
                                                        child: Theme(
                                                          data: Theme.of(ctx).copyWith(
                                                            dialogTheme: DialogThemeData(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(12),
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

                                      // Submit button (73% brand bg, black text)
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
                                              onPressed: _submit,
                                              child: const Text('إنشاء حساب'),
                                            ),
                                          ),
                                        ),
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

  void _submit() {
    // basic client-side checks
    if (_passCtrl.text != _confirmCtrl.text) {
      _toast('كلمتا المرور غير متطابقتين');
      return;
    }
    if (_grade == null || _grade!.isEmpty) {
      _toast('يرجى اختيار الصف الدراسي');
      return;
    }
    if (_dobCtrl.text.isEmpty) {
      _toast('يرجى اختيار تاريخ الميلاد');
      return;
    }
    _toast('جاري إنشاء الحساب...');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

/* ----------------------- widgets & helpers ----------------------- */

class _HeaderBanner extends StatelessWidget {
  final double flagHeight; // تحكم بحجم شعار فلسطين من هنا
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
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
          child,
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

Widget _textField({
  required TextEditingController controller,
  TextInputType? keyboardType,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.right,
    decoration: const InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget _passwordField({required TextEditingController controller}) {
  return _PasswordField(controller: controller);
}

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
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        ),
      ),
    );
  }
}

Widget _gradeDropdown({
  required String? value,
  required ValueChanged<String?> onChanged,
}) {
  final items = List<String>.generate(12, (i) => 'الصف ${i + 1}');
  return DropdownButtonFormField<String>(
    value: value,
    items: items
        .map((g) => DropdownMenuItem<String>(
              value: g,
              child: Text(g, textDirection: TextDirection.rtl),
            ))
        .toList(),
    onChanged: onChanged,
    decoration: const InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
    ),
    isExpanded: true,
    icon: const Icon(Icons.keyboard_arrow_down),
  );
}

Widget _dateField({
  required TextEditingController controller,
  required VoidCallback onPick,
}) {
  return TextFormField(
    controller: controller,
    readOnly: true,
    onTap: onPick,
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.right,
    decoration: const InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: 'yyyy-mm-dd',
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide.none,
      ),
      suffixIcon: Icon(Icons.date_range),
    ),
  );
}
