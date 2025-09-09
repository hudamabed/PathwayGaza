from rest_framework.authentication import BaseAuthentication
from rest_framework import exceptions
from firebase_admin import auth as firebase_auth
from django.utils import timezone
from .models import User


class FirebaseAuthentication(BaseAuthentication):
    """
    Authenticate requests with Firebase ID tokens.
    Expected header: Authorization: Bearer <idToken>
    """

    def authenticate(self, request):
        auth_header = request.headers.get("Authorization")
        if not auth_header:
            return None

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != "bearer":
            return None

        id_token = parts[1]

        try:
            decoded_token = firebase_auth.verify_id_token(id_token)
        except firebase_auth.ExpiredIdTokenError:
            raise exceptions.AuthenticationFailed(
                "Firebase ID token has expired")
        except firebase_auth.RevokedIdTokenError:
            raise exceptions.AuthenticationFailed(
                "Firebase ID token has been revoked")
        except Exception as e:
            raise exceptions.AuthenticationFailed(
                f"Invalid Firebase ID token ({str(e)})")

        uid = decoded_token.get("uid")
        email = decoded_token.get("email")
        if not uid or not email:
            raise exceptions.AuthenticationFailed(
                "Firebase token missing UID or email")

        # Find user by firebase_uid
        user, created = User.objects.get_or_create(
            firebase_uid=uid,
            defaults={
                "email": email,
                "username": decoded_token.get("displayName") or email.split("@")[0],
                "is_active": True,
            },
        )

        if created:
            user.set_unusable_password()
            user.save(update_fields=["password"])

        # Update fields if they changed in Firebase
        update_fields = []
        if user.email != email:
            user.email = email
            update_fields.append("email")

            user.last_login = timezone.now()
            update_fields.append("last_login")

        if update_fields:
            user.save(update_fields=update_fields)

        # Return a (user, auth) tuple — DRF expects this
        return (user, decoded_token)
