// lib/features/home/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../../main.dart' show AppRoutes, CourseContentArgs, CourseGradesArgs;

/* ======================= Data Layer (swap this with your backend) ======================= */

/// Plain models you can also move to /models later.
class Course {
  final String id;            // stable id from backend
  final String title;         // e.g. 'الرياضيات - الصف 6'
  final IconData icon;        // you can replace with an icon code from backend
  final double progress;      // 0..1
  final bool locked;          // access control from backend
  const Course({
    required this.id,
    required this.title,
    required this.icon,
    required this.progress,
    required this.locked,
  });

  Course copyWith({double? progress, bool? locked}) => Course(
        id: id,
        title: title,
        icon: icon,
        progress: progress ?? this.progress,
        locked: locked ?? this.locked,
      );

  // If your backend returns JSON, implement fromJson/toJson here.
}

class Activity {
  final String title;
  final DateTime when;
  const Activity(this.title, this.when);
}

class HomeData {
  final String studentName;
  final String studentGrade;
  final double overallPercent;
  final int completedLessons;
  final int totalLessons;
  final int percentile;
  final List<Activity> recent;
  final List<Course> courses;
  const HomeData({
    required this.studentName,
    required this.studentGrade,
    required this.overallPercent,
    required this.completedLessons,
    required this.totalLessons,
    required this.percentile,
    required this.recent,
    required this.courses,
  });
}

/// Repository contract — implement this with your backend.
abstract class HomeRepository {
  Future<HomeData> fetchHome();
}

/// Working in-memory fake so the screen is fully functional now.
class FakeHomeRepository implements HomeRepository {
  @override
  Future<HomeData> fetchHome() async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final courses = <Course>[
      Course(
        id: 'math-g6',
        title: 'الرياضيات - الصف 6',
        icon: Icons.functions_rounded,
        progress: 0.62,
        locked: false,
      ),
      Course(
        id: 'science-g6',
        title: 'العلوم - الصف 6',
        icon: Icons.science_rounded,
        progress: 0.30,
        locked: false,
      ),
      Course(
        id: 'arabic-g6',
        title: 'اللغة العربية - 6',
        icon: Icons.menu_book_rounded,
        progress: 0.12,
        locked: true,
      ),
      Course(
        id: 'digital-skills',
        title: 'مهارات رقمية',
        icon: Icons.computer_rounded,
        progress: 0.80,
        locked: false,
      ),
    ];

    final recent = <Activity>[
      Activity('أكملت اختبار “الجمع المطوّل”', DateTime.now().subtract(const Duration(hours: 2))),
      Activity('شاهدت درس “دورة الماء في الطبيعة”', DateTime.now().subtract(const Duration(hours: 6))),
      Activity('فتحت درس “علامات الترقيم – الفاصلة”', DateTime.now().subtract(const Duration(days: 1))),
      Activity('راجعت ملخص “الجذور التربيعية”', DateTime.now().subtract(const Duration(days: 2))),
      Activity('أكملت درس “المحيط والمساحة”', DateTime.now().subtract(const Duration(days: 4))),
    ];

    return HomeData(
      studentName: 'اسم الطالب',
      studentGrade: 'الصف السادس',
      overallPercent: 0.54,
      completedLessons: 27,
      totalLessons: 50,
      percentile: 78,
      recent: recent,
      courses: courses,
    );
  }
}

/* ======================= Home Screen ======================= */

class HomePage extends StatefulWidget {
  /// Optional injection for testing / swapping backends
  final HomeRepository? repository;

  /// You can pass these from login/signup (or provide via repository)
  final String? studentName;
  final String? studentGrade;

