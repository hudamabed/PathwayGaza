from django.test import TestCase
from rest_framework.test import APITestCase
from django.urls import reverse
from rest_framework import status
from django.contrib.auth import get_user_model

from .models import LessonProgress
from learning.models import Grade, Course, Lesson

User = get_user_model()


# ---------- Tests for Progress ----------
class ProgressModelsTest(TestCase):

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


class ProgressAPITest(APITestCase):
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

        self.client.force_authenticate(self.student)

    # ---------------------------
    # Lesson progress lifecycle
    # ---------------------------
    def test_lesson_progress_crud(self):
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

        # PATCH again → mark incomplete
        response = self.client.patch(
            url, {"is_completed": False}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data["is_completed"])

    def test_patch_lesson_not_started(self):
        url = reverse("lesson-progress", args=[self.lesson2.id])
        response = self.client.patch(
            url, {"is_completed": True}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIsNotNone(response.data.get("detail"))

    # ---------------------------
    # Course-level progress
    # ---------------------------
    def test_course_progress_view(self):
        # Start only lesson1
        LessonProgress.objects.create(
            user=self.student, lesson=self.lesson1, is_completed=True)

        url = reverse("course-progress", args=[self.course1.id])
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Both lesson progresses should appear
        self.assertEqual(len(response.data), 2)
        self.assertEqual(response.data[0]["lesson"]["id"], self.lesson1.id)
        self.assertEqual(response.data[1]["lesson"]["id"], self.lesson2.id)
        self.assertIsNotNone(response.data[1].get("is_completed"))
        self.assertTrue(response.data[0].get("is_completed"))
        self.assertFalse(response.data[1].get("is_completed"))

    # ---------------------------
    # Overall progress summary
    # ---------------------------
    def test_overall_progress_summary(self):
        # No progress yet
        url = reverse("overall-progress-summary")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["total_lessons"], 2)
        self.assertEqual(response.data["completed_lessons"], 0)
        self.assertEqual(response.data["completion_percentage"], 0.0)

        # Complete one lesson
        LessonProgress.objects.create(
            user=self.student, lesson=self.lesson1, is_completed=True
        )

        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["completed_lessons"], 1)
        self.assertEqual(response.data["completion_percentage"], 50.0)

    def test_overall_progress_no_grade(self):
        user_no_grade = User.objects.create_user(
            email="no_grade@example.com",
            username="nograde",
            firebase_uid="nograde_uid",
            grade=None
        )
        self.client.force_authenticate(user_no_grade)
        url = reverse("overall-progress-summary")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    # ---------------------------
    # Last activity view
    # ---------------------------
    def test_last_activity_view(self):
        # Create progress records with different access times
        p1 = LessonProgress.objects.create(
            user=self.student, lesson=self.lesson1)
        p2 = LessonProgress.objects.create(
            user=self.student, lesson=self.lesson2)

        url = reverse("last-activity")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Should return 2 items ordered by last_accessed desc
        self.assertEqual(len(response.data), 2)
        self.assertCountEqual(
            [item["lesson"]["id"] for item in response.data],
            [p1.lesson.id, p2.lesson.id]
        )

    def test_last_activity_with_limit(self):
        LessonProgress.objects.create(user=self.student, lesson=self.lesson1)
        LessonProgress.objects.create(user=self.student, lesson=self.lesson2)

        url = reverse("last-activity")
        response = self.client.get(url, {"limit": 1})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
