import random
import re
import requests
import webbrowser
import clipboard
import dialogs
from bs4 import BeautifulSoup

BASE = "https://dreimetadaten.de/"
EP_META_FMT = BASE + "data/Serie/{num}/metadata.json"


def get_highest_episode() -> int:
    r = requests.get(BASE)
    r.raise_for_status()
    soup = BeautifulSoup(r.text, "html.parser")
    text = soup.get_text(" ", strip=True)
    nums = [int(m.group()) for m in re.finditer(r"\b\d{1,3}\b", text)]
    return max(n for n in nums if 1 <= n <= 999)


def fetch_episode_metadata(n: int) -> dict:
    num = f"{n:03d}"
    r = requests.get(EP_META_FMT.format(num=num))
    r.raise_for_status()
    return r.json()


def get_title(meta: dict) -> str:
    for key in ("titel", "Titel", "title", "Title", "name", "Name"):
        if isinstance(meta.get(key), str):
            return meta[key]
    return "Unbekannter Titel"


def find_apple_music_url(meta: dict) -> str | None:
    def walk(v):
        if isinstance(v, dict):
            for vv in v.values():
                yield from walk(vv)
        elif isinstance(v, list):
            for vv in v:
                yield from walk(vv)
        elif isinstance(v, str):
            yield v

    for v in walk(meta):
        if "music.apple.com" in v or "itunes.apple.com" in v:
            return v
    return None


def open_in_apple_music(url_https: str | None):
    """Open Apple Music (or Safari fallback)."""
    safari = webbrowser.get("safari")  # ✅ use Safari directly
    if url_https:
        safari.open(url_https)
    else:
        safari.open("music://")  # directly opens Apple Music app


def ask_yes_no(title: str, message: str) -> bool:
    result = dialogs.alert(title, message, "Ja", "Nochmal Neu", hide_cancel_button=False)
    return result == 1


def suggest_episode():
    highest = get_highest_episode()
    while True:
        n = random.randint(1, highest)
        try:
            meta = fetch_episode_metadata(n)
        except Exception:
            continue

        title = get_title(meta)
        if ask_yes_no("🎧 Willst Du \"Die drei ???", f"Folge {n:03d}: {title}\" hören?"):
            apple_url = find_apple_music_url(meta)
            if apple_url:
                clipboard.set(apple_url)
            else:
                clipboard.set(f"Die drei ??? Folge {n:03d} - {title}")
                dialogs.alert(
                    "Kein Apple-Music-Link",
                    f"Ich habe den Titel kopiert:\nDie drei ??? Folge {n:03d} - {title}",
                    "OK",
                    hide_cancel_button=True,
                )
            open_in_apple_music(apple_url)
            break


if __name__ == "__main__":
    suggest_episode()
