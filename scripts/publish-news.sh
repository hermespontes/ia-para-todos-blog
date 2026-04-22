#!/bin/bash

# Script para publicar notícias automaticamente no blog
# Cria posts a partir de feed RSS com parsing robusto (Python XML)

set -euo pipefail

BLOG_DIR="$(pwd)"
POSTS_DIR="$BLOG_DIR/_posts"
NEWS_RSS_URL="${NEWS_RSS_URL:-https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml}"
MAX_POSTS="${MAX_POSTS:-1}"

mkdir -p "$POSTS_DIR"

echo "Buscando notícias mais recentes..."

env POSTS_DIR="$POSTS_DIR" NEWS_RSS_URL="$NEWS_RSS_URL" MAX_POSTS="$MAX_POSTS" python3 - <<'PY'
import os
import re
import sys
import unicodedata
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.request import urlopen
import xml.etree.ElementTree as ET

posts_dir = Path(os.environ["POSTS_DIR"])
rss_url = os.environ["NEWS_RSS_URL"]
max_posts = int(os.environ.get("MAX_POSTS", "1"))


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    text = text.lower().strip()
    text = re.sub(r"[^a-z0-9\s-]", "", text)
    text = re.sub(r"[\s-]+", "-", text).strip("-")
    return text or "post"

try:
    with urlopen(rss_url, timeout=30) as resp:
        xml_data = resp.read()
except Exception as e:
    print(f"Erro ao baixar RSS: {e}", file=sys.stderr)
    sys.exit(1)

try:
    root = ET.fromstring(xml_data)
except ET.ParseError as e:
    print(f"Erro ao parsear RSS: {e}", file=sys.stderr)
    sys.exit(1)

items = root.findall("./channel/item")
if not items:
    print("Nenhuma notícia encontrada no feed.")
    sys.exit(0)

created = 0
for item in items[:max_posts]:
    title = (item.findtext("title") or "Sem título").strip()
    link = (item.findtext("link") or "").strip()
    pub_date_raw = (item.findtext("pubDate") or "").strip()

    if pub_date_raw:
        try:
            dt = parsedate_to_datetime(pub_date_raw)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
        except Exception:
            dt = datetime.now(timezone.utc)
    else:
        dt = datetime.now(timezone.utc)

    date_for_file = dt.strftime("%Y-%m-%d")
    date_for_frontmatter = dt.strftime("%Y-%m-%d %H:%M:%S %z")

    filename = f"{date_for_file}-{slugify(title)}.md"
    path = posts_dir / filename

    if path.exists():
        print(f"Post já existe: {path}")
        continue

    content = f"""---
layout: post
title: \"{title.replace('"', '\\"')}\"
link: \"{link}\"
date: {date_for_frontmatter}
categories: news
---

Originalmente publicado em: [{title}]({link})
"""

    path.write_text(content, encoding="utf-8")
    created += 1
    print(f"Criando post: {path}")

print(f"Publicação de notícias concluída! Criados: {created}")
print(f"Total de posts no blog: {len(list(posts_dir.glob('*.md')))}")
PY
