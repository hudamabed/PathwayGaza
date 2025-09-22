// lib/features/lesson/quiz_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/palette.dart';

/* =======================
   Route Args
   ======================= */

class QuizPageArgs {
  final String courseId;
  final String quizId;
  final String quizTitle;
  const QuizPageArgs({
    required this.courseId,
    required this.quizId,
    required this.quizTitle,
  });
}

/* =======================
   Models (API-friendly)
   ======================= */

enum QuestionType { single, multiple, trueFalse }

class Choice {
  final String id;
  final String text;

  // NOTE: in a real API you won't expose correctness to the client.
  // We keep it here only for the Fake repo to compute a local score.
  final bool _isCorrect;

  const Choice({required this.id, required this.text, bool isCorrect = false})
      : _isCorrect = isCorrect;

  bool get isCorrect => _isCorrect;
}

class QuizQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final List<Choice> choices;
  final double points;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.choices,
    this.points = 1.0,
  });
}

class Quiz {
  final String id;
  final String title;
  final Duration? duration; // null => untimed
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    required this.title,
    required this.questions,
    this.duration,
  });
}

class QuizResult {
  final double score;
  final double max;
  final int correctCount;
  final int totalCount;

  const QuizResult({
    required this.score,
    required this.max,
    required this.correctCount,
    required this.totalCount,
  });

  double get percent => max <= 0 ? 0 : (score / max).clamp(0, 1);
}

/* =======================
   Repository contract
   ======================= */

abstract class QuizRepository {
  Future<Quiz> fetch(String courseId, String quizId);

  /// Submit student's answers (map: questionId -> selected choiceIds).
  /// In a real impl, backend computes the score. Here we simulate it.
  Future<QuizResult> submit(
    String courseId,
    String quizId,
    Map<String, List<String>> answers,
  );
}

/* =======================
   Fake repository (swap later)
   ======================= */

class FakeQuizRepository implements QuizRepository {
  late final Quiz _demo = Quiz(
    id: 'demo-quiz-1',
    title: 'اختبار قصير: الأعداد الحقيقية',
    duration: const Duration(minutes: 10),
    questions: const [
      QuizQuestion(
        id: 'q1',
        text: 'العدد −3 هو عدد…',
        type: QuestionType.single,
        points: 1,
        choices: [
          Choice(id: 'q1a1', text: 'صحيح', isCorrect: false),
          Choice(id: 'q1a2', text: 'كسري', isCorrect: false),
          Choice(id: 'q1a3', text: 'صحيح سالب', isCorrect: true),
          Choice(id: 'q1a4', text: 'عشري موجب', isCorrect: false),
        ],
      ),
      QuizQuestion(
        id: 'q2',
        text: 'اختر جميع الأعداد الصحيحة مما يلي:',
        type: QuestionType.multiple,
        points: 2,
        choices: [
          Choice(id: 'q2a1', text: '5', isCorrect: true),
          Choice(id: 'q2a2', text: '3.5', isCorrect: false),
          Choice(id: 'q2a3', text: '0', isCorrect: true),
          Choice(id: 'q2a4', text: '-2', isCorrect: true),
        ],
      ),
      QuizQuestion(
        id: 'q3',
        text: 'القول: "كل عدد صحيح هو عدد كسري" صحيح أم خطأ؟',
        type: QuestionType.trueFalse,
        points: 1,
        choices: [
          Choice(id: 'q3t', text: 'صحيح', isCorrect: true),
          Choice(id: 'q3f', text: 'خطأ', isCorrect: false),
        ],
      ),
      QuizQuestion(
        id: 'q4',
        text: 'أي مما يلي عدد عشري منتهٍ؟',
        type: QuestionType.single,
        points: 1,
        choices: [
          Choice(id: 'q4a1', text: '1/3', isCorrect: false),
          Choice(id: 'q4a2', text: '2/5', isCorrect: true), // 0.4
          Choice(id: 'q4a3', text: '1/6', isCorrect: false),
          Choice(id: 'q4a4', text: '10/3', isCorrect: false),
        ],
      ),
    ],
  );

