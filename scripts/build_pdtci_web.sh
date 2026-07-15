#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT_DIR/build/pdtci_web"

cd "$ROOT_DIR"

rm -rf "$OUT_DIR"

flutter build web \
  --release \
  --target lib/main_tci_standalone.dart

mkdir -p "$OUT_DIR"
rsync -a --delete "$ROOT_DIR/build/web/" "$OUT_DIR/"

python3 - <<'PY'
import json
from pathlib import Path

index = Path('build/pdtci_web/index.html')
text = index.read_text()
text = text.replace('<title>propofol_dreams_app</title>', '<title>Propofol Dreams TCI</title>')
text = text.replace('<title>Propofol Dreams</title>', '<title>Propofol Dreams TCI</title>')
index.write_text(text)

manifest = Path('build/pdtci_web/manifest.json')
if manifest.exists():
    data = json.loads(manifest.read_text())
    data['name'] = 'Propofol Dreams TCI'
    data['short_name'] = 'PDTci'
    data['description'] = 'Standalone Propofol Dreams TCI calculator'
    data['theme_color'] = '#000000'
    data['background_color'] = '#000000'
    manifest.write_text(json.dumps(data, indent=2) + '\n')
PY

printf 'Built standalone PDTci web output at %s\n' "$OUT_DIR"
