// lib/features/lesson/quiz_api_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'quiz_page.dart'
    show
        QuizRepository,
        Quiz,
        QuizQuestion,
        Choice,
        QuestionType,
        QuizResult;

typedef TokenProvider = Future<String?> Function();

class ApiQuizRepository implements QuizRepository {
  final String baseUrl; // e.g. http://localhost:3000/api
  final http.Client _client;
  final TokenProvider? getToken;

  ApiQuizRepository({
    required this.baseUrl,
    http.Client? client,
    this.getToken,
  }) : _client = client ?? http.Client();

  // ---------- headers ----------
  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (jsonBody) h['Content-Type'] = 'application/json';
    final tk = await getToken?.call();
    if (tk != null && tk.isNotEmpty) h['Authorization'] = 'Bearer $tk';
    return h;
  }

  // ---------- tiny helpers ----------
  static Map<String, dynamic> _asJson(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      try {
        final body = r.body.isEmpty ? {} : jsonDecode(r.body);
        if (body is Map<String, dynamic>) return body;
        if (body is List) return {'_list': body};
      } catch (_) {}
    }
    return {};
  }

  static List _listIn(Map<String, dynamic> j) {
    for (final k in const ['results', 'items', 'data', '_list']) {
      final v = j[k];
      if (v is List) return v;
    }
    return const [];
  }

  static String? _pickStr(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static double? _pickDouble(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final p = double.tryParse(v);
        if (p != null) return p;
      }
    }
    return null;
  }

  static int? _pickInt(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final p = int.tryParse(v);
        if (p != null) return p;
      }
    }
    return null;
  }

  static DateTime? _pickDate(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is String) {
        final d = DateTime.tryParse(v);
        if (d != null) return d;
      }
    }
    return null;
  }

  static QuestionType _qType(String? raw) {
    final t = (raw ?? '').toLowerCase();
    if (t.contains('multi')) return QuestionType.multiple;
    if (t.contains('true') || t.contains('bool')) return QuestionType.trueFalse;
    return QuestionType.single;
  }

  // ============================================================
  // Required by QuizPage
  // ============================================================

  /// GET /quizzes/{id}
  @override
  Future<Quiz> fetch(String courseId, String quizId) async {
    final url = Uri.parse('$baseUrl/quizzes/$quizId');
    final r = await _client.get(url, headers: await _headers()).timeout(const Duration(seconds: 12));
    final j = _asJson(r);

    final id = _pickStr(j, ['id', 'uuid', 'pk']) ?? quizId;
    final title = _pickStr(j, ['title', 'name', 'label']) ?? 'اختبار';

    // duration (prefer seconds, else convert minutes to seconds)
    final durSecsDirect = _pickInt(j, ['duration_seconds', 'time_limit_seconds']);
    final durMins = _pickInt(j, ['duration', 'time_limit', 'duration_minutes']);
    final int? durSecs = durSecsDirect ?? (durMins != null ? durMins * 60 : null);
    final duration = durSecs == null ? null : Duration(seconds: durSecs);

    final qList = _listIn(j);
    final questions = <QuizQuestion>[];
    for (final raw in qList) {
      if (raw is! Map<String, dynamic>) continue;
      final qid = _pickStr(raw, ['id', 'uuid', 'pk']) ?? '';
      final text = _pickStr(raw, ['text', 'question', 'content']) ?? 'سؤال';
      final type = _qType(_pickStr(raw, ['type', 'question_type']));
      final points = _pickDouble(raw, ['points', 'score', 'weight']) ?? 1.0;

      // choices
      final choicesRaw = _listIn(raw);
      final choices = <Choice>[];
      if (choicesRaw.isNotEmpty && choicesRaw.first is Map<String, dynamic>) {
        for (final c in choicesRaw) {
          final m = c as Map<String, dynamic>;
          final cid = _pickStr(m, ['id', 'uuid', 'pk', 'value']) ?? '';
          final ctext = _pickStr(m, ['text', 'label', 'title', 'name']) ?? '';
          choices.add(Choice(id: cid.isEmpty ? ctext : cid, text: ctext));
        }
      } else if (type == QuestionType.trueFalse) {
        choices.addAll(const [
          Choice(id: 'true', text: 'صحيح'),
          Choice(id: 'false', text: 'خطأ'),
        ]);
      }

      questions.add(QuizQuestion(
        id: qid.isEmpty ? text : qid,
        text: text,
        type: type,
        choices: choices,
        points: points,
      ));
    }

    return Quiz(
      id: id,
      title: title,
      questions: questions,
      duration: duration,
    );
  }

  /// POST /quizzes/submit/{id}/
  /// Body: { "answers": [ {"question_id": "...", "choice_ids": ["..."]}, ... ] }
  @override
  Future<QuizResult> submit(
    String courseId,
    String quizId,
    Map<String, List<String>> answers,
  ) async {
    final url = Uri.parse('$baseUrl/quizzes/submit/$quizId/');
    final payload = {
      'answers': answers.entries
          .map((e) => {
                'question_id': e.key,
                'choice_ids': e.value,
              })
          .toList()
    };

    final r = await _client
        .post(url, headers: await _headers(jsonBody: true), body: jsonEncode(payload))
        .timeout(const Duration(seconds: 15));

    final j = _asJson(r);
    final double score = _pickDouble(j, ['score', 'obtained', 'points', 'result']) ?? 0.0;
    final double max = _pickDouble(j, ['max', 'total', 'out_of']) ?? 0.0;

    // Try to read counts if backend returns them; else fall back.
    final int correct = _pickInt(j, ['correct', 'correct_count']) ?? 0;
    final int total = _pickInt(j, ['total', 'question_count']) ?? answers.length;

    return QuizResult(
      score: score,
      max: max,
      correctCount: correct,
      totalCount: total,
    );
  }

  // ============================================================
  // Extra endpoints you asked for (lists, details, attempts)
  // ============================================================

  /// GET /quizzes/
  Future<List<QuizSummary>> listQuizzes() async {
    final r = await _client
        .get(Uri.parse('$baseUrl/quizzes/'), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    final j = _asJson(r);
    final list = _listIn(j);

    return list.whereType<Map<String, dynamic>>().map((m) {
      final id = _pickStr(m, ['id', 'uuid', 'pk']) ?? '';
      final title = _pickStr(m, ['title', 'name', 'label']) ?? 'اختبار';
      final qCount = _pickInt(m, ['question_count', 'questions', 'count']) ?? 0;

      final durSecsDirect = _pickInt(m, ['duration_seconds']);
      final durMins = _pickInt(m, ['duration', 'time_limit', 'duration_minutes']);
      final int? durSecs = durSecsDirect ?? (durMins != null ? durMins * 60 : null);

      return QuizSummary(
        id: id,
        title: title,
        questionCount: qCount,
        duration: durSecs == null ? null : Duration(seconds: durSecs),
      );
    }).toList();
  }

  /// GET /quizzes/{id}
  Future<QuizSummary?> getQuizSummary(String quizId) async {
    final r = await _client
        .get(Uri.parse('$baseUrl/quizzes/$quizId'), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    final j = _asJson(r);
    if (j.isEmpty) return null;

    final id = _pickStr(j, ['id', 'uuid', 'pk']) ?? quizId;
    final title = _pickStr(j, ['title', 'name', 'label']) ?? 'اختبار';
    final qCount = _listIn(j).length;

    final durSecsDirect = _pickInt(j, ['duration_seconds']);
    final durMins = _pickInt(j, ['duration', 'time_limit', 'duration_minutes']);
    final int? durSecs = durSecsDirect ?? (durMins != null ? durMins * 60 : null);

    return QuizSummary(
      id: id,
      title: title,
      questionCount: qCount,
      duration: durSecs == null ? null : Duration(seconds: durSecs),
    );
  }

  /// GET /quizzes/lessons/{lessonId}
  Future<List<QuizSummary>> listLessonQuizzes(String lessonId) async {
    final r = await _client
        .get(Uri.parse('$baseUrl/quizzes/lessons/$lessonId'), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    final j = _asJson(r);
    final list = _listIn(j);
    return list.whereType<Map<String, dynamic>>().map((m) {
      final id = _pickStr(m, ['id', 'uuid', 'pk']) ?? '';
      final title = _pickStr(m, ['title', 'name', 'label']) ?? 'اختبار';
      final qCount = _pickInt(m, ['question_count', 'questions', 'count']) ?? 0;
      return QuizSummary(id: id, title: title, questionCount: qCount);
    }).toList();
  }

  /// GET /quizzes/attempts/?limit=5
  Future<List<AttemptSummary>> listAttempts({int? limit}) async {
    final q = (limit != null) ? '?limit=$limit' : '';
    final r = await _client
        .get(Uri.parse('$baseUrl/quizzes/attempts/$q'), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    final j = _asJson(r);
    final list = _listIn(j);
    return list.whereType<Map<String, dynamic>>().map(_attemptFromJson).toList();
  }

  /// GET /quizzes/attempts/{id}
  Future<AttemptSummary?> getAttempt(String attemptId) async {
    final r = await _client
        .get(Uri.parse('$baseUrl/quizzes/attempts/$attemptId'), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    final j = _asJson(r);
    if (j.isEmpty) return null;
    return _attemptFromJson(j);
  }

  /// GET /quizzes/attempts/lessons/{lessonId}
  Future<List<AttemptSummary>> listLessonAttempts(String lessonId) async {
    final r = await _client
        .get(Uri.parse('$baseUrl/quizzes/attempts/lessons/$lessonId'), headers: await _headers())
        .timeout(const Duration(seconds: 12));
    final j = _asJson(r);
    final list = _listIn(j);
    return list.whereType<Map<String, dynamic>>().map(_attemptFromJson).toList();
  }

  AttemptSummary _attemptFromJson(Map<String, dynamic> m) {
    final id = _pickStr(m, ['id', 'uuid', 'pk']) ?? '';
    final quizId = _pickStr(m, ['quiz', 'quiz_id', 'quizId']) ?? '';
    final lessonId = _pickStr(m, ['lesson', 'lesson_id', 'lessonId']);
    final double score = _pickDouble(m, ['score', 'obtained', 'points']) ?? 0.0;
    final double max = _pickDouble(m, ['max', 'total', 'out_of']) ?? 0.0;
    final startedAt = _pickDate(m, ['started_at', 'created_at', 'start_time']);
    final finishedAt = _pickDate(m, ['finished_at', 'updated_at', 'end_time']);
    final double percent = max > 0 ? (score / max).clamp(0, 1) : 0.0;
    return AttemptSummary(
      id: id,
      quizId: quizId,
      lessonId: lessonId,
      score: score,
      max: max,
      percent: percent,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
  }
}

// ---------- simple summaries for lists ----------
class QuizSummary {
  final String id;
  final String title;
  final int questionCount;
  final Duration? duration;
  const QuizSummary({
    required this.id,
    required this.title,
    this.questionCount = 0,
    this.duration,
  });
}

class AttemptSummary {
  final String id;
  final String quizId;
  final String? lessonId;
  final double score;
  final double max;
  final double percent;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  const AttemptSummary({
    required this.id,
    required this.quizId,
    this.lessonId,
    required this.score,
    required this.max,
    required this.percent,
    this.startedAt,
    this.finishedAt,
  });
}
