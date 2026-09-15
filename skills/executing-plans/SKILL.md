---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
---

## CRITICAL CONSTRAINTS

**You MUST NOT call `EnterPlanMode` or `ExitPlanMode` during this skill.** This skill operates in normal mode, executing a plan that already exists on disk. Plan mode is unnecessary and dangerous here — it restricts Write/Edit tools needed for implementation.

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Note:** Superpowers works best with subagent support. If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## Consulting the Plan Author

Once, at start: run ListAgents and check whether the plan-writing session is alive (the handoff prompt normally names it). If it is, note its name — on every ambiguity or design question during execution, ask IT via SendMessage before guessing and before interrupting your human partner. If it is not listed, ambiguities go to your human partner.

## The Process

### Step 0: Load Persisted Tasks

1. Call `TaskList` to check for existing native tasks
2. **Locate the tasks file:** try `<plan-path>.tasks.json`; if not found, glob for a matching `.tasks.json`
3. If tasks file exists AND native tasks empty: recreate from JSON using TaskCreate:
   - Include full `description` from .tasks.json (not just subject)
   - Include `metadata` field if present (files, verifyCommand, acceptanceCriteria)
   - Restore `blockedBy` with TaskUpdate
4. If native tasks exist: verify they match plan, resume from first `pending`/`in_progress`
5. If neither: proceed to Step 1b to bootstrap from plan

Update `.tasks.json` after every task status change.

### Step 0.5: Settle the Workspace

Worktrees are opt-in — created only when your human partner asked for one (conversation, instruction file, or the plan). **REQUIRED SUB-SKILL:** `superpowers:using-git-worktrees` — its Step 0 decides:

1. `git worktree list` shows one for this plan's branch, or you are already inside a linked worktree: **cd into / stay in it — do NOT create another**
2. Isolation was requested and none exists: the skill creates one
3. Nothing was requested: work in place in the current checkout on the current branch — no worktree, no consent prompt

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Proceed to task setup

### Step 1b: Bootstrap Tasks from Plan (if needed)

If TaskList returned no tasks or tasks don't match plan:

1. Parse the plan document for `## Task N:` or `### Task N:` headers
2. For each task found, use TaskCreate with:
   - subject: The task title from the plan
   - description: Full structured content (Goal, Files, Acceptance Criteria, Verify, Steps) with `json:metadata` code fence at the end containing files, verifyCommand, acceptanceCriteria
   - activeForm: Present tense action (e.g., "Implementing X")
3. **Dependencies:** for each task with `blockedBy` in the plan or `.tasks.json`:
   - Call `TaskUpdate` with `taskId` and `addBlockedBy: [list-of-blocking-task-ids]`
   - Without the edges the tasks execute in the wrong order
4. Call `TaskList` and verify blockedBy relationships show correctly (e.g., "blocked by #1, #2")

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. **Use metadata for verification:** Parse the `json:metadata` code fence from the task description. Run `verifyCommand` and check each `acceptanceCriteria` before marking complete.
4. Mark as completed
5. **Sync `.tasks.json`:** Read the tasks file, update the task's `"status"` to `"completed"` (or `"in_progress"` in step 1), set `"lastUpdated"` to current ISO timestamp, write back. This keeps the persistence file in sync with native tasks for cross-session resume.

### Step 3: Complete Development

After all tasks complete and verified:
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Settles the workspace (in place by default; worktree only when requested)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
