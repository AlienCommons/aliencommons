from io import StringIO

from django.contrib.auth import authenticate, get_user_model
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import override_settings

from articles.models import (
    Article,
    ArticlePublication,
    ArticlePublicationVersion,
    ArticleSnapshot,
)
from core.tests.testcases import BaseTestCase
from posts.models import CommunityPost
from users.models import EmailAddress


class SeedDemoTests(BaseTestCase):
    def test_refuses_unconfigured_environment_before_writing(self):
        with self.assertRaisesMessage(CommandError, "Demo data is disabled"):
            call_command("seed_demo", stdout=StringIO())
        self.assertEqual(get_user_model().objects.count(), 0)
        self.assertEqual(Article.objects.count(), 0)

    @override_settings(ALLOW_DEMO_DATA=True)
    def test_repeatable_fixtures_and_real_login(self):
        for _ in range(2):
            call_command("seed_demo", stdout=StringIO())

        self.assertEqual(get_user_model().objects.count(), 3)
        self.assertEqual(EmailAddress.objects.count(), 3)
        self.assertEqual(Article.objects.count(), 4)
        self.assertEqual(ArticleSnapshot.objects.count(), 3)
        self.assertEqual(ArticlePublication.objects.count(), 1)
        self.assertEqual(ArticlePublicationVersion.objects.count(), 1)
        self.assertEqual(CommunityPost.objects.count(), 1)
        self.assertSetEqual(
            set(Article.objects.values_list("status", flat=True)),
            set(Article.ArticleStatus.values),
        )
        for role in ("reader", "author", "moderator"):
            user = authenticate(email=f"{role}@demo.invalid", password="local-demo-only")
            self.assertIsNotNone(user)
            self.assertEqual(user.is_moderator, role == "moderator")
            self.assertFalse(user.is_staff)
            self.assertFalse(user.is_superuser)

        publication = ArticlePublication.objects.get()
        self.assertEqual(publication.latest_version().title, "Demo published article")

    @override_settings(ALLOW_DEMO_DATA=True)
    def test_rerun_preserves_local_edits(self):
        call_command("seed_demo", stdout=StringIO())
        post = CommunityPost.objects.get()
        post.body = "Locally edited demo"
        post.save()
        call_command("seed_demo", stdout=StringIO())
        post.refresh_from_db()
        self.assertEqual(post.body, "Locally edited demo")
