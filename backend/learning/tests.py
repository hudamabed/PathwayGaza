from django.test import TestCase
from rest_framework.test import APITestCase
from rest_framework import status
from django.urls import reverse
from django.db import IntegrityError
from django.contrib.auth import get_user_model

from .models import Grade, Course, Lesson, LessonProgress


User = get_user_model()

# ---------------------
# Learning Models Tests
# ---------------------


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
            image_url="helloworld.com",
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

    # ---------- Tests for Progress ----------
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


class LearningAPITestCase(APITestCase):

    def setUp(self):
        # Create grades
        self.grade1 = Grade.objects.create(name="Grade 1")
        self.grade2 = Grade.objects.create(name="Grade 2")

        # Create users
        self.student = User.objects.create_user(
            email="student@example.com",
            username="student",
            firebase_uid="test_uid",
            grade=self.grade1
        )

        # Create courses
        self.course1 = Course.objects.create(name="Math", grade=self.grade1)
        self.course2 = Course.objects.create(name="Science", grade=self.grade2)

        # Create lessons
        self.lesson1 = Lesson.objects.create(
            title="Lesson 1", order=1, course=self.course1)
        self.lesson2 = Lesson.objects.create(
            title="Lesson 2", order=2, course=self.course1)

    # ---------------------------
    # Grades
    # ---------------------------
    def test_get_grades(self):
        url = reverse("grade-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)

    # ---------------------------
    # Student courses
    # ---------------------------
    def test_student_courses_list(self):
        self.client.force_authenticate(self.student)
        url = reverse("course-list")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["name"], self.course1.name)

    # ---------------------------
    # Lessons in a course
    # ---------------------------
    def test_get_lessons_in_course(self):
        url = reverse("lesson-list", args=[self.course1.id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
        self.assertEqual(response.data[0]["title"], self.lesson1.title)

    # ---------------------------
    # Lesson progress lifecycle
    # ---------------------------
    def test_lesson_progress_crud(self):
        self.client.force_authenticate(self.student)
        url = reverse("lesson-progress", args=[self.lesson1.id])

        # GET before starting → 404
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

        # POST → start lesson
        response = self.client.post(url)
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertFalse(response.data["is_completed"])

        # GET → now returns progress
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data["is_completed"])

        # PATCH → complete lesson
        response = self.client.patch(
            url, {"is_completed": True}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["is_completed"])

        # PATCH again → mark incomplete (optional)
        response = self.client.patch(
            url, {"is_completed": False}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data["is_completed"])

    # ---------------------------
    # Finish lesson not started
    # ---------------------------
    def test_patch_lesson_not_started(self):
        self.client.force_authenticate(self.student)
        url = reverse("lesson-progress", args=[self.lesson2.id])

        response = self.client.patch(
            url, {"is_completed": True}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIsNotNone(response.data.get("detail"))
