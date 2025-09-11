from django.urls import reverse
from rest_framework.test import APITestCase
from django.test import TestCase
from unittest.mock import patch
from django.contrib.auth import get_user_model

from users.serializers import UserSerializer


User = get_user_model()

# --------------------------
# Model Tests
# --------------------------


class UserModelTest(TestCase):
    def test_create_local_superuser(self):
        user = User.objects.create_superuser(
            email="admin@example.com", username="adminuser", password="password123"
        )
        self.assertEqual(user.email, "admin@example.com")
        self.assertTrue(user.check_password("password123"))
        self.assertTrue(user.is_staff)
        self.assertTrue(user.is_superuser)

    def test_create_firebase_user_unusable_password(self):
        user = User.objects.create_user(
            email="firebase@example.com",
            username="firebaseuser",
            firebase_uid='testme',
        )
        self.assertFalse(user.has_usable_password())
        self.assertEqual(user.email, "firebase@example.com")
        self.assertEqual(user.username, "firebaseuser")


# --------------------------
# Serializer Tests
# --------------------------
class UserSerializerTest(APITestCase):
    def test_serializer_returns_expected_fields(self):
        # Include birth_date and grade_id in the expected fields
        user = User.objects.create_user(
            email="user@test.com", username="user1", firebase_uid="abc123"
        )
        serializer = UserSerializer(instance=user)
        self.assertEqual(set(serializer.data.keys()), {
            "id", "email", "username", "birth_date", "grade_id", "created_at"
        })

    def test_serializer_update_username_birthdate_grade(self):
        # Create a grade for testing
        from learning.models import Grade
        grade = Grade.objects.create(name="Grade 1")

        user = User.objects.create_user(
            email="user@test.com", username="oldname", firebase_uid="abc123"
        )
        data = {
            "username": "newname",
            "birth_date": "2010-05-20",
            "grade_id": grade.id
        }
        serializer = UserSerializer(instance=user, data=data, partial=True)
        self.assertTrue(serializer.is_valid(), serializer.errors)
        serializer.save()

        user.refresh_from_db()
        self.assertEqual(user.username, "newname")
        self.assertEqual(user.birth_date.isoformat(), "2010-05-20")
        self.assertEqual(user.grade, grade)


# --------------------------
# API / Views Tests
# --------------------------
class UserAPITest(APITestCase):
    def setUp(self):
        # Create a local superuser for testing endpoints that require login
        self.superuser = User.objects.create_superuser(
            email="admin@example.com", username="adminuser", password="adminpass123"
        )
        # Mock Firebase calls
        patcher = patch("users.views.auth.update_user")
        self.mock_update_user = patcher.start()
        self.mock_update_user.return_value = None
        self.addCleanup(patcher.stop)  # automatically stop after each test

    def test_profile_requires_auth(self):
        url = reverse("profile")
        response = self.client.get(url)
        self.assertEqual(response.status_code, 401)

    def test_profile_update_all_fields(self):
        self.client.force_authenticate(user=self.superuser)

        from learning.models import Grade
        grade = Grade.objects.create(name="Grade 2")

        url = reverse("profile")
        data = {
            "username": "updateduser",
            "birth_date": "2009-01-01",
            "grade_id": grade.id
        }
        response = self.client.patch(url, data, format="json")
        self.assertEqual(response.status_code, 200)

        user = User.objects.get(pk=self.superuser.pk)
        self.assertEqual(user.username, "updateduser")
        self.assertEqual(user.birth_date.isoformat(), "2009-01-01")
        self.assertEqual(user.grade, grade)

    def test_cannot_update_email(self):
        self.client.force_authenticate(user=self.superuser)
        url = reverse("profile")
        response = self.client.patch(
            url, {"email": "new@example.com"}, format="json")

        self.assertEqual(response.status_code, 200)
        user = User.objects.get(pk=self.superuser.pk)
        self.assertEqual(user.email, "admin@example.com")  # unchanged

    def test_profile_get_does_not_change_eamil(self):
        # Simulate a GET request (profile view triggers get_or_create)
        self.client.force_authenticate(user=self.superuser)
        url = reverse("profile")
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)

        user = User.objects.get(pk=self.superuser.pk)

        # Reload user from DB
        user.refresh_from_db()
        # Ensure email is unchanged
        self.assertEqual(user.email, "admin@example.com")
