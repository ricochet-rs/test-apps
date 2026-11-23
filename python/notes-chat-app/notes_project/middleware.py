"""Temporary debug middleware — catch and print all 500 exceptions."""
import logging
import os
import traceback
from collections.abc import Callable

import jwt
from django.contrib.auth import login
from django.contrib.auth.models import User
from django.core.exceptions import MiddlewareNotUsed
from django.http import HttpRequest, HttpResponse

from notes_app.models import UserProfile

logger = logging.getLogger(__name__)


class DebugExceptionMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            response = self.get_response(request)
            if response.status_code == 500:
                print(f"[MW 500] {request.method} {request.path} → 500", flush=True)
            return response
        except Exception as exc:
            tb = traceback.format_exc()
            print(f"[MW EXCEPTION] {request.method} {request.path} → {exc}", flush=True)
            print(tb, flush=True)
            return HttpResponse(f"<pre>{tb}</pre>", status=500, content_type='text/html')


class RicochetUserMiddleware:
    def __init__(self, get_response: Callable[[HttpRequest], HttpResponse]) -> None:
        if not os.environ.get("RICOCHET_CONTENT_ID"):
            raise MiddlewareNotUsed
        self.get_response = get_response
        self.content_id = os.environ["RICOCHET_CONTENT_ID"]
        self.jwks = jwt.PyJWKClient(f"{os.environ['RICOCHET_URL']}/.well-known/jwks.json")

    def __call__(self, request: HttpRequest) -> HttpResponse:
        # Without a token the visitor falls through to the app's own login page.
        token = request.headers.get("X-Ricochet-User")
        if token:
            try:
                signing_key = self.jwks.get_signing_key_from_jwt(token)
                claims = jwt.decode(
                    token,
                    signing_key.key,
                    algorithms=[signing_key.algorithm_name or "RS256"],
                    audience=self.content_id,
                )
            except jwt.PyJWTError as exc:
                logger.warning("Ignoring invalid Ricochet user token: %s", exc)
            else:
                profile = (
                    UserProfile.objects.select_related("user")
                    .filter(ricochet_sub=claims["sub"])
                    .first()
                )
                if profile is None:
                    email = claims.get("email") or ""
                    username = email if email and not User.objects.filter(username=email).exists() else claims["sub"]
                    user = User.objects.create_user(username=username[:150], email=email)
                    profile = UserProfile.objects.create(
                        user=user,
                        ricochet_sub=claims["sub"],
                        display_name=(claims.get("name") or "")[:100],
                    )
                if request.user.pk != profile.user_id:
                    login(request, profile.user, backend="django.contrib.auth.backends.ModelBackend")
        return self.get_response(request)
