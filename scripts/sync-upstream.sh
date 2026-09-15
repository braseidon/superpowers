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
# Usage: scripts/sync-upstream.sh [ref]   (default upstream/main; pass a tag
# like v6.3.2 to sync to a release. Runnable from anywhere — anchors on its
# own location, not cwd)
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

REF="${1:-upstream/main}"

PURGE=(
  .agents
  .codex-plugin
  .cursor-plugin
  .kimi-plugin
  .opencode
  .pi
  GEMINI.md
  docs/README.kimi.md
  docs/README.opencode.md
  docs/porting-to-a-new-harness.md
  gemini-extension.json
  hooks/hooks-cursor.json
  package.json
  scripts/package-codex-plugin.sh
  scripts/sync-to-codex-plugin.sh
  skills/using-superpowers/references/antigravity-tools.md
  skills/using-superpowers/references/pi-tools.md
  tests/antigravity
  tests/codex
  tests/codex-plugin-sync
  tests/kimi
  tests/opencode
  tests/pi
  commands/brainstorm.md
  commands/execute-plan.md
  commands/write-plan.md
  commands/gate-check.md
  commands/specify-gate.md
  skills/checking-gates
  skills/specifying-gates
  docs/user-gate-flow.md
  hooks/examples/post-task-complete-revalidate.sh
  hooks/examples/stop-revalidate-user-gates.sh
  hooks/examples/post-agent-return-validate.sh
  tests/claude-code/test-user-gate-hooks.sh
  skills/using-git-worktrees
  skills/finishing-a-development-branch
  commands/onboard.md
  hooks/check-onboard-drift
  hooks/onboard-features.json
  tests/claude-code/test-worktree-path-policy.sh
  tests/claude-code/test-worktree-opt-in.sh
  tests/claude-code/test-worktree-native-preference.sh
)

OURS_PINNED=(
  .claude-plugin/marketplace.json
  .claude-plugin/plugin.json
  .github/FUNDING.yml
  .version-bump.json
)

git fetch upstream

if git merge "$REF" --no-edit; then
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
git --no-pager diff "$REF" -- "${OURS_PINNED[@]}"
echo ""
echo "Review the diff above: rename-only lines are fine; anything else"
echo "(version bumps, new fields, hook logic) should be ported by hand."
