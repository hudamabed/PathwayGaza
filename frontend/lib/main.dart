// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gaza_learning_pathways/firebase_options.dart';

// Theme
import 'package:gaza_learning_pathways/core/theme/palette.dart';

// Top-level pages
import 'package:gaza_learning_pathways/features/home/home_page.dart';
import 'package:gaza_learning_pathways/features/catalog/catalog_page.dart';
import 'package:gaza_learning_pathways/features/auth/login_page.dart';
import 'package:gaza_learning_pathways/features/auth/signup_page.dart';
import 'package:gaza_learning_pathways/features/landing/landing_page.dart';

// Course flows
import 'package:gaza_learning_pathways/features/course/course_page.dart';
import 'package:gaza_learning_pathways/features/course/course_content_page.dart';
import 'package:gaza_learning_pathways/features/course/course_grades_page.dart';
import 'package:gaza_learning_pathways/features/course/course_api_repository.dart';

// Home & Quiz API repos
import 'package:gaza_learning_pathways/features/home/home_api_repository.dart';
import 'package:gaza_learning_pathways/features/lesson/quiz_api_repository.dart';

// Lesson & Quiz screens + their args
import 'package:gaza_learning_pathways/features/lesson/lesson_page.dart';
import 'package:gaza_learning_pathways/features/lesson/quiz_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase init (web needs options)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Dev auto-login to make the app usable during development
  const devEmail = 'changed@example.com';
  const devPassword = '010203';

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: devEmail,
      password: devPassword,
    );
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: devEmail,
        password: devPassword,
      );
    } else {
      rethrow;
    }
  }

  runApp(const MyApp());
}

/* A tiny public wrapper so tests (and other packages) can pump the app. */
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const _RootApp();
}

/* ======================= Route Names + Args ======================= */

class AppRoutes {
  static const home          = '/home';
  static const login         = '/login';
  static const signup        = '/signup';
  static const landing       = '/landing';
  static const catalog       = '/catalog';
  static const coursePage    = '/course-page';
  static const courseContent = '/course-content';
  static const grades        = '/grades';
  static const lesson        = '/lesson';
  static const quiz          = '/quiz';
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
  final String courseId;
  final String courseTitle;
  final String gradeLabel;
  const CoursePageArgs({
    required this.courseId,
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

  Future<String?> _getFirebaseIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(true); // force refresh
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Pick from --dart-define=API_BASE=..., else use proxy to dodge CORS
    const apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://localhost:3000/api');

    // Demo defaults (used only if someone navigates without args)
    const demoCourseId    = '1';
    const demoCourseTitle = 'الرياضيات';
    const demoGradeLabel  = 'الصف التاسع';

    final courseRepo = ApiCourseRepository(
      baseUrl: apiBase,
      getToken: _getFirebaseIdToken, // <-- add Bearer token
    );

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
        fontFamily: 'Cairo',
      ),

      // Start here
      initialRoute: AppRoutes.landing,

      routes: {
        // ---------- Top-level ----------
        AppRoutes.home: (_) => HomePage(
              repository: ApiHomeRepository(
                baseUrl: apiBase,
                getToken: _getFirebaseIdToken,
              ),
            ),
        AppRoutes.login:  (_) => const LoginPage(),
        AppRoutes.signup: (_) => const SignupPage(),
        AppRoutes.landing: (_) => LandingPage(
              isArabic: _locale.languageCode == 'ar',
              onToggleLanguage: _toggleLocale,
            ),
        AppRoutes.catalog: (_) => const CatalogPage(),

        // ---------- Course ----------
        AppRoutes.coursePage: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as CoursePageArgs?;
          return CoursePage(
            courseId:    args?.courseId    ?? demoCourseId,
            courseTitle: args?.courseTitle ?? demoCourseTitle,
            gradeLabel:  args?.gradeLabel  ?? demoGradeLabel,
            repository:  courseRepo,
          );
        },

        AppRoutes.courseContent: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as CourseContentArgs?;
          return CourseContentPage(
            courseId:    args?.courseId    ?? demoCourseId,
            courseTitle: args?.courseTitle ?? demoCourseTitle,
            gradeLabel:  args?.gradeLabel  ?? demoGradeLabel,
          );
        },

        AppRoutes.grades: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as CourseGradesArgs?;
          return CourseGradesPage(
            courseId:    args?.courseId    ?? demoCourseId,
            courseTitle: args?.courseTitle ?? demoCourseTitle,
            gradeLabel:  args?.gradeLabel  ?? demoGradeLabel,
            repository:  ApiGradesRepository(
              baseUrl: apiBase,
              getToken: _getFirebaseIdToken, // same token provider
            ),
          );
        },

        // ---------- Lesson ----------
        AppRoutes.lesson: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as LessonPageArgs?;
          return LessonPage(
            courseId:    args?.courseId    ?? demoCourseId,
            lessonId:    args?.lessonId    ?? 'demo-lesson',
            lessonTitle: args?.lessonTitle ?? 'درس تجريبي',
          );
        },

        // ---------- Quiz ----------
        AppRoutes.quiz: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as QuizPageArgs?;
          return QuizPage(
            courseId:  args?.courseId  ?? demoCourseId,
            quizId:    args?.quizId    ?? 'demo-quiz',
            quizTitle: args?.quizTitle ?? 'اختبار قصير',
            repository: ApiQuizRepository(
              baseUrl: apiBase,
              getToken: _getFirebaseIdToken,
            ),
          );
        },
      },

      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('صفحة غير موجودة')),
          body: Center(child: Text('المسار غير معروف: ${settings.name}')),
        ),
      ),
    );
  }
}
