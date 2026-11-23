from django.contrib.auth.models import Group, User
from rest_framework.test import APITestCase

from notes_app import services


class NoteApiTests(APITestCase):
    def setUp(self):
        self.alice = User.objects.create_user("alice", password="pass-alice")
        self.bob = User.objects.create_user("bob", password="pass-bob")
        self.family = Group.objects.create(name="Сім'я")
        self.alice.groups.add(self.family)
        self.bob.groups.add(self.family)
        self.private = services.create_note(user=self.alice, title="Особиста нотатка Аліси")
        self.shared = services.create_note(user=self.alice, title="Список покупок", group=self.family)

    def test_login_required(self):
        self.assertEqual(self.client.get("/api/notes/").status_code, 403)

    def test_bob_sees_only_group_notes(self):
        self.client.force_authenticate(self.bob)
        titles = [n["title"] for n in self.client.get("/api/notes/").data]
        self.assertEqual(titles, ["Список покупок"])
        self.assertEqual(self.client.get(f"/api/notes/{self.private.pk}/").status_code, 404)

    def test_create_sets_owner_from_request(self):
        self.client.force_authenticate(self.bob)
        response = self.client.post("/api/notes/", {"title": "Нотатка Боба", "priority": 4}, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["priority_label"], "🔴 Терміново")
        self.assertEqual(services.Note.objects.get(pk=response.data["id"]).user, self.bob)

    def test_pin_toggles(self):
        self.client.force_authenticate(self.alice)
        first = self.client.post(f"/api/notes/{self.private.pk}/pin/").data["is_pinned"]
        second = self.client.post(f"/api/notes/{self.private.pk}/pin/").data["is_pinned"]
        self.assertEqual((first, second), (True, False))
