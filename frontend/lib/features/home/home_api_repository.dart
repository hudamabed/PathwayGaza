// lib/features/home/home_api_repository.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../home/home_page.dart' show HomeRepository, HomeData, Course, Activity;
typedef TokenProvider = Future<String?> Function();

class ApiHomeRepository implements HomeRepository {
  final String baseUrl; // e.g. http://localhost:3000/api
  final http.Client _client;
  final TokenProvider? getToken;

  ApiHomeRepository({
    required this.baseUrl,
    http.Client? client,
    this.getToken,
  }) : _client = client ?? http.Client();

  /* ---------- headers ---------- */
  Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final h = <String, String>{'Accept': 'application/json'};
    if (jsonBody) h['Content-Type'] = 'application/json';
    final tk = await getToken?.call();
    if (tk != null && tk.isNotEmpty) h['Authorization'] = 'Bearer $tk';
    return h;
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

  static List _listIn(Map<String, dynamic> j) {
    for (final k in const ['results', 'items', 'data', '_list']) {
      final v = j[k];
      if (v is List) return v;
    }
    return const [];
  }

  static Map<String, dynamic>? _asMap(Object? v) => v is Map<String, dynamic> ? v : null;

  static String? _pickStr(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
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

  static double? _pickDouble01(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final v = j[k];
      if (v is num) {
        // accept 0..1 or 0..100 and normalize
        return v > 1 ? (v.toDouble() / 100.0) : v.toDouble();
      }
      if (v is String) {
        final p = double.tryParse(v);
        if (p != null) return p > 1 ? (p / 100.0) : p;
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

  /* ---------- icon guess (optional nicety) ---------- */
  static IconData _iconForTitle(String t) {
    final s = t.toLowerCase();
    if (s.contains('math') || s.contains('رياض') || s.contains('حساب')) {
      return Icons.functions_rounded;
    }
    if (s.contains('science') || s.contains('علوم')) {
      return Icons.science_rounded;
    }
    if (s.contains('عرب') || s.contains('arabic') || s.contains('لغة')) {
      return Icons.menu_book_rounded;
    }
    return Icons.auto_awesome_rounded;
  }

  /* ===========================================================
   * Home: combine learning + progress + last-activity
   *   GET /learning/courses/
   *   GET /progress/courses/
   *   GET /progress/last-activity/?limit=5
   * =========================================================== */
  @override
  Future<HomeData> fetchHome() async {
    final h = await _headers();

    final resp = await Future.wait<http.Response>([
      _client.get(Uri.parse('$baseUrl/learning/courses/'), headers: h),
      _client.get(Uri.parse('$baseUrl/progress/courses/'), headers: h),
      _client.get(Uri.parse('$baseUrl/progress/last-activity/?limit=5'), headers: h),
    ]).timeout(const Duration(seconds: 12));

    final jCourses   = _asJson(resp[0]);
    final jProgress  = _asJson(resp[1]);
    final jActivity  = _asJson(resp[2]);

    final courseList   = _listIn(jCourses).map(_asMap).whereType<Map<String, dynamic>>().toList();
    final progressList = _listIn(jProgress).map(_asMap).whereType<Map<String, dynamic>>().toList();
    final activityList = _listIn(jActivity).map(_asMap).whereType<Map<String, dynamic>>().toList();

    // index progress by course id
    Map<String, Map<String, dynamic>> progressByCourse = {};
    for (final m in progressList) {
      final cid = _pickStr(m, ['course', 'course_id', 'courseId', 'id']) ?? '';
      if (cid.isNotEmpty) progressByCourse[cid] = m;
    }

    // Build courses with progress
    final courses = <Course>[];
    int completedTotal = 0, lessonsTotal = 0;

    for (final c in courseList) {
      final id    = _pickStr(c, ['id', 'pk', 'uuid']) ?? '';
      final title = _pickStr(c, ['title', 'name']) ?? 'مساق';
      final locked = (_pickStr(c, ['status', 'enrollment_status']) ?? '')
          .toLowerCase()
          .contains('locked');

      final p = progressByCourse[id] ?? const <String, dynamic>{};
      final percent = _pickDouble01(p, ['progress', 'percent', 'percentage']) ?? 0.0;
      final completed = _pickInt(p, ['completed_lessons', 'completed', 'done', 'finished']) ?? 0;
      final total     = _pickInt(p, ['total_lessons', 'total', 'count']) ?? 0;

      completedTotal += completed;
      lessonsTotal   += total;

      courses.add(Course(
        id: id.isEmpty ? title : id,
        title: title,
        icon: _iconForTitle(title),
        progress: percent.clamp(0.0, 1.0),
        locked: locked,
      ));
    }

    // Overall (fallback to percent in /progress/courses/ if backend provides it)
    final overallPercent =
        _pickDouble01(jProgress, ['overall_progress', 'progress', 'percent']) ??
        (lessonsTotal > 0 ? (completedTotal / lessonsTotal) : 0.0);

    // Recent activity
    final recent = activityList.map((m) {
      final title = _pickStr(m, ['title', 'action', 'verb', 'label', 'activity']) ?? 'نشاط';
      final when  = _pickDate(m, ['timestamp', 'created_at', 'date', 'time']) ?? DateTime.now();
      return Activity(title, when);
    }).toList();

    // Optional percentile if backend returns it
    final percentile = _pickInt(jProgress, ['percentile', 'rank_percentile', 'rank']) ?? 50;

    // NOTE: name/grade are resolved in the widget (Firebase/args). Keep these empty to enable that coalesce.
    return HomeData(
      studentName: '',
      studentGrade: '',
      overallPercent: overallPercent,
      completedLessons: completedTotal,
      totalLessons: lessonsTotal == 0 ? (courses.length * 1) : lessonsTotal, // safe non-zero display
      percentile: percentile,
      recent: recent,
      courses: courses,
    );
  }

  /* ===========================================================
   * Extra helpers you can call elsewhere if needed
   *   GET  /progress/courses/{id}/
   *   GET  /progress/courses/{id}/lessons/
   *   GET  /progress/lessons/{lessonId}/
   *   PATCH /progress/lessons/{lessonId}/   (finish)
   *   POST /progress/lessons/{lessonId}/    (access ping)
   * =========================================================== */

  Future<Map<String, dynamic>> getCourseProgress(String courseId) async {
    final r = await _client.get(
      Uri.parse('$baseUrl/progress/courses/$courseId/'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 12));
    return _asJson(r);
  }

  Future<List<Map<String, dynamic>>> listCourseLessonProgress(String courseId) async {
    final r = await _client.get(
      Uri.parse('$baseUrl/progress/courses/$courseId/lessons/'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 12));
    return _listIn(_asJson(r)).map(_asMap).whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> getLessonProgress(String lessonId) async {
    final r = await _client.get(
      Uri.parse('$baseUrl/progress/lessons/$lessonId/'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 12));
    return _asJson(r);
  }

  Future<bool> markLessonFinished(String lessonId) async {
    final r = await _client.patch(
      Uri.parse('$baseUrl/progress/lessons/$lessonId/'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({
        // Try multiple common shapes; backend can ignore extras.
        'finished': true,
        'status': 'finished',
        'state': 'done',
      }),
    ).timeout(const Duration(seconds: 12));
    return r.statusCode >= 200 && r.statusCode < 300;
  }

  Future<bool> recordLessonAccess(String lessonId) async {
    final r = await _client.post(
      Uri.parse('$baseUrl/progress/lessons/$lessonId/'),
      headers: await _headers(jsonBody: true),
      body: jsonEncode({'event': 'access'}),
    ).timeout(const Duration(seconds: 12));
    return r.statusCode >= 200 && r.statusCode < 300;
  }
}
