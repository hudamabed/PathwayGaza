// lib/features/course/course_api_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

// Pulls CourseRepository & CourseOverview from Course page
import 'course_page.dart' show CourseRepository, CourseOverview, CourseMember, GradeRow;

// Pulls Grade types & interface from Grades page
import 'course_grades_page.dart' show GradesRepository, GradesData, GradeItem;

typedef TokenProvider = Future<String?> Function();

/// ===========================================================
/// Course APIs (existing + new list endpoints)
/// ===========================================================
class ApiCourseRepository implements CourseRepository {
  final String baseUrl; // e.g. http://localhost:3000/api
  final http.Client _client;
  final TokenProvider? getToken;

  ApiCourseRepository({
    required this.baseUrl,
    http.Client? client,
    this.getToken,
  }) : _client = client ?? http.Client();

  /* ---------- shared headers (Bearer from Firebase) ---------- */
  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = await getToken?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /* ---------- tiny JSON helpers ---------- */
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

  static List<dynamic> _extractList(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is List) return v;
    }
    return const [];
  }

  static Map<String, dynamic>? _asMap(Object? v) =>
      (v is Map<String, dynamic>) ? v : null;

  static String? _pickString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static int? _pickNumAsInt(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) {
        final p = int.tryParse(v);
        if (p != null) return p;
      }
    }
    return null;
  }

  static double? _pickNumAsDouble(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final p = double.tryParse(v);
        if (p != null) return p;
      }
    }
    return null;
  }

  static IconData? _iconFromLesson(Map<String, dynamic> m) {
    final t = (_pickString(m, ['type', 'kind', 'category']) ?? '').toLowerCase();
    if (t.contains('quiz') || t.contains('exam') || t.contains('test')) {
      return Icons.edit_note_rounded;
    }
    if (t.contains('video') || t.contains('zoom') || t.contains('meeting')) {
      return Icons.videocam_rounded;
    }
    return null;
  }

  static String? _formatPeriod(String? startISO, String? endISO) {
    if (startISO == null && endISO == null) return null;
    String fmt(String s) => s.length >= 10 ? s.substring(0, 10) : s;
    if (startISO != null && endISO != null) return '${fmt(startISO)} - ${fmt(endISO)}';
    if (startISO != null) return fmt(startISO);
    return fmt(endISO!);
  }

  /* ===========================================================
   * 🔹 NEW: Mock lessons per course (Palestinian curriculum flavoured)
   *    Returned when the backend has no lessons yet.
   *    Keys used by the rest of the code: id, title, type, start, end, description
   *    For quiz rows, we set type: "quiz" and id like "quiz-1".
   * =========================================================== */
  List<Map<String, dynamic>> _mockLessonsFor(String courseId) {
    final id = (courseId.isEmpty ? '' : courseId).toLowerCase();

    if (id.startsWith('math-g6') || id == 'math-g6') {
      return [
        {
          'id': 'l1',
          'title': 'الأعداد الكبيرة والقيمة المكانية',
          'type': 'reading',
          'description': 'مراجعة قراءة وكتابة الأعداد حتى الملايين.',
          'start': '2025-09-01',
          'end': '2025-09-07',
        },
        {
          'id': 'l2',
          'title': 'الجمع والطرح متعددة الخطوات',
          'type': 'video',
          'description': 'حل مسائل حياتية على الجمع والطرح باستخدام التقدير.',
          'start': '2025-09-08',
          'end': '2025-09-14',
        },
        {
          'id': 'quiz-1',
          'title': 'اختبار قصير: العمليات على الأعداد',
          'type': 'quiz',
          'description': '10 دقائق – أسئلة اختيار من متعدد وصح/خطأ.',
          'start': '2025-09-15',
          'end': '2025-09-15',
        },
        {
          'id': 'l3',
          'title': 'المحيط والمساحة للمستطيل والمربع',
          'type': 'reading',
          'description': 'تطبيقات على أشكال من مناهج فلسطين للصف السادس.',
          'start': '2025-09-16',
          'end': '2025-09-22',
        },
        {
          'id': 'l4',
          'title': 'القسمة المطوّلة',
          'type': 'video',
          'description': 'تقسيم أعداد كبيرة وخطوات التحقق.',
          'start': '2025-09-23',
          'end': '2025-09-29',
        },
      ];
    }

    if (id.startsWith('science-g6') || id == 'science-g6') {
      return [
        {
          'id': 's1',
          'title': 'دورة الماء في الطبيعة',
          'type': 'video',
          'description': 'تبخر، تكاثف، هطول – أمثلة من بيئة فلسطين.',
          'start': '2025-09-01',
          'end': '2025-09-07',
        },
        {
          'id': 's2',
          'title': 'السلاسل الغذائية',
          'type': 'reading',
          'description': 'المنتِجات والمستهلِكات والمحلِّلات.',
          'start': '2025-09-08',
          'end': '2025-09-14',
        },
        {
          'id': 'quiz-1',
          'title': 'اختبار قصير: الماء والغذاء',
          'type': 'quiz',
          'description': '5 أسئلة متنوعة.',
          'start': '2025-09-15',
          'end': '2025-09-15',
        },
        {
          'id': 's3',
          'title': 'التغيرات الفيزيائية والكيميائية',
          'type': 'reading',
          'description': 'تمييز التغيرات بالأمثلة.',
          'start': '2025-09-16',
          'end': '2025-09-22',
        },
      ];
    }

    if (id.startsWith('arabic-g6') || id == 'arabic-g6') {
      return [
        {
          'id': 'a1',
          'title': 'الجملة الاسمية والجملة الفعلية',
          'type': 'reading',
          'description': 'المبتدأ والخبر – الفعل والفاعل.',
          'start': '2025-09-01',
          'end': '2025-09-07',
        },
        {
          'id': 'a2',
          'title': 'علامات الترقيم',
          'type': 'video',
          'description': 'الفاصلة، النقطة، علامة الاستفهام والتعجب…',
          'start': '2025-09-08',
          'end': '2025-09-14',
        },
        {
          'id': 'quiz-1',
          'title': 'اختبار قصير: نحو وترقيم',
          'type': 'quiz',
          'description': 'تصحيح جُمل قصيرة.',
          'start': '2025-09-15',
          'end': '2025-09-15',
        },
        {
          'id': 'a3',
          'title': 'الهمزة المتطرفة والمتوسطة',
          'type': 'reading',
          'description': 'قواعد وأمثلة تدريبية.',
          'start': '2025-09-16',
          'end': '2025-09-22',
        },
      ];
    }

    if (id.contains('digital') || id == 'digital-skills') {
      return [
        {
          'id': 'd1',
          'title': 'السلامة الرقمية',
          'type': 'reading',
          'description': 'كلمات المرور، الخصوصية، والتنمر الإلكتروني.',
          'start': '2025-09-01',
          'end': '2025-09-07',
        },
        {
          'id': 'd2',
          'title': 'مقدمة في Scratch',
          'type': 'video',
          'description': 'برمجة قصص تفاعلية بسيطة.',
          'start': '2025-09-08',
          'end': '2025-09-14',
        },
        {
          'id': 'quiz-1',
          'title': 'اختبار قصير: مفاهيم رقمية',
          'type': 'quiz',
          'description': 'مفاهيم أساسية في الحوسبة.',
          'start': '2025-09-15',
          'end': '2025-09-15',
        },
        {
          'id': 'd3',
          'title': 'البحث الذكي على الإنترنت',
          'type': 'reading',
          'description': 'الكلمات المفتاحية ومصادر موثوقة.',
          'start': '2025-09-16',
          'end': '2025-09-22',
        },
      ];
    }

    // Grade 9 demo math (used elsewhere in your app)
    if (id.startsWith('demo-math-g9') || id.startsWith('math-g9')) {
      return [
        {
          'id': 'm9-1',
          'title': 'المعادلات الخطية وحلّها',
          'type': 'reading',
          'description': 'طرق الحل والتحقق.',
          'start': '2025-09-01',
          'end': '2025-09-07',
        },
        {
          'id': 'm9-2',
          'title': 'الدوال والتمثيل البياني',
          'type': 'video',
          'description': 'ميل الخط والجزء المقطوع.',
          'start': '2025-09-08',
          'end': '2025-09-14',
        },
        {
          'id': 'quiz-1',
          'title': 'اختبار قصير: خطيات',
          'type': 'quiz',
          'description': 'أسئلة سريعة على الميل والمعادلات.',
          'start': '2025-09-15',
          'end': '2025-09-15',
        },
        {
          'id': 'm9-3',
          'title': 'الهندسة: تشابه المثلثات',
          'type': 'reading',
          'description': 'نظريات وزوايا.',
          'start': '2025-09-16',
          'end': '2025-09-22',
        },
      ];
    }

    // Generic fallback
    return [
      {
        'id': 'g1',
        'title': 'تعريف بالمقرر',
        'type': 'reading',
        'description': 'نظرة عامة على أهداف المساق ومتطلباته.',
        'start': '2025-09-01',
        'end': '2025-09-07',
      },
      {
        'id': 'quiz-1',
        'title': 'اختبار قصير تمهيدي',
        'type': 'quiz',
        'description': 'قياس أولي للمستوى.',
        'start': '2025-09-08',
        'end': '2025-09-08',
      },
    ];
  }

  /* ===========================================================
   * 1) Existing: fetch a single course (basics + lessons + progress)
   * =========================================================== */
  @override
  Future<CourseOverview> fetchCourse(String courseId) async {
    final headers = await _headers();

    final courseBasicsUrl    = Uri.parse('$baseUrl/learning/courses/$courseId/');
    final courseLessonsUrl   = Uri.parse('$baseUrl/learning/courses/$courseId/lessons');
    final progressCourseUrl  = Uri.parse('$baseUrl/progress/courses/$courseId/');
    final progressLessonsUrl = Uri.parse('$baseUrl/progress/courses/$courseId/lessons/');

    final responses = await Future.wait<http.Response>([
      _client.get(courseBasicsUrl,    headers: headers),
      _client.get(courseLessonsUrl,   headers: headers),
      _client.get(progressCourseUrl,  headers: headers),
      _client.get(progressLessonsUrl, headers: headers),
    ]).timeout(const Duration(seconds: 12));

    final courseBasics    = _asJson(responses[0]);
    final courseLessons   = _asJson(responses[1]);
    final progressCourse  = _asJson(responses[2]);
    final progressLessons = _asJson(responses[3]);

    final titleMaybe       = _pickString(courseBasics, ['title', 'name']);
    final gradeLabelMaybe  = _pickString(courseBasics, ['grade_label', 'grade', 'level', 'class_name']);
    final descriptionMaybe = _pickString(courseBasics, ['description', 'summary']);

    // 🔹 Use backend lessons or fall back to our mocks per course
    List<dynamic> lessonsList = _extractList(courseLessons, ['results', 'items', '_list']);
    if (lessonsList.isEmpty) {
      lessonsList = _mockLessonsFor(courseId);
    }

    final syllabus = lessonsList
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map((m) => (m['title'] ?? m['name']) as String?)
        .whereType<String>()
        .toList();

    final schedule = lessonsList.map((raw) {
      final m = _asMap(raw) ?? {};
      final start = _pickString(m, ['start', 'start_date', 'available_from', 'published_at', 'open_at']);
      final end   = _pickString(m, ['end', 'end_date', 'available_to', 'due_date', 'close_at']);
      final label = _formatPeriod(start, end) ?? (m['title'] as String?) ?? (m['name'] as String?) ?? 'درس';
      final trailing = _iconFromLesson(m);
      final items = <String>[
        if (m['title'] is String) m['title'] as String,
        if (m['subtitle'] is String) m['subtitle'] as String,
        if (m['description'] is String) (m['description'] as String).trim(),
      ].where((s) => s.trim().isNotEmpty).toList();
      return (period: label, trailing: trailing, items: items);
    }).toList();

    final teacherName = _pickString(courseBasics, ['teacher', 'instructor', 'teacher_name', 'owner_name']);
    final membersFromProgress = _extractList(progressCourse, ['members', 'students', 'participants'])
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map((m) => CourseMember(
              name: _pickString(m, ['name', 'full_name', 'username']) ?? 'طالب',
              isTeacher: (_pickString(m, ['role', 'type']) ?? '').toLowerCase().contains('teacher'),
            ))
        .toList();

    final members = <CourseMember>[
      if (teacherName != null && teacherName.isNotEmpty)
        CourseMember(name: teacherName, isTeacher: true),
      ...membersFromProgress.where((m) => !m.isTeacher),
    ];

    final grades = _extractList(progressLessons, ['results', 'items', '_list'])
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map((m) {
          final item = _pickString(m, ['title', 'name']) ?? 'عنصر تقييم';
          final obtained = _pickNumAsInt(m, ['score', 'obtained', 'mark', 'grade_obtained']);
          final total    = _pickNumAsInt(m, ['total', 'max_score', 'out_of']);
          final mark = (obtained != null && total != null)
              ? '$total/$obtained'
              : (_pickString(m, ['mark']) ?? '-');
          return GradeRow(item, mark);
        }).toList();

    return CourseOverview(
      id: courseId,
      title: titleMaybe ?? 'المساق',
      gradeLabel: gradeLabelMaybe ?? 'الصف',
      description: descriptionMaybe ?? 'لا يوجد وصف للمادة حالياً.',
      schedule: schedule,
      syllabus: syllabus.isNotEmpty ? syllabus : ['ستظهر الخطة الدراسية هنا عند توفر الدروس.'],
      members: members.isNotEmpty ? members : const [CourseMember(name: 'المعلم', isTeacher: true)],
      grades: grades,
    );
  }

  /* ===========================================================
   * 2) NEW: GET /learning/courses/   → list all courses (basic info)
   * =========================================================== */
  Future<List<CourseSummary>> listCourses() async {
    final headers = await _headers();
    final url = Uri.parse('$baseUrl/learning/courses/');
    final r = await _client.get(url, headers: headers)
        .timeout(const Duration(seconds: 12));

    final json = _asJson(r);
    final list = _extractList(json, ['results', 'items', '_list']);

    return list.map(_asMap).whereType<Map<String, dynamic>>().map((m) {
      final id = _pickString(m, ['id', 'pk', 'uuid']) ?? '';
      final title = _pickString(m, ['title', 'name']) ?? 'مساق';
      final grade = _pickString(m, ['grade_label', 'grade', 'level', 'class_name']) ?? '';
      final desc  = _pickString(m, ['description', 'summary']) ?? '';
      return CourseSummary(id: id, title: title, gradeLabel: grade, description: desc);
    }).toList();
  }

  /* ===========================================================
   * 3) GET /learning/courses/{id}/lessons → raw list passthrough
   *    🔹 Falls back to mock lessons if the API returns empty.
   * =========================================================== */
  Future<List<Map<String, dynamic>>> listCourseLessonsRaw(String courseId) async {
    final headers = await _headers();
    final url = Uri.parse('$baseUrl/learning/courses/$courseId/lessons');
    final r = await _client.get(url, headers: headers)
        .timeout(const Duration(seconds: 12));

    final json = _asJson(r);
    List<dynamic> list = _extractList(json, ['results', 'items', '_list']);
    if (list.isEmpty) {
      return _mockLessonsFor(courseId);
    }
    return list.map(_asMap).whereType<Map<String, dynamic>>().toList();
  }
}

