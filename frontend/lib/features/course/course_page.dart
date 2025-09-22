// lib/features/course/course_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../common/site_app_bar.dart';
import '../landing/footer_section.dart';
import '../../main.dart' show AppRoutes, CourseContentArgs, CourseGradesArgs;

/* ======================= Data & Repository ======================= */

class CourseMember {
  final String name;
  final bool isTeacher;
  const CourseMember({required this.name, this.isTeacher = false});
}

class GradeRow {
  final String item;
  final String mark; // e.g. "10/8"
  const GradeRow(this.item, this.mark);
}

class CourseOverview {
  final String id;
  final String title;
  final String gradeLabel;
  final String description;
  final List<({String period, IconData? trailing, List<String> items})> schedule;  final List<String> syllabus;
  final List<CourseMember> members;
  final List<GradeRow> grades;

  const CourseOverview({
    required this.id,
    required this.title,
    required this.gradeLabel,
    required this.description,
    required this.schedule,
    required this.syllabus,
    required this.members,
    required this.grades,
  });

  CourseOverview copyWith({
    String? title,
    String? gradeLabel,
    String? description,
    List<({String period, IconData? trailing, List<String> items})>? schedule,
    List<String>? syllabus,
    List<CourseMember>? members,
    List<GradeRow>? grades,
  }) {
    return CourseOverview(
      id: id,
      title: title ?? this.title,
      gradeLabel: gradeLabel ?? this.gradeLabel,
      description: description ?? this.description,
      schedule: schedule ?? this.schedule,
      syllabus: syllabus ?? this.syllabus,
      members: members ?? this.members,
      grades: grades ?? this.grades,
    );
    }
}

/// Contract for backend
abstract class CourseRepository {
  Future<CourseOverview> fetchCourse(String courseId);
}

/// Working fake so the page is fully functional today.
/// Swap with a real API implementation later.
class FakeCourseRepository implements CourseRepository {
  @override
  Future<CourseOverview> fetchCourse(String courseId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return CourseOverview(
      id: courseId,
      title: 'الرياضيات',
      gradeLabel: 'الصف التاسع',
      description:
          'هذه صفحة المساق. هنا ستجد الوصف المختصر والخطة الدراسية والأعضاء والدرجات.',
      schedule: const [
  (period: '1 أيلول - 7 أيلول', trailing: Icons.edit_note_rounded, items: ['اختبار قصير']),
  (period: '8 أيلول - 14 أيلول', trailing: Icons.videocam_rounded, items: ['حصة زوم']),
  (period: '15 أيلول - 21 أيلول', trailing: null, items: []),
  (period: '21 أيلول - 28 أيلول', trailing: null, items: []),
  (period: '29 أيلول - 5 تشرين أول', trailing: null, items: []),
  (period: '6 تشرين أول - 13 تشرين أول', trailing: null, items: []),
],

      syllabus: const [
        'تعريف بالأعداد الصحيحة والكسور',
        'الجمع والطرح والضرب والقسمة',
        'المعادلات الخطية البسيطة',
        'الهندسة: المحيط والمساحة',
        'الجذور التربيعية والتقدير',
      ],
      members: const [
        CourseMember(name: 'المعلم المشرف', isTeacher: true),
        CourseMember(name: 'أحمد محمد'),
        CourseMember(name: 'سارة علي'),
        CourseMember(name: 'محمود خليل'),
      ],
      grades: const [
        GradeRow('اختبار 1', '10/8'),
        GradeRow('وظيفة 1', '10/10'),
        GradeRow('مشروع صغير', '20/18'),
        GradeRow('اختبار نهائي', '50/44'),
      ],
    );
  }
}

/* ======================= Course Page ======================= */

class CoursePage extends StatefulWidget {
  final String courseTitle;
  final String gradeLabel;
  final String courseId; // important for backend lookups
  final CourseRepository? repository;

