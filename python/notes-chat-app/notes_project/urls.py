import os

from django.contrib import admin
from django.contrib.auth import views as auth_views
from urllib.parse import urlencode

from django.http import HttpRequest, HttpResponseRedirect
from django.urls import path, include
from debug_toolbar.toolbar import debug_toolbar_urls
from rest_framework.routers import DefaultRouter

from notes_app.api import NoteViewSet

# REST API: /api/notes/, /api/notes/<id>/, /api/notes/<id>/pin/ (див. notes_app/api.py)
router = DefaultRouter()
router.register("notes", NoteViewSet, basename="api-note")

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include(router.urls)),
    # Django built-in auth: login, logout, password change
    path("accounts/", include("django.contrib.auth.urls")),
    path("", include("notes_app.urls", namespace="notes_app")),
] + debug_toolbar_urls()

if os.environ.get("RICOCHET_URL") and os.environ.get("RICOCHET_CONTENT_ID"):
    # Ricochet handles sign-in, so the app's login page sends visitors to Ricochet's
    # sign-in page, which returns them to `next` afterwards.
    def ricochet_signin(request: HttpRequest) -> HttpResponseRedirect:
        url = f"{os.environ['RICOCHET_URL']}/app/{os.environ['RICOCHET_CONTENT_ID']}/signin"
        if next_path := request.GET.get("next"):
            url += "?" + urlencode({"next": next_path})
        return HttpResponseRedirect(url)

    urlpatterns.insert(0, path("accounts/login/", ricochet_signin, name="login"))
