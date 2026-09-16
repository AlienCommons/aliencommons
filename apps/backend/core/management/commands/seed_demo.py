"""Stable presentation fixtures for disposable local databases only."""

from datetime import UTC, datetime
from uuid import NAMESPACE_URL, uuid5

from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from articles.models import (
    Article,
    ArticlePublication,
    ArticlePublicationVersion,
    ArticleSnapshot,
    ArticleSource,
)
from articles.services.articles import ArticleWorkflow
from bookmarks.models import BookmarkFolder
from posts.models import CommunityPost
from users.models import EmailAddress

DEMO_PASSWORD = "local-demo-only"
DEMO_DATE = datetime(2026, 1, 1, tzinfo=UTC)


def demo_id(name):
    return uuid5(NAMESPACE_URL, f"https://aliencommons.invalid/demo/{name}")


class Command(BaseCommand):
    help = "Create idempotent demo fixtures in an explicitly enabled disposable environment."

    @transaction.atomic
    def handle(self, *args, **options):
        if not getattr(settings, "ALLOW_DEMO_DATA", False):
            raise CommandError("Demo data is disabled. Use make browser-backend.")

        users = {}
        for role in ("reader", "author", "moderator"):
            user, created = get_user_model().objects.get_or_create(
                id=demo_id(role),
                defaults={
                    "username": f"demo-{role}",
                    "is_moderator": role == "moderator",
                    "is_email_verified": True,
                    "date_joined": DEMO_DATE,
                },
            )
            if created:
                user.set_password(DEMO_PASSWORD)
                user.save(update_fields=["password"])
            EmailAddress.objects.get_or_create(
                user=user,
                email=f"{role}@demo.invalid",
                defaults={"is_verified": True, "is_primary": True},
            )
            BookmarkFolder.objects.get_or_create(
                user=user, name=settings.DEFAULT_BOOKMARK_FOLDER_NAME,
            )
            users[role] = user

        for status in Article.ArticleStatus:
            key = status.label.lower()
            title = f"Demo {key} article"
            markdown = f"# {title}\n\nA repeatable Technical Minecraft example."
            article, _ = Article.objects.get_or_create(
                id=demo_id(f"article/{key}"),
                defaults={"author": users["author"], "status": status},
            )
            ArticleSource.objects.get_or_create(
                article=article,
                defaults={"title": title, "markdown": markdown},
            )
            if status == Article.ArticleStatus.DRAFT:
                continue
            snapshot, _ = ArticleSnapshot.objects.get_or_create(
                id=demo_id(f"snapshot/{key}"),
                defaults={
                    "article": article,
                    "title": title,
                    "markdown": markdown,
                    "hash": ArticleWorkflow._hash_and_normalize(title, markdown),
                    "source_version": 1,
                    "moderation_status": (
                        ArticleSnapshot.SnapshotStatus.PENDING
                        if status == Article.ArticleStatus.PENDING
                        else ArticleSnapshot.SnapshotStatus.APPROVED
                    ),
                },
            )
            if status == Article.ArticleStatus.PUBLISHED:
                publication, _ = ArticlePublication.objects.get_or_create(
                    id=demo_id("publication"),
                    defaults={"article": article, "published_at": DEMO_DATE},
                )
                # Fixed, trusted HTML keeps the demo independent of AlienMark HTTP.
                # Workflow/rendering behavior is covered by service and parser tests.
                ArticlePublicationVersion.objects.get_or_create(
                    publication=publication,
                    version=1,
                    defaults={
                        "approved_snapshot": snapshot,
                        "title": title,
                        "html": "<p>A repeatable Technical Minecraft example.</p>",
                        "publication_at": DEMO_DATE,
                    },
                )

        CommunityPost.objects.get_or_create(
            id=demo_id("community-post"),
            defaults={
                "author": users["author"],
                "body": "Demo community post about redstone.",
            },
        )
        self.stdout.write(self.style.SUCCESS(
            "Demo ready: reader/author/moderator@demo.invalid; password: local-demo-only"
        ))
