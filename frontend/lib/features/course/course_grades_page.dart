// lib/features/course/course_grades_page.dart
import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

/// =======================
/// Top-level helpers (visible to all widgets in this file)
/// =======================

String fmtNum(double? v) {
  if (v == null) return '-';
  return (v % 1 == 0) ? v.toInt().toString() : v.toStringAsFixed(1);
}

String fmtDate(DateTime? d) {
  if (d == null) return '-';
  return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

// Fixed width helper for headers/cells
Widget _w(double width, Widget child) => SizedBox(width: width, child: child);

/// =======================
/// Models (API-friendly)
/// =======================

class GradeItem {
  final String id;
  final String title;
  final String category; // e.g. "امتحان قصير", "امتحان شهرين", "واجب"
  final DateTime? date; // optional
  final double? score; // student's score (null => not graded yet)
  final double max; // maximum possible
  final double min; // minimum (often 0) – shown for transparency
  final double? weight; // optional: if you use weighted categories

  const GradeItem({
    required this.id,
    required this.title,
    required this.category,
    this.date,
    required this.max,
    this.min = 0,
    this.score,
    this.weight,
  });
}

/// =======================
/// Page
/// =======================

class CourseGradesPage extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String gradeLabel; // e.g. "الصف التاسع"
  final List<GradeItem> items;

  const CourseGradesPage({
    super.key,
    required this.courseId,
    this.courseTitle = 'الرياضيات',
    this.gradeLabel = 'الصف التاسع',
    this.items = const [],
  });

  @override
  State<CourseGradesPage> createState() => _CourseGradesPageState();
}

class _CourseGradesPageState extends State<CourseGradesPage> {
  // State: filters / search / sorting
  String _query = '';
  String? _category; // null = all
  _SortBy _sortBy = _SortBy.date;
  bool _sortAsc = false;

