import nh3

PUBLISHED_HTML_CLEANER = nh3.Cleaner(
    tags={
        "a",
        "blockquote",
        "code",
        "em",
        "h1",
        "h2",
        "h3",
        "h4",
        "hr",
        "img",
        "li",
        "ol",
        "p",
        "pre",
        "strong",
        "ul",
    },
    clean_content_tags={"script", "style"},
    attributes={
        "a": {"href"},
        "code": {"class"},
        "img": {"alt", "src"},
        "ol": {"start"},
    },
    link_rel="noopener noreferrer",
    url_schemes={"http", "https", "mailto"},
)


def sanitize_published_html(value: str) -> str:
    """Return the safe HTML subset supported by the article renderer."""
    return PUBLISHED_HTML_CLEANER.clean(value)
