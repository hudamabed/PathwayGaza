from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


class UserAdmin(BaseUserAdmin):
    model = User
    list_display = (
        "email",
        "username",
        "grade",
        "birth_date",
        "is_staff",
        "is_superuser",
        "is_active",
        "created_at",
    )
    list_filter = ("is_staff", "is_superuser", "is_active", "grade")
    ordering = ("email",)
    fieldsets = (
        (None, {"fields": ("email", "username", "password")}),
        ("Profile info", {"fields": ("birth_date", "grade")}),
        ("Permissions", {"fields": ("is_staff", "is_superuser",
         "is_active", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "created_at")}),
    )
    add_fieldsets = (
        (None, {
            "classes": ("wide",),
            "fields": (
                "email",
                "username",
                "password1",
                "password2",
                "birth_date",
                "grade",
                "is_staff",
                "is_superuser",
                "is_active",
            ),
        }),
    )

admin.site.register(User, UserAdmin)
