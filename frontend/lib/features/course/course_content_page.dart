import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

/// =====================
/// Models (simple & API-friendly)
/// =====================

enum LessonType { video, reading, quiz, live }
enum LessonStatus { notStarted, inProgress, completed }

class Lesson {
  final String id;
  final String title;
  final LessonType type;
  final LessonStatus status;
  final Duration? duration; // null for things like live sessions

  const Lesson({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    this.duration,
  });
}

class ContentUnit {
  final String id;
  final String title;
  final List<Lesson> lessons;

  const ContentUnit({
    required this.id,
    required this.title,
    required this.lessons,
  });
}

/// =====================
/// Page
/// Pass real data via [units]. A demo seed is used if empty.
/// =====================
class CourseContentPage extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String gradeLabel; // e.g. "الصف التاسع"
  final String overview;   // short "what you'll learn"
  final List<ContentUnit> units;

  const CourseContentPage({
    super.key,
    required this.courseId,
    this.courseTitle = 'الرياضيات',
    this.gradeLabel = 'الصف التاسع',
    this.overview =
        'في هذه المادة سنتعرف على مفاهيم ومهارات متنوعة: الأعداد الحقيقية،'
        ' العلاقات والدوال، الهندسة والقياس، إضافةً إلى الإحصاء والاحتمالات.',
    this.units = const [],
  });

  @override
  State<CourseContentPage> createState() => _CourseContentPageState();
}

class _CourseContentPageState extends State<CourseContentPage> {
  LessonStatus? _statusFilter;
  String _query = '';
  late final List<ContentUnit> _units;

  @override
  void initState() {
    super.initState();
    _units = widget.units.isNotEmpty ? widget.units : _demoUnits();
  }

