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
