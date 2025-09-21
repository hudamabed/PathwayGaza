import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';
import '../common/site_app_bar.dart';                 // ✅ shared app bar
import '../landing/footer_section.dart';             // ✅ your existing footer

class CoursePage extends StatelessWidget {
  final String courseTitle;
  final String gradeLabel;

  const CoursePage({
    super.key,
    this.courseTitle = 'الرياضيات',
    this.gradeLabel = 'الصف التاسع',
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          backgroundColor: Palette.pageBackground,

          // ✅ Replace the local app bar with the shared one
          appBar: SiteAppBar(
            isArabic: true,
            showAuthButtons: false,  // course screen usually doesn’t need auth buttons
            actions: const [],       // you can pass extra actions if you like
            centerTitle: const Text(
              'الصفحة الرئيسية',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800),
            ),
          ),

          body: Column(
            children: [
              _CourseBanner(title: courseTitle, subtitle: gradeLabel),
              _TopTabs(),
              const Divider(height: 1, thickness: 1, color: Color(0x144A90E2)),
              const Expanded(
                child: TabBarView(
                  children: [
                    _HomeTab(),
                    _SyllabusTab(),
                    _MembersTab(),
                    _GradesTab(),
                  ],
                ),
              ),

              // ✅ Use the same footer you already have in landing
              const FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------- Banner ----------------------- */

class _CourseBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  const _CourseBanner({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
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
      child: TabBar(
        labelColor: Colors.black87,
        unselectedLabelColor: Colors.black87,
        indicatorColor: Colors.black87,
        indicatorWeight: 2.2,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
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
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final items = <_EventItem>[
      _EventItem.header('عام'),
      _EventItem.banner('الإعلانات', Icons.chat_bubble_outline_rounded),
      _EventItem.period('1 أيلول - 7 أيلول', children: const [
        'اختبار قصير',
      ], trailing: Icons.edit_note_rounded),
      _EventItem.period('8 أيلول - 14 أيلول', children: const [
        'حصة زوم',
      ], trailing: Icons.videocam_rounded),
      _EventItem.period('15 أيلول - 21 أيلول'),
      _EventItem.period('21 أيلول - 28 أيلول'),
      _EventItem.period('29 أيلول - 5 تشرين أول'),
      _EventItem.period('6 تشرين أول - 13 تشرين أول'),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => items[i].build(context),
    );
  }
}

/* ----------------------- Tab: المادة ----------------------- */

class _SyllabusTab extends StatelessWidget {
  const _SyllabusTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _SectionTitle('وصف المادة'),
        SizedBox(height: 8),
        Text(
          'هذا تبويب المادة — يمكن إضافة الخطة الدراسية، المراجع، وسياسات المادة هنا.',
          style: TextStyle(color: Palette.subtitle),
        ),
      ],
    );
  }
}

/* ----------------------- Tab: الأعضاء ----------------------- */

class _MembersTab extends StatelessWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context) {
    final members = [
      ('المعلم المشرف', Icons.person_pin_rounded),
      ('أحمد محمد', Icons.person_rounded),
      ('سارة علي', Icons.person_rounded),
      ('محمود خليل', Icons.person_rounded),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, i) {
        final (name, icon) = members[i];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Palette.primary.withOpacity(.15),
              child: Icon(icon, color: Palette.primary),
            ),
            title: Text(name),
          ),
        );
      },
    );
  }
}

/* ----------------------- Tab: العلامات ----------------------- */

class _GradesTab extends StatelessWidget {
  const _GradesTab();

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('اختبار 1', '10/8'),
      ('وظيفة 1', '10/10'),
      ('مشروع صغير', '20/18'),
      ('اختبار نهائي', '50/44'),
    ];

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
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Palette.primary.withOpacity(.18)),
          columns: const [
            DataColumn(label: Text('البند', style: TextStyle(fontWeight: FontWeight.w800))),
            DataColumn(label: Text('العلامة', style: TextStyle(fontWeight: FontWeight.w800))),
          ],
          rows: rows
              .map(
                (r) => DataRow(cells: [
                  DataCell(Text(r.$1)),
                  DataCell(Text(r.$2)),
                ]),
              )
              .toList(),
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
                    children: const [
                      Icon(Icons.circle, size: 8, color: Palette.subtitle),
                      SizedBox(width: 8),
                    ],
                  ),
                ))
            .toList()
          ..asMap().forEach((i, _) {}),
      ),
    );
  }
}
