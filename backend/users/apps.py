from django.apps import AppConfig
import firebase_admin
from firebase_admin import credentials
import os

class UsersConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'users'

    def ready(self):
        """
        Initialize Firebase app only once when Django starts.
        """
        if not firebase_admin._apps:  # prevent reinitialization on autoreload
            cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)