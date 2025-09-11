from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin, BaseUserManager
from django.utils import timezone


class CustomUserManager(BaseUserManager):
    def create_user(self, email, username, password=None, firebase_uid=None, **extra_fields):
        if not email:
            raise ValueError("The Email field must be set")
        if not username:
            raise ValueError("The Username field must be set")

        email = self.normalize_email(email)
        extra_fields.setdefault("is_active", True)

        user = self.model(
            email=email,
            username=username,
            firebase_uid=firebase_uid,
            **extra_fields
        )

        if password:
            # Local user
            user.set_password(password)
        elif firebase_uid:
            # Firebase-managed user, no password
            user.set_unusable_password()
        else:
            raise ValueError(
                "Either a password or firebase_uid must be provided")

        user.save(using=self._db)
        return user

    def create_superuser(self, email, username, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self.create_user(email, username, password=password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    username = models.CharField(max_length=150, unique=True)
    created_at = models.DateTimeField(default=timezone.now)
    firebase_uid = models.CharField(
        max_length=128, unique=True, null=True, blank=True)
    birth_date = models.DateField(null=True, blank=True)
    grade = models.ForeignKey(
        "learning.Grade",  # app_label.ModelName
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="users"
    )

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    objects = CustomUserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["username"]

    def __str__(self):
        return self.email
