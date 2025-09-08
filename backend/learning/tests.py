from django.test import TestCase
from django.contrib.auth import get_user_model
from django.db import IntegrityError

from .models import Grade, Course, Lesson, CourseEnrollment, LessonProgress


User = get_user_model()


class LearningModelsTest(TestCase):
    def setUp(self):
        # Create user
        self.user = User.objects.create_user(
            email="test@example.com",
            username="testuser",
            password="password123"
        )

        self.grade1 = Grade.objects.create(
            name="Grade 1",
            description="First grade"
        )

        self.course1 = Course.objects.create(
            name="Math 101",
            description="Basic Math",
            grade=self.grade1
        )
        self.course2 = Course.objects.create(
            name="Science 101",
            description="Basic Science",
            grade=self.grade1
        )

        self.lesson1 = Lesson.objects.create(
            course=self.course1,
            title="Addition",
            order=1,
            document_link="http://example.com/addition"
        )
        self.lesson2 = Lesson.objects.create(
            course=self.course1,
            title="Subtraction",
            order=2,
            document_link="http://example.com/subtraction"
        )

    def test_course_relationship(self):
        self.assertEqual(list(self.grade1.courses.all()),
                         [self.course1, self.course2])

    def test_lesson_relationship(self):
        lessons = list(self.course1.lessons.all())
        self.assertEqual(lessons, [self.lesson1, self.lesson2])
        self.assertEqual(lessons[0].order, 1)

    def test_grade_name_unique(self):
        with self.assertRaises(IntegrityError):
            Grade.objects.create(
                name="Grade 1",
                description="Duplicate grade"
            )

    def test_unique_lesson_order(self):
        with self.assertRaises(IntegrityError):
            Lesson.objects.create(
                course=self.course1,
                title="Duplicate Order",
                order=1,
                document_link="http://example.com/duplicate"
            )

    def test_lesson_ordering_in_meta(self):
        lessons = list(self.course1.lessons.all())
        self.assertEqual(lessons[0], self.lesson1)
        self.assertEqual(lessons[1], self.lesson2)

    def test_cross_course_same_order_allowed(self):
        lesson_other_course = Lesson.objects.create(
            course=self.course2,
            title="Biology Intro",
            order=1,  # same as lesson1 but different course
            document_link="http://example.com/biology"
        )
        self.assertEqual(lesson_other_course.order, 1)

    def test_str_methods(self):
        self.assertEqual(str(self.grade1), "Grade 1")
        self.assertIn("Math 101", str(self.course1))
        self.assertIn("Addition", str(self.lesson1))

    # ---------- Tests for Enrollments & Progress ----------

    def test_course_enrollment_creation(self):
        enrollment = CourseEnrollment.objects.create(
            user=self.user,
            course=self.course1
        )
        self.assertEqual(enrollment.user, self.user)
        self.assertEqual(enrollment.course, self.course1)
        self.assertIsNotNone(enrollment.start_date)
        self.assertIn("enrolled", str(enrollment).lower())

    def test_lesson_progress_creation(self):
        progress = LessonProgress.objects.create(
            user=self.user,
            lesson=self.lesson1,
            is_completed=False
        )
        self.assertEqual(progress.user, self.user)
        self.assertEqual(progress.lesson, self.lesson1)
        self.assertFalse(progress.is_completed)
        self.assertIsNotNone(progress.last_accessed)
        self.assertIn("In Progress", str(progress))

    def test_lesson_progress_mark_completed(self):
        progress = LessonProgress.objects.create(
            user=self.user,
            lesson=self.lesson2,
            is_completed=False
        )
        progress.is_completed = True
        progress.save()
        self.assertTrue(progress.is_completed)
        self.assertIn("Completed", str(progress))
