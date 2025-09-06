from django.urls import reverse
from users.serializers import UserSerializer
from rest_framework.test import APITestCase
from django.test import TestCase
from users.models import User


# model tests
class UserModelTest(TestCase):
    def test_create_user(self):
        user = User.objects.create_user(
            email="test@example.com", username="testuser", password="password123")
        self.assertEqual(user.email, "test@example.com")
        self.assertTrue(user.check_password("password123"))
        self.assertFalse(user.is_staff)


# serializer tests
class UserSerializerTest(APITestCase):
    def test_serializer_valid_data(self):
        data = {"email": "user@test.com",
                "username": "user1", "password": "pass123456"}
        serializer = UserSerializer(data=data)
        self.assertTrue(serializer.is_valid())

    def test_serializer_invalid_data(self):
        data = {"email": "user@test.com",
                "username": "user1", "password": "pass123"}
        serializer = UserSerializer(data=data)
        self.assertFalse(serializer.is_valid())


# API (Views) tests
class UserAPITest(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="test@example.com", username="testuser", password="password123")

    def test_signup_creates_user(self):
        url = reverse("signup")
        data = {"email": "hello@example.com",
                "username": "hello", "password": "newpass123"}
        reponse = self.client.post(url, data, format='json')

        self.assertEqual(reponse.status_code, 201)
        self.assertTrue(User.objects
                        .filter(email="hello@example.com").exists())
        
    def test_signup_rejects_staff_parameters(self):
        url = reverse("signup")
        data = {"email": "hello@example.com",
                "username": "hello", "password": "newpass123",
                "is_staff": True, "is_superuser": True}
        
        reponse = self.client.post(url, data, format='json')

        self.assertEqual(reponse.status_code, 400)
        self.assertFalse(User.objects
                        .filter(email="hello@example.com").exists())

    def test_signup_missing_email(self):
        url = reverse("signup")
        data = {"username": "hello", "password": "short"}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, 400)

    def test_signup_missing_username(self):
        url = reverse("signup")
        data = {"email": "hello@example.com", "password": "newpass123"}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, 400)

    def test_signup_used_username(self):
        url = reverse("signup")
        data = {"email": "hello@example.com",
                "username": "testuser", "password": "newpass123"}
        response = self.client.post(url, data, format='json')
        self.assertEqual(response.status_code, 400)

    def test_login_returns_tokens(self):
        url = reverse("login")
        response = self.client \
            .post(url, {"email": "test@example.com", "password": "password123"})

        self.assertEqual(response.status_code, 200)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)

    def test_profile_requires_auth(self):
        url = reverse("profile")
        # No token
        response = self.client.get(url)
        self.assertEqual(response.status_code, 401)

    def test_profile_update(self):
        url = reverse("profile")

        # Login to get token
        login_response = self.client.post(
            reverse("login"), {"email": "test@example.com", "password": "password123"})
        token = login_response.data["access"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")

        # Update profile
        response = self.client.put(
            url, {"username": "updateduser"}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["username"], "updateduser")