  const HomePage({
    super.key,
    this.repository,
    this.studentName,
    this.studentGrade,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeRepository _repo = widget.repository ?? FakeHomeRepository();
  late Future<HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchHome();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.fetchHome();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<HomeData>(
        future: _future,
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting;
          final hasError = snap.hasError;
          final data = snap.data;

          return Scaffold(
            backgroundColor: Palette.pageBackground,
            appBar: _HomeAppBar(
              studentName: data?.studentName ?? widget.studentName ?? 'اسم الطالب',
              studentGrade: data?.studentGrade ?? widget.studentGrade ?? 'الصف السادس',
              onOpenCatalogue: () {
                Navigator.of(context).pushNamed(AppRoutes.catalog);
              },
              onLogout: () {
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
              },
            ),
            body: hasError
                ? _ErrorState(onRetry: _refresh)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final isWide = c.maxWidth >= 1100;

                        // Skeleton while loading
                        if (isLoading && data == null) {
                          return _SkeletonHome(isWide: isWide);
                        }

                        final d = data!;
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: Wrap(
                                spacing: 28,
                                runSpacing: 28,
                                children: [
                                  // ===== Column A (visually right in RTL) =====
                                  SizedBox(
                                    width: isWide ? 440 : c.maxWidth,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _SectionCard(
                                          child: _ProgressSummary(
                                            overallPercent: d.overallPercent,
                                            completedLessons: d.completedLessons,
                                            totalLessons: d.totalLessons,
                                            onShowGrades: () {
                                              Navigator.of(context).pushNamed(
                                                AppRoutes.grades,
                                                arguments: const CourseGradesArgs(
                                                  courseId: 'demo-math-g9',
                                                  courseTitle: 'الرياضيات',
                                                  gradeLabel: 'الصف التاسع',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _SectionCard(child: _CompareCard(percentile: d.percentile)),
                                        const SizedBox(height: 24),
                                        _SectionCard(
                                          child: _RecentActivityList(
                                            items: d.recent,
                                            onTapItem: (a) {
                                              // Navigate to the related resource if you have ids.
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('فتح: ${a.title}')),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ===== Column B (visually left in RTL) =====
                                  SizedBox(
                                    width: isWide ? (1400 - 440 - 28) : c.maxWidth,
                                    child: _SectionCard(
                                      padding: EdgeInsets.zero,
                                      child: _CoursesGrid(
                                        courses: d.courses,
                                        onOpenCourse: (course) {
                                          if (course.locked) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('أكمل المتطلبات لفتح هذا المحتوى')),
                                            );
                                            return;
                                          }
                                          Navigator.of(context).pushNamed(
                                            AppRoutes.courseContent,
                                            arguments: CourseContentArgs(
                                              courseId: course.id,
                                              courseTitle: _titleOnly(course.title),
                                              gradeLabel: _gradeOnly(course.title) ?? d.studentGrade,
                                            ),
                                          );
                                        },
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
        },
      ),
    );
  }

  // Helpers to parse demo title strings; keep until backend supplies explicit fields.
  static String _titleOnly(String title) {
    final parts = title.split('-');
    return parts.isNotEmpty ? parts.first.trim() : title;
  }

  static String? _gradeOnly(String title) {
    final idx = title.indexOf('الصف ');
    if (idx == -1) return null;
    return title.substring(idx).trim();
  }
}

/* ======================= App Bar ======================= */

class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenCatalogue;
  final VoidCallback onLogout;
  final String studentName;
  final String studentGrade;

  const _HomeAppBar({
    required this.onOpenCatalogue,
    required this.onLogout,
    required this.studentName,
    required this.studentGrade,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Palette.primary,
      elevation: 0,
      centerTitle: true,
      titleSpacing: 6,
      leadingWidth: 240,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 10, end: 8),
        child: _AccountHeader(name: studentName, grade: studentGrade),
      ),
      title: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_rounded, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'الصفحة الرئيسية',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      actions: [
        TextButton(
          onPressed: onOpenCatalogue,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('كتالوج الصفوف'),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'تسجيل الخروج',
          icon: const Icon(Icons.logout_rounded),
          onPressed: onLogout,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _AccountHeader extends StatelessWidget {
  final String name;
  final String grade;

  const _AccountHeader({required this.name, required this.grade});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240, minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.32)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.22),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.38)),
            ),
            child: const Icon(Icons.person_rounded, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  grade,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ======================= Section Wrapper ======================= */

class _SectionCard extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final Widget child;
  const _SectionCard({required this.child, this.padding, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }
}

/* ======================= Left Column Widgets ======================= */

class _ProgressSummary extends StatelessWidget {
  final double overallPercent; // 0..1
  final int completedLessons;
  final int totalLessons;
  final VoidCallback? onShowGrades;

  const _ProgressSummary({
    required this.overallPercent,
    required this.completedLessons,
    required this.totalLessons,
    this.onShowGrades,
  });

  @override
  Widget build(BuildContext context) {
    final percentText = '${(overallPercent * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CardTitle('ملخص التقدم'),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: overallPercent,
            minHeight: 14,
            color: Palette.primary,
            backgroundColor: Palette.primary.withOpacity(.15),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text('إجمالي التقدم: $percentText',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('الدروس المكتملة: $completedLessons / $totalLessons',
                style: const TextStyle(color: Palette.subtitle)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.primary,
                    foregroundColor: Palette.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('متابعة آخر درس...')),
                    );
                  },
                  child: const Text('تابع آخر درس'),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.assessment_rounded),
                label: const Text('عرض الدرجات'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Palette.primary.withOpacity(.45)),
                  foregroundColor: Palette.primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: onShowGrades,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  final int percentile; // e.g. 78
  const _CompareCard({required this.percentile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percentile / 100,
                strokeWidth: 8,
                color: Palette.primary,
                backgroundColor: Palette.primary.withOpacity(.15),
              ),
              Text('$percentile%', style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'أعلى من أقرانك في نفس الصف',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Palette.text),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({super.key, required this.items, this.onTapItem});

  final List<Activity> items;
  final ValueChanged<Activity>? onTapItem;

  @override
  Widget build(BuildContext context) {
    final data = items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CardTitle('النشاطات الأخيرة'),
        const SizedBox(height: 8),
        if (data.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('لا يوجد نشاط حديث.', textAlign: TextAlign.center),
          )
        else
          ...data.take(5).map((a) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
                leading: const Icon(Icons.history_rounded, color: Palette.primary),
                title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(_ago(a.when), textDirection: TextDirection.rtl),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onTapItem?.call(a),
              ),
            );
          }),
      ],
    );
  }

  static String _ago(DateTime time) {
    final d = DateTime.now().difference(time);
    if (d.inMinutes < 60) return 'قبل ${d.inMinutes} دقيقة';
    if (d.inHours < 24) return 'قبل ${d.inHours} ساعة';
    return 'قبل ${d.inDays} يوم';
  }
}

/* ======================= Courses Grid (Right Column) ======================= */

class _CoursesGrid extends StatelessWidget {
  final List<Course> courses;
  final ValueChanged<Course> onOpenCourse;
  const _CoursesGrid({required this.courses, required this.onOpenCourse});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final cross = w >= 1200 ? 3 : w >= 880 ? 2 : 1;

      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: _CardTitle('مقرراتي'),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              itemCount: courses.length,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 4 / 2,
              ),
              itemBuilder: (context, i) => _CourseTile(
                course: courses[i],
                onOpen: () => onOpenCourse(courses[i]),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CourseTile extends StatelessWidget {
  final Course course;
  final VoidCallback onOpen;
  const _CourseTile({required this.course, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final iconBg = Palette.primary.withOpacity(0.12);

    return InkWell(
      onTap: () {
        if (course.locked) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('أكمل المتطلبات لفتح هذا المحتوى')),
          );
        } else {
          onOpen();
        }
      },
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Palette.text,
                          ),
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
                  const SizedBox(height: 10),
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
                      Text(
                        course.locked ? 'مغلق' : 'متاح',
                        style: TextStyle(color: course.locked ? Colors.red : Colors.green),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        if (!course.locked) onOpen();
                      },
                      child: const Text('ابدأ / تابع'),
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

/* ======================= Shared Bits ======================= */

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Palette.text),
    );
  }
}

/* ======================= Error & Skeleton ======================= */

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Palette.subtitle),
            const SizedBox(height: 10),
            const Text('تعذر تحميل الصفحة. حاول مجددًا.', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}

class _SkeletonHome extends StatelessWidget {
  final bool isWide;
  const _SkeletonHome({required this.isWide});

  @override
  Widget build(BuildContext context) {
    Widget skel({double h = 16, double r = 10}) => Container(
          height: h,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.06),
            borderRadius: BorderRadius.circular(r),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Wrap(
            spacing: 28,
            runSpacing: 28,
            children: [
              SizedBox(
                width: isWide ? 440 : double.infinity,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          skel(h: 22),
                          const SizedBox(height: 12),
                          skel(h: 14),
                          const SizedBox(height: 12),
                          skel(h: 14),
                          const SizedBox(height: 16),
                          skel(h: 42, r: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(height: 110, decoration: _box()),
                    const SizedBox(height: 24),
                    Container(height: 220, decoration: _box()),
                  ],
                ),
              ),
              SizedBox(
                width: isWide ? (1400 - 440 - 28) : double.infinity,
                child: Container(height: 420, decoration: _box()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
      );
}