  const CoursePage({
    super.key,
    this.courseTitle = 'الرياضيات',
    this.gradeLabel = 'الصف التاسع',
    this.courseId = 'demo-math-g9',
    this.repository,
  });

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  late final CourseRepository _repo = widget.repository ?? FakeCourseRepository();
  late Future<CourseOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchCourse(widget.courseId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.fetchCourse(widget.courseId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 4,
        child: FutureBuilder<CourseOverview>(
          future: _future,
          builder: (context, snap) {
            final isLoading = snap.connectionState == ConnectionState.waiting && !snap.hasData;
            final hasError = snap.hasError;
            final data = snap.data;

            return Scaffold(
              backgroundColor: Palette.pageBackground,
              appBar: SiteAppBar(
                isArabic: true,
                showAuthButtons: false,
                actions: const [],
                centerTitle: const Text(
                  'الصفحة الرئيسية',
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
                ),
              ),
              body: hasError
                  ? _ErrorState(onRetry: _refresh)
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: Column(
                        children: [
                          if (isLoading && data == null)
                            const _BannerSkeleton()
                          else
                            _CourseBanner(
                              title: data?.title ?? widget.courseTitle,
                              subtitle: data?.gradeLabel ?? widget.gradeLabel,
                              onStart: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.courseContent,
                                  arguments: CourseContentArgs(
                                    courseId: widget.courseId,
                                    courseTitle: data?.title ?? widget.courseTitle,
                                    gradeLabel: data?.gradeLabel ?? widget.gradeLabel,
                                  ),
                                );
                              },
                              onGrades: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.grades,
                                  arguments: CourseGradesArgs(
                                    courseId: widget.courseId,
                                    courseTitle: data?.title ?? widget.courseTitle,
                                    gradeLabel: data?.gradeLabel ?? widget.gradeLabel,
                                  ),
                                );
                              },
                            ),
                          _TopTabs(),
                          const Divider(height: 1, thickness: 1, color: Color(0x144A90E2)),
                          Expanded(
                            child: isLoading && data == null
                                ? const _TabsSkeleton()
                                : TabBarView(
                                    children: [
                                      _HomeTab(schedule: data!.schedule),
                                      _SyllabusTab(description: data.description, syllabus: data.syllabus),
                                      _MembersTab(members: data.members),
                                      _GradesTab(rows: data.grades),
                                    ],
                                  ),
                          ),
                          const FooterSection(),
                        ],
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

/* ----------------------- Banner ----------------------- */

class _CourseBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onStart;
  final VoidCallback? onGrades;

  const _CourseBanner({
    required this.title,
    required this.subtitle,
    this.onStart,
    this.onGrades,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Palette.primary,
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Palette.primary.withOpacity(.95),
            Palette.primary.withOpacity(.70),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.calculate_rounded, size: 48, color: Colors.black87),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text('ابدأ / تابع'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: onGrades,
                        icon: const Icon(Icons.assessment_rounded, size: 18),
                        label: const Text('العلامات'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Colors.black87),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
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

/* ----------------------- Tabs ----------------------- */

class _TopTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.primary,
      child: const TabBar(
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.black87,
        indicatorColor: Colors.black87,
        indicatorWeight: 2.2,
        labelStyle: TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'الرئيسية'),
          Tab(text: 'المادة'),
          Tab(text: 'الأعضاء'),
          Tab(text: 'العلامات'),
        ],
      ),
    );
  }
}

/* ----------------------- Tab: الرئيسية ----------------------- */

class _HomeTab extends StatelessWidget {
  final List<({String period, IconData? trailing, List<String> items})> schedule;
  const _HomeTab({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final items = <_EventItem>[
      _EventItem.header('عام'),
      _EventItem.banner('الإعلانات', Icons.chat_bubble_outline_rounded),
      ...schedule.map((e) => _EventItem.period(e.period, trailing: e.trailing, children: e.items)),
    ];

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => items[i].build(context),
    );
  }
}

/* ----------------------- Tab: المادة ----------------------- */