  @override
  Widget build(BuildContext context) {
    // overall progress
    final allLessons = _units.expand((u) => u.lessons).toList();
    final done = allLessons.where((l) => l.status == LessonStatus.completed).length;
    final percent = allLessons.isEmpty ? 0.0 : done / allLessons.length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Palette.pageBackground,
        appBar: _CourseBar(title: widget.courseTitle, grade: widget.gradeLabel),
        body: LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 1100;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1300),
                  child: Column(
                    children: [
                      _BannerHeader(
                        title: widget.courseTitle,
                        grade: widget.gradeLabel,
                        progress: percent,
                        completedCount: done,
                        totalCount: allLessons.length,
                      ),
                      const SizedBox(height: 20),

                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          // ---------- Column A ----------
                          SizedBox(
                            width: isWide ? 420 : c.maxWidth,
                            child: Column(
                              children: [
                                _Card(child: _Overview(overview: widget.overview)),
                                const SizedBox(height: 20),
                                _Card(
                                  child: _StatsBlock(
                                    total: allLessons.length,
                                    completed: done,
                                    inProgress: allLessons
                                        .where((e) => e.status == LessonStatus.inProgress)
                                        .length,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ---------- Column B ----------
                          SizedBox(
                            width: isWide ? (1300 - 420 - 20) : c.maxWidth,
                            child: _Card(
                              padding: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // header + search + filter
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('المحتويات',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: Palette.text,
                                                )),
                                            const Spacer(),
                                            _StatusFilter(
                                              value: _statusFilter,
                                              onChanged: (v) => setState(() => _statusFilter = v),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _SearchField(
                                          initialText: _query,
                                          onChanged: (txt) =>
                                              setState(() => _query = txt.trim()),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0x14555555)),

                                  // Units
                                  if (_units.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(18),
                                      child: Center(
                                        child: Text('لا يوجد محتوى بعد.',
                                            style: TextStyle(color: Palette.subtitle)),
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                                      itemCount: _units.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                                      itemBuilder: (context, i) {
                                        final unit = _units[i];
                                        return _UnitTile(
                                          unit: unit,
                                          initiallyExpanded: i == 0,
                                          filter: _statusFilter,
                                          query: _query,
                                          onTapLesson: (lesson) {
                                            // TODO: Navigate to lesson page using lesson.id
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('فتح: ${lesson.title}')),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const _SmallFooter(),
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

  // -------- demo seed (replace with real API data) --------
  List<ContentUnit> _demoUnits() => const [
        ContentUnit(
          id: 'u1',
          title: 'الوحدة الأولى: الأعداد الحقيقية',
          lessons: [
            Lesson(
              id: 'l1',
              title: 'الدرس الأول: الأعداد الصحيحة',
              type: LessonType.reading,
              status: LessonStatus.completed,
              duration: Duration(minutes: 15),
            ),
            Lesson(
              id: 'l2',
              title: 'الدرس الثاني: الأعداد الكسرية',
              type: LessonType.video,
              status: LessonStatus.inProgress,
              duration: Duration(minutes: 18),
            ),
            Lesson(
              id: 'l3',
              title: 'الدرس الثالث: الأعداد العشرية',
              type: LessonType.reading,
              status: LessonStatus.notStarted,
              duration: Duration(minutes: 12),
            ),
            Lesson(
              id: 'l4',
              title: 'اختبار قصير',
              type: LessonType.quiz,
              status: LessonStatus.notStarted,
              duration: Duration(minutes: 8),
            ),
          ],
        ),
        ContentUnit(
          id: 'u2',
          title: 'الوحدة الثانية: العلاقات والاقترانات',
          lessons: [
            Lesson(
              id: 'l5',
              title: 'مفهوم العلاقة',
              type: LessonType.video,
              status: LessonStatus.notStarted,
              duration: Duration(minutes: 14),
            ),
            Lesson(
              id: 'l6',
              title: 'تمثيل الدوال',
              type: LessonType.reading,
              status: LessonStatus.notStarted,
              duration: Duration(minutes: 16),
            ),
          ],
        ),
        ContentUnit(
          id: 'u3',
          title: 'الوحدة الثالثة: الهندسة والقياس',
          lessons: [
            Lesson(
              id: 'l7',
              title: 'المحيط والمساحة',
              type: LessonType.video,
              status: LessonStatus.completed,
              duration: Duration(minutes: 20),
            ),
            Lesson(
              id: 'l8',
              title: 'زوايا ومضلعات',
              type: LessonType.reading,
              status: LessonStatus.inProgress,
              duration: Duration(minutes: 17),
            ),
          ],
        ),
      ];
}

/// =====================
/// Top Bar
/// =====================
class _CourseBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String grade;
  const _CourseBar({required this.title, required this.grade});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Palette.primary,
      elevation: 0,
      centerTitle: true,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_rounded, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$title • $grade',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      leading: IconButton(
        tooltip: 'رجوع',
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

/// =====================
/// Banner
/// =====================
class _BannerHeader extends StatelessWidget {
  final String title;
  final String grade;
  final double progress;
  final int completedCount;
  final int totalCount;

  const _BannerHeader({
    required this.title,
    required this.grade,
    required this.progress,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final percentText = '${(progress * 100).round()}%';
    return Container(
      height: 126,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Palette.primary.withOpacity(.95), Palette.primary.withOpacity(.7)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.calculate_rounded, size: 48, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 4),
                Text(grade,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.92),
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          color: Colors.white,
                          backgroundColor: Colors.white.withOpacity(.35),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(percentText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text('الدروس المكتملة: $completedCount / $totalCount',
                    style: TextStyle(color: Colors.white.withOpacity(.9), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================
/// Overview
/// =====================
class _Overview extends StatelessWidget {
  final String overview;
  const _Overview({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CardTitle('ماذا سوف نتعلم'),
        const SizedBox(height: 8),
        Text(
          overview,
          style: const TextStyle(color: Palette.subtitle, height: 1.65),
        ),
      ],
    );
  }
}

/// =====================
/// Stats
/// =====================
class _StatsBlock extends StatelessWidget {
  final int total;
  final int completed;
  final int inProgress;

  const _StatsBlock({
    required this.total,
    required this.completed,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatBox(label: 'الدروس', value: '$total', icon: Icons.list_alt_rounded),
      _StatBox(
        label: 'مكتملة',
        value: '$completed',
        icon: Icons.check_circle_rounded,
        tint: Colors.green,
      ),
      _StatBox(
        label: 'قيد التقدم',
        value: '$inProgress',
        icon: Icons.play_circle_fill_rounded,
        tint: Palette.primary,
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? tint;
  const _StatBox({required this.label, required this.value, required this.icon, this.tint});

  @override
  Widget build(BuildContext context) {
    final color = tint ?? Palette.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(.12),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Palette.subtitle)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================
/// Search + Filter
/// =====================
class _SearchField extends StatelessWidget {
  final String initialText;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.initialText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: initialText)
        ..selection = TextSelection.collapsed(offset: initialText.length),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث عن درس…',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: const Color(0xFFF6F8FC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x11000000)),
        ),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final LessonStatus? value;
  final ValueChanged<LessonStatus?> onChanged;

  const _StatusFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chips = <(String, LessonStatus?)>[
      ('الكل', null),
      ('غير مكتمل', LessonStatus.notStarted),
      ('قيد التقدم', LessonStatus.inProgress),
      ('مكتمل', LessonStatus.completed),
    ];

    return Wrap(
      spacing: 6,
      children: [
        for (final (label, v) in chips)
          ChoiceChip(
            label: Text(label),
            selected: value == v,
            onSelected: (_) => onChanged(v),
            selectedColor: Palette.primary.withOpacity(.18),
            labelStyle: TextStyle(
              fontWeight: value == v ? FontWeight.w800 : FontWeight.w600,
              color: Palette.text,
            ),
            side: const BorderSide(color: Color(0x22555555)),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
      ],
    );
  }
}

/// =====================
/// Units / Lessons
/// =====================
class _UnitTile extends StatefulWidget {
  final ContentUnit unit;
  final LessonStatus? filter;
  final String query;
  final ValueChanged<Lesson> onTapLesson;
  final bool initiallyExpanded;

  const _UnitTile({
    required this.unit,
    required this.filter,
    required this.query,
    required this.onTapLesson,
    this.initiallyExpanded = false,
  });

  @override
  State<_UnitTile> createState() => _UnitTileState();
}

class _UnitTileState extends State<_UnitTile> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    // filter + search
    final filtered = widget.unit.lessons.where((l) {
      final statusOk = widget.filter == null || l.status == widget.filter;
      final queryOk = widget.query.isEmpty || l.title.contains(widget.query);
      return statusOk && queryOk;
    }).toList();

    // unit progress
    final total = widget.unit.lessons.length;
    final done = widget.unit.lessons.where((l) => l.status == LessonStatus.completed).length;
    final p = total == 0 ? 0.0 : done / total;

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
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (v) => setState(() => _open = v),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        trailing: Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.unit.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 8,
                color: Palette.primary,
                backgroundColor: Palette.primary.withOpacity(.15),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('مكتملة: $done / $total',
                    style: const TextStyle(fontSize: 12, color: Palette.subtitle)),
              ],
            ),
          ],
        ),
        children: [
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('لا يوجد عناصر مطابقة.', style: TextStyle(color: Palette.subtitle)),
            )
          else
            ...filtered.map(
              (l) => _LessonRow(
                lesson: l,
                onTap: () => widget.onTapLesson(l),
              ),
            ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final VoidCallback onTap;
  const _LessonRow({required this.lesson, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (chipText, chipColor) = switch (lesson.status) {
      LessonStatus.completed => ('منتهي', Colors.green),
      LessonStatus.inProgress => ('تابع', Palette.primary),
      LessonStatus.notStarted => ('ابدأ', Colors.orange),
    };

    final icon = switch (lesson.type) {
      LessonType.video => Icons.play_circle_fill_rounded,
      LessonType.reading => Icons.menu_book_rounded,
      LessonType.quiz => Icons.edit_note_rounded,
      LessonType.live => Icons.videocam_rounded,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x11000000)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Palette.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                lesson.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (lesson.duration != null) ...[
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: Palette.subtitle),
                  const SizedBox(width: 4),
                  Text('${lesson.duration!.inMinutes} دقيقة',
                      style: const TextStyle(fontSize: 12, color: Palette.subtitle)),
                ],
              ),
            ],
            const SizedBox(width: 12),
            _StatusChip(text: chipText, color: chipColor, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

/// =====================
/// Small bits
/// =====================
class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Palette.text),
    );
  }
}

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
            color: Colors.black.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({required this.text, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.chevron_left_rounded), // inward arrow in RTL
      label: Text(text),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Compact footer
class _SmallFooter extends StatelessWidget {
  const _SmallFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Row(
        children: [
          const Text('تابعنا:', style: TextStyle(fontWeight: FontWeight.w800, color: Palette.text)),
          const SizedBox(width: 8),
          _iconButton(Icons.facebook_rounded, const Color(0xFF1877F2)),
          _iconButton(Icons.camera_alt_rounded, null),
          _iconButton(Icons.link_rounded, null),
          const Spacer(),
          const Text('© Palestine Learning', style: TextStyle(color: Palette.subtitle, fontSize: 12)),
        ],
      ),
    );
  }

  static Widget _iconButton(IconData icon, Color? color) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 6),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: (color ?? Colors.black87).withOpacity(.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color ?? Colors.black87),
        ),
      );
}
