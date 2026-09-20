"""URL utilities for web crawling.

These helpers normalize crawl URLs and identify URL patterns that
should be excluded before crawling.
"""

from urllib.parse import urldefrag, urlparse, urlunparse


def normalize_url(url: str) -> str:
    """Return a canonicalized version of a URL.

    The normalization removes fragments, lowercases only the hostname,
    preserves path casing, retains explicit ports, and removes trailing
    slashes except for the root path.

    This helps reduce duplicate URL variants without modifying
    potentially case-sensitive URL paths.
    """
    url, _ = urldefrag(url)
    parsed = urlparse(url)

    host = parsed.hostname.lower() if parsed.hostname else ""

    netloc = host
    if parsed.port:
        netloc = f"{host}:{parsed.port}"

    path = parsed.path
    if path != "/" and path.endswith("/"):
        path = path.rstrip("/")

    return urlunparse(
        (
            parsed.scheme,
            netloc,
            path,
            parsed.params,
            parsed.query,
            "",
        )
    )


def has_email_like_path(url: str) -> bool:
    """Return True when a URL path appears to contain an email address."""
    parsed = urlparse(normalize_url(url))
    return "@" in parsed.path