class _SyllabusTab extends StatelessWidget {
  final String description;
  final List<String> syllabus;
  const _SyllabusTab({required this.description, required this.syllabus});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle('وصف المادة'),
        const SizedBox(height: 8),
        Text(
          description,
          style: const TextStyle(color: Palette.subtitle),
        ),
        const SizedBox(height: 18),
        const _SectionTitle('الخطة الدراسية'),
        const SizedBox(height: 8),
        ...syllabus.map((s) => Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Palette.primary.withOpacity(.15),
                  child: const Icon(Icons.menu_book_rounded, color: Palette.primary),
                ),
                title: Text(s),
              ),
            )),
        const SizedBox(height: 12),
      ],
    );
  }
}

/* ----------------------- Tab: الأعضاء ----------------------- */

class _MembersTab extends StatelessWidget {
  final List<CourseMember> members;
  const _MembersTab({required this.members});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, i) {
        final m = members[i];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Palette.primary.withOpacity(.15),
              child: Icon(m.isTeacher ? Icons.person_pin_rounded : Icons.person_rounded,
                  color: Palette.primary),
            ),
            title: Text(m.name, style: TextStyle(fontWeight: m.isTeacher ? FontWeight.w800 : FontWeight.w600)),
            subtitle: m.isTeacher ? const Text('المعلم المشرف') : null,
          ),
        );
      },
    );
  }
}

/* ----------------------- Tab: العلامات ----------------------- */

class _GradesTab extends StatelessWidget {
  final List<GradeRow> rows;
  const _GradesTab({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal, // prevents overflow on small screens
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Palette.primary.withOpacity(.18)),
            columns: const [
              DataColumn(label: Text('البند', style: TextStyle(fontWeight: FontWeight.w800))),
              DataColumn(label: Text('العلامة', style: TextStyle(fontWeight: FontWeight.w800))),
            ],
            rows: rows
                .map((r) => DataRow(cells: [
                      DataCell(Text(r.item)),
                      DataCell(Text(r.mark)),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }
}

/* ----------------------- Small helpers & models ----------------------- */

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Palette.text),
    );
  }
}

class _EventItem {
  final _EventKind kind;
  final String title;
  final IconData? trailing;
  final List<String> children;

  _EventItem._(this.kind, this.title, this.trailing, this.children);

  factory _EventItem.header(String title) => _EventItem._(_EventKind.header, title, null, const []);
  factory _EventItem.banner(String title, IconData icon) =>
      _EventItem._(_EventKind.banner, title, icon, const []);
  factory _EventItem.period(String title, {IconData? trailing, List<String> children = const []}) =>
      _EventItem._(_EventKind.period, title, trailing, children);

  Widget build(BuildContext context) {
    switch (kind) {
      case _EventKind.header:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Palette.text)),
        );
      case _EventKind.banner:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
              Icon(trailing ?? Icons.chat_bubble_outline_rounded, color: Palette.primary),
            ],
          ),
        );
      case _EventKind.period:
        return _ExpandableTile(title: title, trailing: trailing, children: children);
    }
  }
}

enum _EventKind { header, banner, period }

class _ExpandableTile extends StatefulWidget {
  final String title;
  final IconData? trailing;
  final List<String> children;
  const _ExpandableTile({required this.title, this.trailing, required this.children});

  @override
  State<_ExpandableTile> createState() => _ExpandableTileState();
}

class _ExpandableTileState extends State<_ExpandableTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        onExpansionChanged: (v) => setState(() => _open = v),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.trailing != null)
              Icon(widget.trailing, color: Palette.primary, size: 20),
            const SizedBox(width: 8),
            Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
          ],
        ),
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        children: widget.children
            .map((c) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Palette.subtitle),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

/* ----------------------- Error & Skeleton ----------------------- */

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

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.06),
      ),
    );
  }
}

class _TabsSkeleton extends StatelessWidget {
  const _TabsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget skel({double h = 16, double r = 10}) => Container(
          height: h,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.06),
            borderRadius: BorderRadius.circular(r),
          ),
        );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              skel(h: 18),
              const SizedBox(height: 12),
              skel(),
              const SizedBox(height: 8),
              skel(),
            ],
          ),
        ),
      ),
    );
  }
}
