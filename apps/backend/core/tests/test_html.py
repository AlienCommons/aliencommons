from django.test import SimpleTestCase

from core.utils.html import sanitize_published_html


class PublishedHtmlSanitizerTests(SimpleTestCase):
    def test_preserves_alienmark_markup(self):
        html = (
            '<h2>Guide</h2><p>Use <strong>redstone</strong>.</p>'
            '<pre><code class="language-ts">const x = 1;</code></pre>'
            '<img src="/media/article_images/guide.webp" alt="Guide">'
            '<a href="https://example.com">Reference</a>'
        )

        sanitized = sanitize_published_html(html)

        self.assertIn("<h2>Guide</h2>", sanitized)
        self.assertIn("<strong>redstone</strong>", sanitized)
        self.assertIn('class="language-ts"', sanitized)
        self.assertIn('src="/media/article_images/guide.webp"', sanitized)
        self.assertIn('href="https://example.com"', sanitized)
        self.assertIn('rel="noopener noreferrer"', sanitized)

    def test_removes_executable_markup_and_unsafe_urls(self):
        html = (
            '<script>alert("xss")</script>'
            '<img src="data:image/svg+xml,unsafe" onerror="alert(1)">'
            '<a href="javascript:alert(1)">unsafe</a>'
        )

        sanitized = sanitize_published_html(html)

        self.assertNotIn("script", sanitized)
        self.assertNotIn("data:", sanitized)
        self.assertNotIn("onerror", sanitized)
        self.assertNotIn("javascript:", sanitized)