  late final List<GradeItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items.isNotEmpty ? widget.items : _demo();
  }

  @override
  Widget build(BuildContext context) {
    final categories = {
      for (final i in _items) i.category,
    }.toList()
      ..sort();

    // Filter + query
    final filtered = _items.where((i) {
      final cOk = _category == null || i.category == _category;
      final q = _query.trim();
      final qOk = q.isEmpty || i.title.contains(q) || i.category.contains(q);
      return cOk && qOk;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case _SortBy.date:
          cmp = (a.date ?? DateTime(2000)).compareTo(b.date ?? DateTime(2000));
          break;
        case _SortBy.title:
          cmp = a.title.compareTo(b.title);
          break;
        case _SortBy.category:
          cmp = a.category.compareTo(b.category);
          break;
        case _SortBy.score:
          cmp = (a.score ?? -1).compareTo(b.score ?? -1);
          break;
        case _SortBy.percent:
          cmp = _percent(a).compareTo(_percent(b));
          break;
      }
      return _sortAsc ? cmp : -cmp;
    });

    // Totals
    final totals = _totals(_items);
    final ftotals = _totals(filtered);
    final percent = totals.max > 0 ? totals.score / totals.max : 0.0;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Palette.pageBackground,
        appBar: _GradesAppBar(title: widget.courseTitle, grade: widget.gradeLabel),
        body: LayoutBuilder(builder: (context, c) {
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
                      percent: percent,
                      earned: totals.score,
                      outOf: totals.max,
                    ),
                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        // ------ Left column (stacks on small) ------
                        SizedBox(
                          width: isWide ? 420 : c.maxWidth,
                          child: Column(
                            children: [
                              _Card(
                                child: _SummaryCards(
                                  overallEarned: totals.score,
                                  overallMax: totals.max,
                                  filteredEarned: ftotals.score,
                                  filteredMax: ftotals.max,
                                  notGraded: _items.where((e) => e.score == null).length,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _Card(
                                child: _CategoryFilter(
                                  categories: categories,
                                  selected: _category,
                                  onChanged: (v) => setState(() => _category = v),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ------ Right column (table) ------
                        SizedBox(
                          width: isWide ? (1300 - 420 - 20) : c.maxWidth,
                          child: _Card(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                // Search + sort row
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      _SearchField(
                                        initialText: _query,
                                        onChanged: (t) => setState(() => _query = t),
                                      ),
                                      const SizedBox(height: 10),
                                      _SortRow(
                                        sortBy: _sortBy,
                                        asc: _sortAsc,
                                        onChanged: (by) => setState(() {
                                          _sortAsc = by == _sortBy ? !_sortAsc : true;
                                          _sortBy = by;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1, color: Color(0x14555555)),

                                // Data table (scrolls horizontally on small screens)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      Palette.primary.withValues(alpha: 0.12),
                                    ),
                                    columnSpacing: 12,      // tighter spacing
                                    horizontalMargin: 10,
                                    dataRowMinHeight: 48,
                                    dataRowMaxHeight: 64,
                                    // ── Fixed widths per column (adjust as you like)
                                    // date 110, title 260, category 160, score 90, max 90, min 90, percent 140, weight 90
                                    columns: [
                                      DataColumn(label: _w(110, _Header(label: 'التاريخ', onTap: () => _setSort(_SortBy.date)))),
                                      DataColumn(label: _w(260, _Header(label: 'البند', onTap: () => _setSort(_SortBy.title)))),
                                      DataColumn(label: _w(160, _Header(label: 'التصنيف', onTap: () => _setSort(_SortBy.category)))),
                                      DataColumn(label: _w(90,  _Header(label: 'علامتي', onTap: () => _setSort(_SortBy.score)))),
                                      DataColumn(label: _w(90,  _Header(label: 'العظمى'))),
                                      DataColumn(label: _w(90,  _Header(label: 'الصغرى'))),
                                      DataColumn(label: _w(140, _Header(label: 'النسبة', onTap: () => _setSort(_SortBy.percent)))),
                                      DataColumn(label: _w(90,  _Header(label: 'الوزن'))),
                                    ],
                                    rows: filtered.map((e) {
                                      final p = _percent(e);
                                      return DataRow(
                                        cells: [
                                          DataCell(_w(110, Text(fmtDate(e.date)))),
                                          DataCell(_w(260, Text(
                                            e.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ))),
                                          DataCell(_w(160, _CategoryPill(text: e.category))),
                                          DataCell(_w(90,  Text(fmtNum(e.score)))),
                                          DataCell(_w(90,  Text(fmtNum(e.max)))),
                                          DataCell(_w(90,  Text(fmtNum(e.min)))),
                                          DataCell(_w(140, _PercentCell(value: p))), // adaptive & overflow-proof
                                          DataCell(_w(90,  Text(e.weight == null ? '-' : fmtNum(e.weight)))),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),

                                // filtered total
                                Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Text(
                                    'المجموع (المعروض): ${fmtNum(ftotals.score)} / ${fmtNum(ftotals.max)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Palette.text,
                                    ),
                                  ),
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
        }),
      ),
    );
  }

  // ===== Helpers inside State =====

  void _setSort(_SortBy by) => setState(() {
        _sortAsc = by == _sortBy ? !_sortAsc : true;
        _sortBy = by;
      });

  ({double score, double max}) _totals(List<GradeItem> list) {
    double score = 0, max = 0;
    for (final i in list) {
      if (i.score != null) score += i.score!;
      max += i.max;
    }
    return (score: score, max: max);
  }

  double _percent(GradeItem i) =>
      (i.score == null || i.max <= 0) ? 0.0 : (i.score! / i.max).clamp(0, 1);

  // -------- Demo data (replace with API) --------
  List<GradeItem> _demo() => [
        GradeItem(
          id: 'g1',
          title: 'امتحان قصير 1',
          category: 'امتحان قصير',
          date: DateTime.now().subtract(const Duration(days: 25)),
          score: 8,
          max: 10,
          min: 5,
        ),
        GradeItem(
          id: 'g2',
          title: 'امتحان شهرين',
          category: 'امتحان شهرين',
          date: DateTime.now().subtract(const Duration(days: 10)),
          score: 26,
          max: 30,
          min: 15,
          weight: 2,
        ),
        GradeItem(
          id: 'g3',
          title: 'امتحان قصير 2',
          category: 'امتحان قصير',
          date: DateTime.now().subtract(const Duration(days: 4)),
          score: null, // not graded yet
          max: 10,
          min: 0,
        ),
        GradeItem(
          id: 'g4',
          title: 'واجب بيتـي',
          category: 'واجب',
          date: DateTime.now().subtract(const Duration(days: 2)),
          score: 5,
          max: 5,
          min: 0,
        ),
      ];
}

/// =======================
/// AppBar
/// =======================

class _GradesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String grade;
  const _GradesAppBar({required this.title, required this.grade});

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
          const Icon(Icons.assessment_rounded, color: Colors.white),
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

/// =======================
/// Banner
/// =======================

class _BannerHeader extends StatelessWidget {
  final String title;
  final String grade;
  final double percent;
  final double earned;
  final double outOf;

  const _BannerHeader({
    required this.title,
    required this.grade,
    required this.percent,
    required this.earned,
    required this.outOf,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (percent * 100).round();
    return Container(
      height: 126,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [
            Palette.primary.withValues(alpha: 0.95),
            Palette.primary.withValues(alpha: 0.70),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.grade_rounded, size: 48, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  grade,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$pct%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'المجموع: ${fmtNum(earned)} / ${fmtNum(outOf)}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Left-column widgets
/// =======================

class _SummaryCards extends StatelessWidget {
  final double overallEarned, overallMax;
  final double filteredEarned, filteredMax;
  final int notGraded;

  const _SummaryCards({
    required this.overallEarned,
    required this.overallMax,
    required this.filteredEarned,
    required this.filteredMax,
    required this.notGraded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MetricTile(
          icon: Icons.summarize_rounded,
          title: 'إجمالي العلامات',
          value: '${fmtNum(overallEarned)} / ${fmtNum(overallMax)}',
        ),
        const SizedBox(height: 10),
        _MetricTile(
          icon: Icons.filter_alt_rounded,
          title: 'مجموع العناصر المعروضة',
          value: '${fmtNum(filteredEarned)} / ${fmtNum(filteredMax)}',
        ),
        const SizedBox(height: 10),
        _MetricTile(
          icon: Icons.hourglass_bottom_rounded,
          title: 'بانتظار التصحيح',
          value: '$notGraded',
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _MetricTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: Palette.primary.withValues(alpha: 0.12),
            child: Icon(icon, size: 18, color: Palette.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chips = ['الكل', ...categories];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('التصنيفات', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in chips)
              ChoiceChip(
                label: Text(c),
                selected: selected == null ? c == 'الكل' : c == selected,
                onSelected: (_) => onChanged(c == 'الكل' ? null : c),
                selectedColor: Palette.primary.withValues(alpha: 0.18),
                side: const BorderSide(color: Color(0x22555555)),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  fontWeight:
                      (selected == null && c == 'الكل') || selected == c ? FontWeight.w800 : FontWeight.w600,
                  color: Palette.text,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
          ],
        ),
      ],
    );
  }
}

/// =======================
/// Table helpers
/// =======================

enum _SortBy { date, title, category, score, percent }

class _SortRow extends StatelessWidget {
  final _SortBy sortBy;
  final bool asc;
  final ValueChanged<_SortBy> onChanged;

  const _SortRow({required this.sortBy, required this.asc, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget btn(String label, _SortBy by, IconData icon) => OutlinedButton.icon(
          onPressed: () => onChanged(by),
          icon: Icon(icon, size: 18),
          label: Text(
            label + (sortBy == by ? (asc ? ' ↑' : ' ↓') : ''),
            style: TextStyle(fontWeight: sortBy == by ? FontWeight.w800 : FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            side: const BorderSide(color: Color(0x22555555)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        btn('التاريخ', _SortBy.date, Icons.calendar_today_rounded),
        btn('العنوان', _SortBy.title, Icons.sort_by_alpha_rounded),
        btn('التصنيف', _SortBy.category, Icons.category_rounded),
        btn('العلامة', _SortBy.score, Icons.numbers_rounded),
        btn('النسبة', _SortBy.percent, Icons.percent_rounded),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _Header({required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

DataColumn _col(String label, {VoidCallback? onTap}) => DataColumn(
      label: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );

class _CategoryPill extends StatelessWidget {
  final String text;
  const _CategoryPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Adaptive, overflow-proof percent cell
class _PercentCell extends StatelessWidget {
  final double value; // 0..1
  const _PercentCell({required this.value});

  @override
  Widget build(BuildContext context) {
    final pctText = '${(value * 100).round()}%';

    return LayoutBuilder(
      builder: (context, box) {
        // If too narrow, show text only to avoid any chance of overflow.
        if (box.maxWidth < 70) {
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(pctText, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          );
        }

        // Otherwise, show progress with overlaid text (no Row involved).
        return SizedBox(
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 18,
                  color: Palette.primary,
                  backgroundColor: Palette.primary.withValues(alpha: 0.15),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(pctText, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// =======================
/// Reusable small bits
/// =======================

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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SearchField extends StatelessWidget {
  final String initialText;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.initialText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: initialText)
      ..selection = TextSelection.collapsed(offset: initialText.length);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'ابحث في العلامات…',
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
        children: const [
          Text('© Palestine Learning',
              style: TextStyle(color: Palette.subtitle, fontSize: 12)),
          Spacer(),
          Icon(Icons.facebook_rounded, size: 18, color: Colors.black87),
          SizedBox(width: 8),
          Icon(Icons.camera_alt_rounded, size: 18, color: Colors.black87),
          SizedBox(width: 8),
          Icon(Icons.link_rounded, size: 18, color: Colors.black87),
        ],
      ),
    );
  }
}
