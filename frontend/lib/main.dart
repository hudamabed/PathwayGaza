// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:gaza_learning_pathways/core/theme/palette.dart';
import 'package:gaza_learning_pathways/features/auth/login_page.dart';
import 'package:gaza_learning_pathways/features/catalog/catalog_page.dart';
import 'package:gaza_learning_pathways/features/home/home_page.dart';
import 'package:gaza_learning_pathways/features/course/course_content_page.dart';
import 'package:gaza_learning_pathways/features/course/course_grades_page.dart';
import 'package:gaza_learning_pathways/features/course/course_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _RootApp());
}

/* ======================= Route Names + Args ======================= */

class AppRoutes {
  static const home = '/home';
  static const login = '/login';
  static const courseContent = '/course-content';
  static const grades = '/grades';
  static const coursePage = '/course-page';
  static const catalog = '/catalog'; // ✅ FIX: define the missing route
}

class CourseContentArgs {
  final String courseId;
  final String courseTitle;
  final String gradeLabel;
  const CourseContentArgs({
    required this.courseId,
    required this.courseTitle,
    required this.gradeLabel,
  });
}

class CourseGradesArgs {
  final String courseId;
  final String courseTitle;
  final String gradeLabel;
  const CourseGradesArgs({
    required this.courseId,
    required this.courseTitle,
    required this.gradeLabel,
  });
}

class CoursePageArgs {
  final String courseTitle;
  final String gradeLabel;
  const CoursePageArgs({
    required this.courseTitle,
    required this.gradeLabel,
  });
}

/* ======================= App ======================= */

class _RootApp extends StatefulWidget {
  const _RootApp({super.key});
  @override
  State<_RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<_RootApp> {
  Locale _locale = const Locale('ar');

  void _toggleLocale() {
    setState(() {
      _locale = _locale.languageCode == 'ar' ? const Locale('en') : const Locale('ar');
    });
  }

  @override
  Widget build(BuildContext context) {
    // Demo fallbacks
    const demoCourseId = 'demo-math-g9';
    const demoCourseTitle = 'الرياضيات';
    const demoGradeLabel = 'الصف التاسع';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gaza Learning Pathways',

      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: _locale,

      // Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.primary),
        scaffoldBackgroundColor: Palette.pageBackground,
        datePickerTheme: const DatePickerThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),

      // Start on /home and define all routes:
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.login: (_) => const LoginPage(),

        // /course-content
        AppRoutes.courseContent: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as CourseContentArgs?;
          return CourseContentPage(
            courseId: args?.courseId ?? demoCourseId,
            courseTitle: args?.courseTitle ?? demoCourseTitle,
            gradeLabel: args?.gradeLabel ?? demoGradeLabel,
          );
        },

        // /grades
        AppRoutes.grades: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as CourseGradesArgs?;
          return CourseGradesPage(
            courseId: args?.courseId ?? demoCourseId,
            courseTitle: args?.courseTitle ?? demoCourseTitle,
            gradeLabel: args?.gradeLabel ?? demoGradeLabel,
          );
        },

        // /course-page (optional tabs page)
        AppRoutes.coursePage: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as CoursePageArgs?;
          return CoursePage(
            courseTitle: args?.courseTitle ?? demoCourseTitle,
            gradeLabel: args?.gradeLabel ?? demoGradeLabel,
          );
        },

        // /catalog
        AppRoutes.catalog: (_) => const CatalogPage(),
      },
    );
  }
}
