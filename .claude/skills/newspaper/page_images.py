"""Print the share image (og:image or twitter:image) of each page URL, one line per URL.

Usage: og_image.py URL [URL ...]

Look at each image before you use it. Many share images are a logo or a site-wide card.
"""

import sys
import urllib.request
from html.parser import HTMLParser


class Meta(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.image: str | None = None

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        named = dict(attrs)
        if tag == "meta" and not self.image and (named.get("property") or named.get("name")) in ("og:image", "twitter:image"):
            self.image = named.get("content")


def image(url: str) -> str | None:
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (newspaper skill)"})
    with urllib.request.urlopen(request, timeout=15) as response:
        page = response.read(2_000_000).decode("utf-8", "replace")
    meta = Meta()
    meta.feed(page)
    return meta.image


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    for url in sys.argv[1:]:
        try:
            print(f"{url}\t{image(url) or '-'}")
        except OSError as error:
            print(f"{url}\terror: {error}")


if __name__ == "__main__":
    main()