/// Lightweight model for course catalog rows.
class CourseSummary {
  final String id;
  final String title;
  final String gradeLabel;
  final String description;
  const CourseSummary({
    required this.id,
    required this.title,
    required this.gradeLabel,
    required this.description,
  });
}

/// ===========================================================
/// Grades API repository (GET /learning/grades/)
/// Implements GradesRepository used by CourseGradesPage.
/// ===========================================================
class ApiGradesRepository implements GradesRepository {
  final String baseUrl; // e.g. http://localhost:3000/api
  final http.Client _client;
  final TokenProvider? getToken;

  ApiGradesRepository({
    required this.baseUrl,
    http.Client? client,
    this.getToken,
  }) : _client = client ?? http.Client();

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Accept': 'application/json'};
    final token = await getToken?.call();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _asJson(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      try {
        final body = r.body.isEmpty ? {} : jsonDecode(r.body);
        if (body is Map<String, dynamic>) return body;
        if (body is List) return {'_list': body};
      } catch (_) {}
    }
    return {};
  }

  List<dynamic> _extractList(Map<String, dynamic> json) {
    for (final k in const ['results', 'items', '_list']) {
      final v = json[k];
      if (v is List) return v;
    }
    return const [];
  }

  String? _pickString(Map<String, dynamic> json, List<String> keys) =>
      ApiCourseRepository._pickString(json, keys);
  double? _pickDouble(Map<String, dynamic> json, List<String> keys) =>
      ApiCourseRepository._pickNumAsDouble(json, keys);

  @override
  Future<GradesData> fetch(String courseId) async {
    final headers = await _headers();

    // If your backend supports filtering, uncomment one of these:
    // final url = Uri.parse('$baseUrl/learning/grades/?course=$courseId');
    // final url = Uri.parse('$baseUrl/learning/grades/?course_id=$courseId');

    // Generic (works regardless of filter support); client-side filter later:
    final url = Uri.parse('$baseUrl/learning/grades/');
    final r = await _client.get(url, headers: headers)
        .timeout(const Duration(seconds: 12));

    final json = _asJson(r);
    final list = _extractList(json);

    final items = <GradeItem>[];
    for (final raw in list) {
      final m = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};

      // Optional client-side filter by course
      final courseRaw = _pickString(m, ['course', 'course_id', 'courseId', 'course_pk']);
      if (courseRaw != null && courseRaw.isNotEmpty && courseRaw != courseId) {
        continue; // skip others
      }

      final id = _pickString(m, ['id', 'grade_id', 'pk', 'uuid']) ?? '';
      final title = _pickString(m, ['title', 'name', 'label']) ?? 'عنصر تقييم';
      final category = _pickString(m, ['category', 'type', 'kind']) ?? 'غير مصنف';

      DateTime? date;
      for (final k in const ['date', 'graded_at', 'created_at', 'updated_at', 'deadline', 'due_date']) {
        final v = m[k];
        if (v is String) {
          final d = DateTime.tryParse(v);
          if (d != null) {
            date = d;
            break;
          }
        }
      }

      final score = _pickDouble(m, ['score', 'obtained', 'mark', 'grade_obtained']);
      final max   = _pickDouble(m, ['total', 'max_score', 'out_of']) ?? 0;
      final min   = _pickDouble(m, ['min', 'min_score']) ?? 0;
      final weight= _pickDouble(m, ['weight', 'weighting']);

      items.add(GradeItem(
        id: id.isEmpty ? title : id,
        title: title,
        category: category,
        date: date,
        max: max,
        min: min,
        score: score,
        weight: weight,
      ));
    }

    return GradesData(items);
  }
}
