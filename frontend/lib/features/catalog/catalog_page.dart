// lib/features/catalog/catalog_page.dart
import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../main.dart' show AppRoutes, CourseContentArgs;

/// A simple catalogue of courses grouped by grade & subject.
/// - Search by text
/// - Filter by Grade (chips)
/// - Filter by Subject (chips)
/// - Tap a course -> navigates to /course-content with CourseContentArgs
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  String _query = '';
  String? _grade;   // null => All
  String? _subject; // null => All

  // Demo data — replace with API later
  final List<_CatalogCourse> _all = const [
    _CatalogCourse(grade: 'الصف 4', subject: 'الرياضيات', title: 'الرياضيات - الصف 4', icon: Icons.functions_rounded, progress: 0.0, locked: false),
    _CatalogCourse(grade: 'الصف 5', subject: 'اللغة العربية', title: 'اللغة العربية - الصف 5', icon: Icons.menu_book_rounded, progress: 0.0, locked: false),
    _CatalogCourse(grade: 'الصف 6', subject: 'الرياضيات', title: 'الرياضيات - الصف 6', icon: Icons.functions_rounded, progress: 0.4, locked: false),
    _CatalogCourse(grade: 'الصف 6', subject: 'العلوم', title: 'العلوم - الصف 6', icon: Icons.science_rounded, progress: 0.2, locked: false),
    _CatalogCourse(grade: 'الصف 6', subject: 'اللغة العربية', title: 'اللغة العربية - الصف 6', icon: Icons.menu_book_rounded, progress: 0.1, locked: true),
    _CatalogCourse(grade: 'الصف 7', subject: 'مهارات رقمية', title: 'مهارات رقمية - الصف 7', icon: Icons.computer_rounded, progress: 0.0, locked: false),
    _CatalogCourse(grade: 'الصف 9', subject: 'الرياضيات', title: 'الرياضيات - الصف 9', icon: Icons.calculate_rounded, progress: 0.7, locked: false),
    _CatalogCourse(grade: 'الصف 9', subject: 'العلوم', title: 'العلوم - الصف 9', icon: Icons.biotech_rounded, progress: 0.5, locked: false),
  ];

  List<String> get _grades =>
      ['الكل', ...{for (final c in _all) c.grade}].toList()..sort(_arabicAware);

  List<String> get _subjects =>
      ['الكل', ...{for (final c in _all) c.subject}].toList()..sort(_arabicAware);

  @override
  Widget build(BuildContext context) {
    final filtered = _all.where((c) {
      final gOk = _grade == null || c.grade == _grade;
      final sOk = _subject == null || c.subject == _subject;
      final q = _query.trim();
      final qOk = q.isEmpty || c.title.contains(q) || c.subject.contains(q) || c.grade.contains(q);
      return gOk && sOk && qOk;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Palette.pageBackground,
        appBar: AppBar(
          backgroundColor: Palette.primary,
          elevation: 0,
          centerTitle: true,
          title: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apps_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('كتالوج الصفوف', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ],
          ),
          leading: IconButton(
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),

        body: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 1100;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Filters(
                        grades: _grades,
                        subjects: _subjects,
                        selectedGrade: _grade,
                        selectedSubject: _subject,
                        onGradeChanged: (g) => setState(() => _grade = g == 'الكل' ? null : g),
                        onSubjectChanged: (s) => setState(() => _subject = s == 'الكل' ? null : s),
                        query: _query,
                        onQueryChanged: (t) => setState(() => _query = t),
                      ),
                      const SizedBox(height: 16),

                      _Card(
                        padding: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _CoursesGrid(
                            courses: filtered,
                            isWide: isWide,
                            onOpen: _openCourse,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openCourse(_CatalogCourse c) {
    if (c.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أكمل المتطلبات لفتح هذا المحتوى')),
      );
      return;
    }

    final courseId = _toId('${c.subject}-${c.grade}');
    Navigator.of(context).pushNamed(
      AppRoutes.courseContent,
      arguments: CourseContentArgs(
        courseId: courseId,
        courseTitle: _titleOnly(c.title),
        gradeLabel: c.grade,
      ),
    );
  }

  // helpers to derive id/title (same style you used in HomePage)
  static String _toId(String title) => title.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
  static String _titleOnly(String title) {
    final parts = title.split('-');
    return parts.isNotEmpty ? parts.first.trim() : title;
  }

  static int _arabicAware(String a, String b) => a.compareTo(b);
}

/* ======================= Filters Bar ======================= */

class _Filters extends StatelessWidget {
  final List<String> grades;
  final List<String> subjects;
  final String? selectedGrade;
  final String? selectedSubject;
  final ValueChanged<String> onGradeChanged;
  final ValueChanged<String> onSubjectChanged;
  final String query;
  final ValueChanged<String> onQueryChanged;

  const _Filters({
    required this.grades,
    required this.subjects,
    required this.selectedGrade,
    required this.selectedSubject,
    required this.onGradeChanged,
    required this.onSubjectChanged,
    required this.query,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ابحث واختر الصف والمادة', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: query)
              ..selection = TextSelection.collapsed(offset: query.length),
            onChanged: onQueryChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'ابحث عن "رياضيات 6" أو "علوم 9"…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF6F8FC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0x11000000)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...grades.map((g) => ChoiceChip(
                    label: Text(g),
                    selected: selectedGrade == null ? g == 'الكل' : g == selectedGrade,
                    onSelected: (_) => onGradeChanged(g),
                    selectedColor: Palette.primary.withOpacity(.18),
                    side: const BorderSide(color: Color(0x22555555)),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontWeight: (selectedGrade == null && g == 'الكل') || selectedGrade == g
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: Palette.text,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...subjects.map((s) => ChoiceChip(
                    label: Text(s),
                    selected: selectedSubject == null ? s == 'الكل' : s == selectedSubject,
                    onSelected: (_) => onSubjectChanged(s),
                    selectedColor: Palette.primary.withOpacity(.18),
                    side: const BorderSide(color: Color(0x22555555)),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontWeight: (selectedSubject == null && s == 'الكل') || selectedSubject == s
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: Palette.text,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

/* ======================= Grid ======================= */

class _CoursesGrid extends StatelessWidget {
  final List<_CatalogCourse> courses;
  final bool isWide;
  final ValueChanged<_CatalogCourse> onOpen;

  const _CoursesGrid({
    required this.courses,
    required this.isWide,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cross = isWide ? 3 : 1;
    if (courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: Text('لا نتائج مطابقة.', style: TextStyle(color: Palette.subtitle))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      itemCount: courses.length,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 4 / 2,
      ),
      itemBuilder: (context, i) => _Tile(course: courses[i], onOpen: () => onOpen(courses[i])),
    );
  }
}

class _Tile extends StatelessWidget {
  final _CatalogCourse course;
  final VoidCallback onOpen;
  const _Tile({required this.course, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final iconBg = Palette.primary.withOpacity(0.12);

    return InkWell(
      onTap: course.locked ? null : onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(course.icon, size: 48, color: Palette.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Palette.text),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (course.locked)
                        const Tooltip(
                          message: 'أكمل المتطلبات لفتح المحتوى',
                          child: Icon(Icons.lock_outline_rounded, size: 18, color: Colors.redAccent),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(course.grade, style: const TextStyle(color: Palette.subtitle)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: course.progress,
                      minHeight: 10,
                      color: Palette.primary,
                      backgroundColor: Palette.primary.withOpacity(.15),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('${(course.progress * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(course.subject, style: const TextStyle(color: Palette.subtitle)),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: course.locked ? null : onOpen,
                      child: const Text('افتح المقرر'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ======================= Shared bits ======================= */

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/* ======================= Models ======================= */

class _CatalogCourse {
  final String grade;
  final String subject;
  final String title;
  final IconData icon;
  final double progress;
  final bool locked;
  const _CatalogCourse({
    required this.grade,
    required this.subject,
    required this.title,
    required this.icon,
    required this.progress,
    required this.locked,
  });
}
