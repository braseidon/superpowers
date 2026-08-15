---
name: using-git-worktrees
description: Use when starting feature work or before executing an implementation plan, to settle where the work happens - worktrees are opt-in, created only when your human partner asked for one; otherwise work stays in the current checkout
---

# Using Git Worktrees

## Overview

Worktrees are **opt-in**. Work happens in the current checkout unless your human partner asked for isolation. When they did, prefer your platform's native worktree tools; fall back to manual git worktrees only when no native tool is available.

**Core principle:** No request, no worktree. Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

**Announce at start:** "I'm using the using-git-worktrees skill to settle the workspace."

## Step 0: Was Isolation Requested? Are You Already Isolated?

**A worktree exists only because your human partner asked for one.** A request is explicit: this conversation, an instruction file (CLAUDE.md, AGENTS.md), or the plan itself says "worktree" / "isolated workspace". A plan-execution skill routing you here is NOT a request — it is asking you to run this check.

**No request → work in place.** Do not ask "would you like a worktree?" — that question manufactures the request; the answer is already no. Skip to Step 3 and run the baseline in the current checkout. Report: "Working in place at `<path>` on branch `<name>`."

**A fresh worktree is also not a scratch checkout** — not even `git worktree add --detach <tmp> HEAD` to measure a "before" state. Pre-change comparisons come from a baseline captured before editing, or from `git show <sha>:<path>` / `git diff <sha>` on individual files. No baseline captured and a delta is wanted? Report the absolute number and say no baseline exists — never build one from a second working tree.

**Why in place is the default:** a new worktree has none of the gitignored files the current checkout accumulated — installed dependencies (`node_modules/`, `vendor/`), env files, generated data, build output. Tests, type checks, and project CLIs are dead in it until every setup step is re-run, and some setup (secrets, generated caches) cannot be re-run by a script at all. Isolation that cannot run the test suite protects nothing.

**Request confirmed → before creating anything, check if you are already in an isolated workspace.**

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout. Proceed to Step 1.

## Step 1: Create Isolated Workspace

**You have two mechanisms. Try them in this order.**

### 1a. Native Worktree Tools (preferred)

Your human partner asked for an isolated workspace (Step 0) — that request is your authorization to use the native tool. Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 2.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no native worktree tool available.

### 1b. Git Worktree Fallback

**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.

2. **Check for an existing project-local worktree directory:**
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, use it. If both exist, `.worktrees` wins.

3. **If there is no other guidance available**, default to `.worktrees/` at the project root.

#### Safety Verification (project-local directories only)

**MUST verify directory is ignored before creating worktree:**

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:** Add to .gitignore, commit the change, then proceed.

**Why critical:** Prevents accidentally committing worktree contents to repository.

#### Create the Worktree

```bash
# Determine path based on chosen location
path="$LOCATION/$BRANCH_NAME"

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.

## Step 2: Project Setup

Auto-detect and run appropriate setup:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

## Step 3: Verify Clean Baseline

Runs for both outcomes — in place (Step 0) or inside the new worktree. Run tests to ensure the workspace starts clean:

```bash
# Use project-appropriate command
npm test / cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### Report

```
Workspace: <in place at full-path | worktree at full-path> on branch <name>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Step 4: Exit the Worktree (when done)

When feature work is finished, use the native `ExitWorktree` tool — the counterpart to `EnterWorktree` — to clean up. It can remove the worktree, or keep it / discard changes, and unwinds the harness state cleanly.

Prefer this over `git worktree remove`. Reaching for git here leaves the same phantom state your harness can't see or manage that you avoided at create time.

Only fall back to `git worktree remove` if you have no native exit tool available.

## Quick Reference

| Situation | Action |
|-----------|--------|
| Nobody asked for isolation | Work in place, baseline in current checkout (Step 0) — no consent prompt |
| Plan-execution skill routed you here | That is the check, not a request — Step 0 decides |
| Need a "before" state to diff against | Baseline captured before editing, or `git show <sha>:<path>` / `git diff <sha>` — not a worktree; no baseline = report the absolute number |
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |
| Feature work done, cleaning up | Use native `ExitWorktree` (Step 4) |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Asking for consent is harmless — I'll just offer a worktree" | The prompt is the cost: it stalls the run and hands your human partner a decision they already made by not asking. Silence means in place. |
| "The plan touches many files — that deserves isolation" | Scope is not a request. Isolation comes from small, pathspec'd commits. |
| "A clean worktree gives a trustworthy baseline" | A fresh worktree has no dependencies, no env, no generated data — its baseline is "everything fails". Baseline in the checkout that can run the tests. |
| "I only need a throwaway detached checkout to measure the before state" | A second checkout has no installed dependencies or gitignored data — the measurement fails or lies. Use the baseline captured before editing or `git show <sha>:<path>`; with no baseline, report the absolute number and say so. |
| "I'm obviously not in a worktree — no need to check" | Run Step 0. Harness-created isolation and submodules both fool eyeballing; the detection commands settle it. |
| "`git worktree add` is quicker than hunting for a native tool" | A native tool (e.g. `EnterWorktree`) owns placement, branching, and cleanup. Bypassing it is the #1 mistake — it creates phantom state your harness can't see or manage. |
| "The worktree directory is surely ignored already" | Run `git check-ignore`. An unignored worktree directory commits the whole tree into the repo. |
| "Any directory name works" | Explicit instructions beat an existing project-local directory, which beats the `.worktrees/` default. |
| "The workspace is fresh — baseline tests can wait" | A dirty baseline makes every later failure ambiguous. Run the tests now; proceeding past failures is your human partner's call. |
