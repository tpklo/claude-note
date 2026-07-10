#!/bin/bash
# Guard: manifests parse as JSON, skill stays config-driven, and no private
# strings leak into the repo. Private patterns live in internal/private-patterns.txt
# (gitignored) so the guard itself never publishes them.
set -e
cd "$(dirname "$0")/.."

python3 -m json.tool .claude-plugin/marketplace.json >/dev/null && echo "OK marketplace.json"
python3 -m json.tool plugins/linked-notes/.claude-plugin/plugin.json >/dev/null && echo "OK plugin.json"

if [ -f internal/private-patterns.txt ]; then
  if grep -rniE -f internal/private-patterns.txt --exclude-dir=.git --exclude-dir=internal --exclude=spec.md .; then
    echo "FAIL: private string found in tracked files"; exit 1
  fi
  echo "OK leak scan"
else
  echo "SKIP leak scan (internal/private-patterns.txt not present — maintainer-only check)"
fi

grep -q 'linked-notes/config.json' plugins/linked-notes/skills/note/SKILL.md || { echo "FAIL: SKILL.md not config-driven"; exit 1; }

echo "ALL OK"
