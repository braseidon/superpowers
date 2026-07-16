#!/usr/bin/env bash
# Sync this fork with upstream (pcvelz/superpowers) while enforcing fork policy:
#
#  1. PURGE list — non-Claude AI tooling we deleted on purpose. gitattributes
#     merge drivers can't enforce deletions (delete-vs-modify = conflict, new
#     upstream files under a purged dir merge in cleanly), so this script
#     re-deletes them after every merge.
#  2. merge=ours pins (.gitattributes) — fork-rename files. Silently keep our
#     version, so upstream structural changes (e.g. version bumps, new fields)
#     are dropped; the report at the end surfaces any drift to review.
#
# Usage: scripts/sync-upstream.sh   (runnable from anywhere — anchors on its
# own location, not cwd)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

PURGE=(
  .codex-plugin
  .cursor-plugin
  .opencode
  GEMINI.md
  docs/README.opencode.md
  gemini-extension.json
  hooks/hooks-cursor.json
  package.json
  scripts/sync-to-codex-plugin.sh
  tests/codex-plugin-sync
  tests/opencode
)

OURS_PINNED=(
  .claude-plugin/marketplace.json
  .claude-plugin/plugin.json
  .github/FUNDING.yml
  hooks/session-start
)

git fetch upstream

if git merge upstream/main --no-edit; then
  # Clean merge — but upstream may have added new files under purged paths.
  git rm -r -f -q --ignore-unmatch -- "${PURGE[@]}"
  if ! git diff --cached --quiet; then
    git commit -m "chore: re-purge non-Claude files after upstream merge"
  fi
else
  # Conflicts. Resolve purge-path conflicts by keeping them deleted.
  git rm -r -f -q --ignore-unmatch -- "${PURGE[@]}"
  if [ -n "$(git ls-files -u)" ]; then
    echo ""
    echo "!! Non-purge conflicts remain — resolve manually, then: git commit --no-edit"
    git ls-files -u | awk '{print $4}' | sort -u
    exit 1
  fi
  git commit --no-edit
fi

echo ""
echo "== merge=ours drift check (expected: name/author/repo rename only) =="
git --no-pager diff upstream/main -- "${OURS_PINNED[@]}"
echo ""
echo "Review the diff above: rename-only lines are fine; anything else"
echo "(version bumps, new fields, hook logic) should be ported by hand."