  @override
  Future<Quiz> fetch(String courseId, String quizId) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return _demo;
  }

  @override
  Future<QuizResult> submit(
    String courseId,
    String quizId,
    Map<String, List<String>> answers,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final q = _demo;
    double score = 0, max = 0;
    int correctCount = 0;

    for (final qq in q.questions) {
      max += qq.points;
      final selected = answers[qq.id] ?? const <String>[];
      final correctIds = qq.choices.where((c) => c.isCorrect).map((c) => c.id).toSet();
      final chosen = selected.toSet();

      // grading per type
      final isCorrect = chosen.length == correctIds.length && chosen.containsAll(correctIds);
      if (isCorrect) {
        score += qq.points;
        correctCount++;
      }
    }

    return QuizResult(
      score: score,
      max: max,
      correctCount: correctCount,
      totalCount: q.questions.length,
    );
  }
}

/* =======================
   Page
   ======================= */

class QuizPage extends StatefulWidget {
  final String courseId;
  final String quizId;
  final String quizTitle;
  final QuizRepository? repository;

  const QuizPage({
    super.key,
    required this.courseId,
    required this.quizId,
    required this.quizTitle,
    this.repository,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final QuizRepository _repo = widget.repository ?? FakeQuizRepository();
  late Future<Quiz> _future;

  // answers: questionId -> selected choiceIds
  final Map<String, Set<String>> _answers = {};
  QuizResult? _result;

  Timer? _timer;
  Duration? _timeLeft;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetch(widget.courseId, widget.quizId);
    _future.then((quiz) {
      if (quiz.duration != null) {
        _timeLeft = quiz.duration;
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (_timeLeft == null) return;
          if (_timeLeft!.inSeconds <= 1) {
            _timer?.cancel();
            _handleSubmit(); // auto-submit on timeout
          } else {
            setState(() => _timeLeft = _timeLeft! - const Duration(seconds: 1));
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.fetch(widget.courseId, widget.quizId);
      _answers.clear();
      _result = null;
      _timer?.cancel();
      _timeLeft = null;
    });
    final quiz = await _future;
    if (quiz.duration != null) {
      _timeLeft = quiz.duration;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_timeLeft == null) return;
        if (_timeLeft!.inSeconds <= 1) {
          _timer?.cancel();
          _handleSubmit();
        } else {
          setState(() => _timeLeft = _timeLeft! - const Duration(seconds: 1));
        }
      });
    }
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  int _answeredCount(Quiz q) =>
      q.questions.where((qq) => (_answers[qq.id]?.isNotEmpty ?? false)).length;

  Future<void> _handleSubmit() async {
    // prevent double submit
    if (_result != null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإرسال'),
        content: const Text('هل تريد إرسال إجاباتك الآن؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('إرسال')),
        ],
      ),
    );

    if (ok != true) return;

    final map = _answers.map((k, v) => MapEntry(k, v.toList()));
    final res = await _repo.submit(widget.courseId, widget.quizId, map);
    if (!mounted) return;
    setState(() => _result = res);

    // simple result dialog
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تم الإرسال'),
        content: Text(
          'النتيجة: ${res.score.toStringAsFixed(1)} / ${res.max.toStringAsFixed(1)}'
          ' (${(res.percent * 100).round()}%)',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<Quiz>(
        future: _future,
        builder: (context, snap) {
          final isLoading = snap.connectionState == ConnectionState.waiting && !snap.hasData;
          final hasError = snap.hasError;
          final quiz = snap.data;

          return Scaffold(
            backgroundColor: Palette.pageBackground,
            appBar: AppBar(
              backgroundColor: Palette.primary,
              centerTitle: true,
              title: Text(
                widget.quizTitle,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            body: hasError
                ? _ErrorState(onRetry: _refresh)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: isLoading && quiz == null
                        ? const _Skeleton()
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 950),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _QuizBanner(
                                      title: quiz!.title,
                                      timeLeftText: quiz.duration == null
                                          ? null
                                          : (_result == null && _timeLeft != null
                                              ? _fmtDuration(_timeLeft!)
                                              : '00:00'),
                                      answered: _answeredCount(quiz),
                                      total: quiz.questions.length,
                                      percent: quiz.questions.isEmpty
                                          ? 0
                                          : _answeredCount(quiz) / quiz.questions.length,
                                      result: _result,
                                    ),
                                    const SizedBox(height: 18),

                                    // Questions
                                    ...quiz.questions.indexed.map((entry) {
                                      final idx = entry.$1 + 1;
                                      final q = entry.$2;
                                      final selected = _answers[q.id] ?? <String>{};

                                      return _QuestionCard(
                                        index: idx,
                                        question: q,
                                        selected: selected,
                                        locked: _result != null, // lock after submit
                                        showCorrection: _result != null,
                                        onChange: (choiceId, checked) {
                                          if (_result != null) return;
                                          setState(() {
                                            final set = _answers.putIfAbsent(q.id, () => <String>{});
                                            switch (q.type) {
                                              case QuestionType.single:
                                              case QuestionType.trueFalse:
                                                set
                                                  ..clear()
                                                  ..add(choiceId);
                                                break;
                                              case QuestionType.multiple:
                                                checked ? set.add(choiceId) : set.remove(choiceId);
                                                break;
                                            }
                                          });
                                        },
                                      );
                                    }),

                                    const SizedBox(height: 20),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            icon: const Icon(Icons.send_rounded),
                                            onPressed: _result == null ? _handleSubmit : null,
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Palette.primary,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              textStyle: const TextStyle(fontWeight: FontWeight.w800),
                                            ),
                                            label: const Text('إرسال الإجابات'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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

/* =======================
   Widgets
   ======================= */

class _QuizBanner extends StatelessWidget {
  final String title;
  final String? timeLeftText;
  final int answered;
  final int total;
  final double percent;
  final QuizResult? result;

  const _QuizBanner({
    required this.title,
    required this.timeLeftText,
    required this.answered,
    required this.total,
    required this.percent,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
          colors: [Palette.primary.withOpacity(.95), Palette.primary.withOpacity(.70)],
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
          const Icon(Icons.quiz_rounded, size: 48, color: Colors.white),
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
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 10,
                          color: Colors.white,
                          backgroundColor: Colors.white.withOpacity(.35),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$answered / $total',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (timeLeftText != null)
                      Row(
                        children: [
                          const Icon(Icons.timer_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text('الوقت المتبقي: $timeLeftText',
                              style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    const Spacer(),
                    if (result != null)
                      Text(
                        'نتيجتك: ${result!.score.toStringAsFixed(1)} / ${result!.max.toStringAsFixed(1)}'
                        ' (${(result!.percent * 100).round()}%)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final QuizQuestion question;
  final Set<String> selected;
  final bool locked;
  final bool showCorrection;
  final void Function(String choiceId, bool checked) onChange;

  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.locked,
    required this.showCorrection,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final title = 'سؤال $index: ${question.text}';

    Color? correctColorFor(String choiceId) {
      if (!showCorrection) return null;
      final c = question.choices.firstWhere((x) => x.id == choiceId);
      if (c.isCorrect) return Colors.green.withOpacity(.12);
      if (selected.contains(choiceId)) return Colors.red.withOpacity(.12);
      return null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800, color: Palette.text)),
            const SizedBox(height: 10),
            ...question.choices.map((c) {
              switch (question.type) {
                case QuestionType.single:
                case QuestionType.trueFalse:
                  return Container(
                    decoration: BoxDecoration(
                      color: correctColorFor(c.id),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: RadioListTile<String>(
                      value: c.id,
                      groupValue: selected.isEmpty ? null : selected.first,
                      onChanged: locked ? null : (v) => onChange(c.id, true),
                      title: Text(c.text),
                      activeColor: Palette.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                case QuestionType.multiple:
                  final checked = selected.contains(c.id);
                  return Container(
                    decoration: BoxDecoration(
                      color: correctColorFor(c.id),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CheckboxListTile(
                      value: checked,
                      onChanged: locked ? null : (v) => onChange(c.id, v ?? false),
                      title: Text(c.text),
                      activeColor: Palette.primary,
                      visualDensity: VisualDensity.compact,
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
              }
            }),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'الدرجة: ${question.points.toStringAsFixed(1)}',
                style: const TextStyle(fontSize: 12, color: Palette.subtitle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =======================
   Error & Skeleton
   ======================= */

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
            const Text('تعذر تحميل الاختبار. حاول مجددًا.',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar() => Container(
          height: 126,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(.06),
            borderRadius: BorderRadius.circular(16),
          ),
        );

    Widget card() => Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        children: [
          bar(),
          const SizedBox(height: 16),
          card(),
          const SizedBox(height: 10),
          card(),
        ],
      ),
    );
  }
}
