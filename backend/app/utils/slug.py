import re
import unicodedata


def slugify(value: str) -> str:
    """Convert text into a lowercase URL-safe slug."""

    normalized = unicodedata.normalize("NFKD", value)
    ascii_value = normalized.encode("ascii", "ignore").decode("ascii")
    lowercase_value = ascii_value.lower().strip()

    return re.sub(r"[^a-z0-9]+", "-", lowercase_value).strip("-")