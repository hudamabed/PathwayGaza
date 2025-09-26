"""
URL configuration for core project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from rest_framework import permissions

from drf_yasg.views import get_schema_view
from drf_yasg import openapi


schema_view = get_schema_view(
    openapi.Info(
        title="PathwayGaza API",
        default_version="v1",
        description="API documentation for Django project",
        contact=openapi.Contact(email="contact@example.com"),
        license=openapi.License(name="MIT License"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

schema_view.security_definitions = {
    "Bearer": {
        "type": "apiKey",
        "name": "Authorization",
        "in": "header",
        "description": "Paste the full value including 'Bearer'. Example:\n\n"
                       "`Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...`",
    }
}
schema_view.security = [{"Bearer": []}]

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/learning/', include('learning.urls')),
    path('api/progress/', include('progress.urls')),
    path('api/quizzes/', include('quizzes.urls')),
    path(
        'health/',
        lambda request: JsonResponse({'status': 'ok'}), name='health_check',
    ),
    # path(r"swagger(<format>\.json|\.yaml)", schema_view.without_ui(
    #     cache_timeout=0), name="schema-json"),
    path("swagger/", schema_view.with_ui("swagger",
         cache_timeout=0), name="schema-swagger-ui"),
    path("redoc/", schema_view.with_ui("redoc",
         cache_timeout=0), name="schema-redoc"),
]
admin.site.site_header = 'Gaza Pathway'
admin.site.site_title = 'Gaza Pathway'
