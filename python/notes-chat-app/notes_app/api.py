"""REST API нотаток поверх наявних selectors і services Notes Chat App.

View не робить ORM-запитів сам: читання — selectors, зміни — services.
Кожен запит бачить лише нотатки користувача та його груп (захист від IDOR).
"""
from rest_framework import permissions, serializers, viewsets
from rest_framework.decorators import action
from rest_framework.exceptions import NotFound
from rest_framework.response import Response

from . import selectors, services
from .models import Note


class NoteOutputSerializer(serializers.ModelSerializer):
    """Що бачить клієнт: явний список полів, без user і group."""
    priority_label = serializers.CharField(source="get_priority_display", read_only=True)
    notebook = serializers.CharField(source="notebook.title", default=None, read_only=True)

    class Meta:
        model = Note
        fields = ["id", "title", "content", "priority", "priority_label", "is_pinned", "notebook"]


class NoteInputSerializer(serializers.Serializer):
    """Що клієнт може надіслати. Власника задає сервер, а не клієнт."""
    title = serializers.CharField(max_length=200)
    content = serializers.CharField(required=False, allow_blank=True, default="")
    priority = serializers.ChoiceField(choices=Note.PRIORITY_CHOICES, default=Note.PRIORITY_LOW)


class NoteViewSet(viewsets.ViewSet):
    permission_classes = [permissions.IsAuthenticated]

    def _get_note(self, request, pk):
        try:
            return selectors.get_note_detail(request.user, pk)
        except Note.DoesNotExist:
            raise NotFound("Нотатку не знайдено.")

    def list(self, request):
        notes = selectors.get_user_notes(request.user, search=request.query_params.get("search"))
        return Response(NoteOutputSerializer(notes, many=True).data)

    def retrieve(self, request, pk=None):
        return Response(NoteOutputSerializer(self._get_note(request, pk)).data)

    def create(self, request):
        data = NoteInputSerializer(data=request.data)
        data.is_valid(raise_exception=True)
        note = services.create_note(user=request.user, **data.validated_data)
        return Response(NoteOutputSerializer(note).data, status=201)

    @action(detail=True, methods=["post"])
    def pin(self, request, pk=None):
        note = services.toggle_pin_note(self._get_note(request, pk))
        return Response(NoteOutputSerializer(note).data)
