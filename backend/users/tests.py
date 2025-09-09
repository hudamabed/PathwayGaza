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
    def test_serializer_valid_data_for_local_user(self):
        data = {"email": "user@test.com",
                "username": "user1", "password": "pass123456"}
        serializer = UserSerializer(data=data)
        self.assertTrue(serializer.is_valid())

    def test_serializer_invalid_data_short_password(self):
        data = {"email": "user@test.com",
                "username": "user1", "password": "pass123"}
        serializer = UserSerializer(data=data)
        self.assertFalse(serializer.is_valid())

    def test_serializer_invalid_staff_data(self):
        data = {
            "email": "user@test.com",
            "username": "user1",
            "password": "pass123456",
            "is_staff": True,
            "is_superuser": True
        }
        serializer = UserSerializer(data=data)
        self.assertFalse(serializer.is_valid())

    def test_serializer_update_only_username(self):
        user = User.objects.create_user(
            email="firebase@example.com",
            username="oldname",
            firebase_uid='testme',
        )
        serializer = UserSerializer(
            user, data={"username": "newname", "email": "hacker@test.com"}, partial=True)
        serializer.is_valid(raise_exception=True)
        updated_user = serializer.save()
        self.assertEqual(updated_user.username, "newname")
        # email unchanged
        self.assertEqual(updated_user.email, "firebase@example.com")


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

    def test_profile_update_username(self):
        self.client.force_authenticate(user=self.superuser)

        url = reverse("profile")
        response = self.client.patch(
            url, {"username": "updateduser"}, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["username"], "updateduser")

    def test_cannot_update_email_or_password(self):
        self.client.force_authenticate(user=self.superuser)
        url = reverse("profile")
        response = self.client.patch(
            url, {"email": "new@example.com", "password": "newpass123"}, format="json"
        )

        self.assertEqual(response.status_code, 200)
        user = User.objects.get(pk=self.superuser.pk)
        self.assertEqual(user.email, "admin@example.com")  # unchanged
        self.assertTrue(user.check_password("adminpass123"))  # unchanged

    def test_profile_get_does_not_change_username(self):
        # Simulate a GET request (profile view triggers get_or_create)
        self.client.force_authenticate(user=self.superuser)
        url = reverse("profile")
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)

        user = User.objects.get(pk=self.superuser.pk)

        # Reload user from DB
        user.refresh_from_db()
        # Ensure username is unchanged
        self.assertEqual(user.username, "adminuser")
