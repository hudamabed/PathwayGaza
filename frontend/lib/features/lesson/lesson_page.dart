// lib/features/lesson/lesson_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

class LessonPageArgs {
  final String courseId;
  final String lessonId;
  final String lessonTitle;
  const LessonPageArgs({
    required this.courseId,
    required this.lessonId,
    required this.lessonTitle,
  });
}

/// Backend contract for lesson content
abstract class LessonRepository {
  Future<LessonContent> fetch(String courseId, String lessonId);
}

/// Replace with real API later
class FakeLessonRepository implements LessonRepository {
  @override
  Future<LessonContent> fetch(String courseId, String lessonId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return LessonContent(
      html: '''
<h2>${_escape('عنوان الدرس')}</h2>
<p>هذا محتوى تجريبي للدرس. استبدله بنص/صور/روابط من الـ API.</p>
<ul>
  <li>نص وصور خفيفة</li>
  <li>روابط لمراجع أو فيديو خارجي (يفتح في تبويب جديد)</li>
</ul>
''',
      // keep a minimal text fallback for offline/AR screen readers
      plainText: 'هذا محتوى تجريبي للدرس…',
      attachments: const [],
    );
  }
}

class LessonContent {
  final String html;        // render with a webview/HTML widget later if needed
  final String plainText;   // safe fallback
  final List<Uri> attachments;
  const LessonContent({
    required this.html,
    required this.plainText,
    required this.attachments,
  });
}

class LessonPage extends StatefulWidget {
  final String courseId;
  final String lessonId;
  final String lessonTitle;
  final LessonRepository? repository;

  const LessonPage({
    super.key,
    required this.courseId,
    required this.lessonId,
    required this.lessonTitle,
    this.repository,
  });

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  late final LessonRepository _repo = widget.repository ?? FakeLessonRepository();
  late Future<LessonContent> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetch(widget.courseId, widget.lessonId);
  }

  Future<void> _refresh() async {
    setState(() => _future = _repo.fetch(widget.courseId, widget.lessonId));
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<LessonContent>(
        future: _future,
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting && !snap.hasData;
          final hasError = snap.hasError;
          final data = snap.data;

          return Scaffold(
            backgroundColor: Palette.pageBackground,
            appBar: AppBar(
              backgroundColor: Palette.primary,
              title: Text(widget.lessonTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: hasError
                ? _ErrorState(onRetry: _refresh)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: isLoading && data == null
                                ? const _Skeleton()
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Minimal safe renderer (plain text). Swap for an HTML renderer later.
                                      Text(
                                        data!.plainText,
                                        style: const TextStyle(height: 1.7, color: Palette.text),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: data.attachments.map((u) {
                                          return OutlinedButton.icon(
                                            onPressed: () {
                                              // In Flutter Web, use `launchUrl` (url_launcher) to open in new tab
                                              // TODO: implement url_launcher
                                            },
                                            icon: const Icon(Icons.link_rounded, size: 18),
                                            label: Text(u.toString(), overflow: TextOverflow.ellipsis),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: Palette.subtitle),
          const SizedBox(height: 10),
          const Text('تعذّر تحميل الدرس. حاول مجددًا.', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ]),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (_) => Container(
        height: 16,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.black.withOpacity(.06), borderRadius: BorderRadius.circular(8)),
      )),
    );
  }
}

// very small HTML escape for demo/placeholder
String _escape(String s) => s
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;');
