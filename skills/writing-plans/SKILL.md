---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## CRITICAL CONSTRAINTS — Read Before Anything Else

**You MUST NOT call `EnterPlanMode` or `ExitPlanMode` at any point during this skill.** This skill operates in normal mode and manages its own completion flow via `AskUserQuestion`. Calling `EnterPlanMode` traps the session in plan mode where Write/Edit are restricted. Calling `ExitPlanMode` breaks the workflow and skips the user's execution choice. If you feel the urge to call either, STOP — follow this skill's instructions instead.

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- (User preferences for plan location override this default)

## Model Fit

Plan writing is decomposition from a locked spec — Opus-tier work, written by a FRESH subagent whatever the session model. A fresh writer working from the spec alone is the test that the spec is sufficient input — execution agents get the same isolation later, so a wall the writer hits is a spec gap surfacing early, not friction to route around. In-session plan writing only on explicit user grant.

Dispatched plan writers run at xhigh reasoning effort — use an effort-pinned agent type if available (e.g. `general-xhigh`) with model Opus on the call. Work that earns a plan earns the effort; tiers above xhigh are not worth the expense here.

**Running as a dispatched plan writer:** write the plan through Self-Review, save the plan + `.tasks.json`, commit, and return the plan path. Do NOT run the Execution Handoff — subagents cannot AskUserQuestion. Expect revival: independent-review findings come back to you via resume — apply them, re-run Self-Review's mechanical checks on the amended tasks, commit, and return. The coordinator adjudicates `[FABLE-ADJUDICATE]` markers and runs the handoff itself.

## Escalation Boundaries

Read the spec's `## Plan-stage escalation` section before decomposing. For each listed boundary:

- **Spec already decided it** → cite that decision in the touching task and follow it.
- **Still open** → the touching task states the question and carries a `[FABLE-ADJUDICATE]` marker. Resolving a listed boundary with plan-writer judgment is a plan failure (same severity as No Placeholders) — flag, don't decide.

No such section in the spec → add `**Escalation:** spec predates escalation marking` to the plan header and proceed.

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## REQUIRED FIRST STEP: Initialize Task Tracking

**BEFORE exploring code or writing the plan, you MUST:**

1. Call `TaskList` to check for existing tasks from brainstorming
2. If tasks exist: you will enhance them with implementation details as you write the plan
3. If no tasks: you will create them with `TaskCreate` as you write each plan task

**Do not proceed to exploration until TaskList has been called.** This includes dispatching background or parallel investigation subagents — TaskList is fast and synchronous, so call it FIRST, then fan out any exploration agents.

```
TaskList
```

## Task Granularity

**Each task is a coherent unit of work that produces a testable, committable outcome.**

See `skills/shared/task-format-reference.md` for the full granularity guide.

Key principle: TDD cycles happen WITHIN tasks, not as separate tasks. A task is "Implement X with tests" — the red-green-refactor steps are execution detail inside the task, not task boundaries.

**Scope test:**
1. Can it be verified independently? (if no → too small)
2. Does it touch more than one concern? (if yes → too big)
3. Would it get its own commit? (if no → merge with adjacent task)

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

**Global Constraints:** [Binding requirements every task must respect — exact values, formats, cross-component relationships ("same layout as X", "matches Y"). Execution controllers hand these to every reviewer. "none" if none.]

**User decisions (already made):** [One line per decision the user made during brainstorming/planning, quotable. "none" if none.]

## Review checkpoints

[Every task must appear in exactly one checkpoint. Default is batched review — 1:1 is the exception, and it must name what COMPOUNDS: downstream tasks consume this artifact's shape/semantics before any harness exists to catch a defect, or the task carries an adjudication gate. Risk CATEGORY alone ("it's matching/data work") never justifies 1:1 — on a plan whose whole subject is the risk surface that rule degenerates to per-task review and doubles wall time; local-blast-radius work (a test file's assertions, display flags, an isolated normalizer) batches even there, backed by the plan's own late-stage harness. Tasks whose risk is only jointly checkable (two legs of a parity) review together at the second leg, never separately. Review batching and model routing are independent axes — a batched task still routes its implementer by judgment density, not by batch membership. One line per checkpoint: name, task numbers, one-clause why (for 1:1s: what compounds).]

- Adapters (Tasks 6+7) - matching/scaling is the risk surface, and cross-adapter parity can only be checked once both legs exist
- Mechanical batch (Tasks 5, 9, 10, 11, 13) - one pass before final regression

## Dispatch waves

[Derived from `blockedBy` + `files`, one line per wave: wave 1 = every task with no blockers; wave N+1 = the tasks wave N unblocks, split wherever two tasks' `files` overlap. The execution controller dispatches a whole wave in one message, so every false edge here is wall-clock burned. `blockedBy` carries DATA dependencies only — a symbol, file, fixture, or interface the task consumes that an earlier task creates. "Comes later in the plan", "same area", "feels risky together" are not edges; an overlap in `files` is handled by the wave split, not by an edge.]

- Wave 1: Tasks 0
- Wave 2: Tasks 1, 5, 6, 9 (disjoint files)
- Wave 3: Tasks 2, 7 (7 after 5+6)

---
```

### Deferred decisions

If the plan schedules questions for the user (a DECIDE list, an AskUserQuestion step), each question MUST:
- Cite why it is still open despite the header decisions. If a recorded decision answers it, answer from the record — do not re-ask.
- Carry the facts needed to answer it in the option descriptions: name the artifact AND its role/state (e.g. "stale GitHub mirror, last push 2026-03-25 — separate from your local-tools dev home"), and state what does NOT change under each option.
- Recommend nothing that contradicts a recorded decision. That is a plan failure (same severity as No Placeholders).

## Task Structure

````markdown
### Task N: [Component Name]

**Goal:** [One sentence — what this task produces]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Acceptance Criteria:**
- [ ] [Concrete, testable criterion]
- [ ] [Another criterion]

**Verify:** `exact test command` → expected output

**Steps:**

- [ ] **Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

- [ ] **Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task
- **Project-specific identifiers without provenance** — DB column names, API field names, library function names, schema keys, config flags, domain-specific IDs. If you cannot show a verification command (grep/jq/sql/etc.) above the identifier that produced it, the identifier is a placeholder. Replace with "verify during implementation" and add a Task 0 recon step. **This is where most hallucinations land in plans.**

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

**4. Dependency-order walk:** Walk tasks in order. Every symbol, type, file, or fixture a task consumes must exist by that point — created by an earlier task or verified pre-existing. A task consuming what a later task creates is a sequencing bug.

**5. Test-snippets-run-as-written:** Every test code block carries the setup it needs to actually run — imports, seeds, fixture loads, mocks. A snippet that assumes ambient setup described in another task's prose fails as written.

**6. Single-source mechanisms:** Each mechanism is specified in exactly one task; other tasks reference it by task number instead of restating it. Restated descriptions drift when fix rounds amend one copy and miss the other.

**7. Review checkpoints:** Confirm the `## Review checkpoints` section exists and every task is accounted for in exactly one checkpoint. Every 1:1 names what compounds (downstream consumer of the artifact, or an adjudication gate) — a 1:1 justified only by risk category is a checkpoint to merge.

**8. Escalation coverage:** Every boundary in the spec's `## Plan-stage escalation` section is either covered by a cited spec decision or carries a `[FABLE-ADJUDICATE]` marker. A listed boundary the plan silently decided is a plan failure — restore the flag.

**9. Execution recommendation:** Confirm the plan ends with an **Execution recommendation** line: subagent-driven vs parallel-session, recommended orchestrator model (Fable for judgment-dense coordination, Opus otherwise), one clause why.

**10. Absence criteria vs the plan's own text:** For every criterion that asserts a string's ABSENCE ("`rg foo` returns zero hits under `src/`"), grep the plan for that string. If the plan supplies code, a docblock, or a comment for that scope containing the string, the criterion is unmeetable as written and the implementer must choose between your prose and your gate. Either remove the string from the supplied text, or scope the criterion to imports/code references (`rg "from .*foo"`) instead of any occurrence.

**11. Tier vocabulary (mechanical):** `grep -o '"modelTier": *"[a-z]*"' <plan>.tasks.json | sort | uniq -c` — only `mechanical`, `standard`, `frontier` may appear, and the counts sum to the task count. Any other word (`judgment`, `orchestrator`, prose) is a plan failure: the routing gates reject it and the controller falls back to guessing.

**12. Dispatch waves:** Confirm the `## Dispatch waves` section exists, every task appears in exactly one wave, wave 1 is non-empty, and every `blockedBy` edge names something consumed (walk the edges: if you cannot say what artifact of the blocker the blocked task reads, delete the edge).

**13. Quantified outcome claims (mechanical grep, then verify):** `rg -n -i '\b(all|both|exactly|only|every|never)\b[^.]{0,40}\b(tests?|reds?|greens?|redden|fail|pass)' <plan>` — every hit that predicts a test outcome (which tests redden under a mutation, how many, "both stay green") is either produced by a command the plan cites (Facts table or the step itself) or rewritten as the minimal observable signal with no count ("Shrine red under X, green under Y"). A count written from reasoning is a guess: the independent reviewer re-derives it, and a wrong one costs a full delta round. Applies with double force to text added while applying review findings — a verified fix plus an unverified summary of it is the recurring blocker shape.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

Checks 4-6 and 10-13 are mechanical — most independent-review blockers are this class, and every one caught here is a review round saved.

After self-review passes, commit the plan + `.tasks.json`. Any independent review dispatch needs a committed doc — the commit sha is the review's delta base.

## Execution Handoff

<HARD-GATE>
STOP. You are about to complete the plan. DO NOT call EnterPlanMode or ExitPlanMode. You MUST call AskUserQuestion below. Both are FORBIDDEN — EnterPlanMode traps the session, ExitPlanMode skips the user's execution choice.
</HARD-GATE>

A plan enters execution with zero unresolved `[FABLE-ADJUDICATE]` markers — the top-tier coordinator adjudicates each one (or surfaces it to the user) before the execution question. If you are that coordinator, do it now; if markers remain and you cannot adjudicate them, surface them in the question below instead of proceeding silently.

Your ONLY permitted next action is calling `AskUserQuestion` with this EXACT structure — mark the option matching the plan's Execution recommendation "(Recommended)":

```yaml
AskUserQuestion:
  question: "Plan complete and saved to docs/superpowers/plans/<filename>.md. How would you like to execute it?"
  header: "Execution"
  options:
    - label: "Subagent-Driven (this session)"
      description: "I dispatch fresh subagent per task, review between tasks, fast iteration"
    - label: "Parallel Session (separate)"
      description: "Open new session in worktree with executing-plans, batch execution with checkpoints"
```

**If you are about to call ExitPlanMode, STOP — call AskUserQuestion instead.**

<HARD-GATE>
STOP. The user has chosen an execution method. You MUST invoke the corresponding skill using the Skill tool NOW. Do NOT implement tasks yourself — do NOT read files, make edits, or update task statuses. Your ONLY permitted action is invoking the skill below.

**If Subagent-Driven chosen:**
Invoke the Skill tool: `superpowers:subagent-driven-development`
- The skill handles everything: subagent dispatch, review, task tracking
- You stay in this session as the coordinator
- Do NOT start working on tasks directly

**If Parallel Session chosen:**
Guide the user to open a new session in the worktree, then invoke: `superpowers:executing-plans`
</HARD-GATE>

---

## Native Task Integration Reference

Use Claude Code's native task tools (v2.1.16+) to create structured tasks alongside the plan document.

### Creating Native Tasks

For each task in the plan, create a corresponding native task. Embed metadata as a `json:metadata` code fence at the end of the description — this is the only way to ensure metadata survives TaskGet (the `metadata` parameter on TaskCreate is accepted but not returned by TaskGet).

#### TaskCreate description — full structured body, not a summary

**Hard rule.** Every TaskCreate `description` MUST contain, verbatim, the same **Goal / Files / Acceptance Criteria / Verify** sections you wrote into the plan `.md` for that task. Do NOT condense into a one-sentence summary. Do NOT move the AC to "see the plan doc". Do NOT omit `**Verify:**`. The description MUST end with the `json:metadata` code fence.

**Why it matters.** Both execution paths (`executing-plans` and `subagent-driven-development`) read the task description via TaskGet and pass it to the implementing subagent. A one-sentence description makes the subagent improvise AC. The plan `.md` is not a fallback — TaskGet does not read it.

**The `.tasks.json` is a LOSSY projection of the plan body** — only `id`/`subject`/`status`/`blockedBy`/`description` survive. Two things the plan body carries have no native field and MUST be encoded in each task's description or a JSON-only runner loses them:
- **Checkpoint label.** `checkpoint` is not a native task field. Put the task's label from `## Review checkpoints` in the metadata fence (`"checkpoint": "CP2"`) — otherwise every review gate vanishes for an orchestrator driving from the JSON.
- **Conditional gates.** `blockedBy` expresses UNCONDITIONAL edges only. A task gated on something that may park (a `[FABLE-ADJUDICATE]` decision, a `[D]`-able task) gets NO `blockedBy` edge; instead its description opens with an `ORCHESTRATOR:` line stating the gate and the action ("add `5` to `blockedBy` before dispatch if Task 5 is proceeding; otherwise dispatch as-is"). A hard edge on a parked task silently stalls the whole downstream chain, including tasks unrelated to the gate.

**Self-check before finishing the skill.** This is a mechanical count, not a read-and-confirm — a prose pass can be rubber-stamped, a count can't. For each of the four section headers (`**Goal:**`, `**Files:**`, `**Acceptance Criteria:**`, `**Verify:**`), run `grep -c` over `<plan>.tasks.json`:

```bash
grep -c '\*\*Goal:\*\*' <plan>.tasks.json
grep -c '\*\*Files:\*\*' <plan>.tasks.json
grep -c '\*\*Acceptance Criteria:\*\*' <plan>.tasks.json
grep -c '\*\*Verify:\*\*' <plan>.tasks.json
```

Each count MUST equal the number of tasks. If any count is lower → a task dropped that section; TaskUpdate it to the full block BEFORE the Execution Handoff. Also confirm the `json:metadata` fence is present in every task. Fall back to per-task TaskGet only if the tasks file is missing.

**Keep subjects compact.** The harness re-injects every task's subject line into context on periodic reminders, so subjects are paid for repeatedly — aim for ≤ 60 characters and put detail in the description.

**`modelTier` is REQUIRED on every task, schema values only: `mechanical` | `standard` | `frontier`.** You assign it — you hold the task; the execution controller dispatches at the tier without re-deciding, so a tier you leave vague becomes a guess made by someone with less context. The test is whether a DECISION remains at edit time, not how many files the task touches:
- `mechanical` — 1-2 files, the steps carry the code, nothing left to choose.
- `standard` — several files or an integration seam, the steps still carry the code and every choice is already made. Multi-file alone never promotes a task.
- `frontier` — the steps leave a design choice open, the task needs broad codebase understanding the brief cannot carry, or it sits in a domain the project's instruction file routes to its top tier (a HARD-TRIGGER area, a skill-gated surface). Name which in the task's prose, one clause.
Never `judgment`, `orchestrator`, or any other word — the routing gates reject them (Self-Review check 11).

```yaml
TaskCreate:
  subject: "Task N: [Component Name]"
  description: |
    **Goal:** [From task's Goal line]

    **Files:**
    [From task's Files section]

    **Acceptance Criteria:**
    [From task's Acceptance Criteria]

    **Verify:** [From task's Verify line]

    ```json:metadata
    {"files": ["path/to/file1.py"], "verifyCommand": "pytest tests/path/ -v", "acceptanceCriteria": ["criterion 1", "criterion 2"], "checkpoint": "CP1", "modelTier": "mechanical"}
    ```
  activeForm: "Implementing [Component Name]"
```

### Why Embedded Metadata

The `metadata` parameter on TaskCreate is accepted but **not returned by TaskGet**. Embedding it as a `json:metadata` code fence in the description ensures:
- TaskGet returns the full metadata (it's part of the description)
- Cross-session resume can parse it from .tasks.json
- Subagent dispatch can extract it for implementer prompts

See `skills/shared/task-format-reference.md` for the full metadata schema.

### Setting Dependencies

After all tasks created, set blockedBy relationships — **unconditional prerequisites only** (a conditional gate is an `ORCHESTRATOR:` line in the description, see the hard rule above):

```
TaskUpdate:
  taskId: [task-id]
  addBlockedBy: [prerequisite-task-ids]
```

### During Execution

Update task status as work progresses:

```
TaskUpdate:
  taskId: [task-id]
  status: in_progress  # when starting

TaskUpdate:
  taskId: [task-id]
  status: completed    # when done
```

---

## Task Persistence

At plan completion, write the task persistence file **in the same directory as the plan document**.

If the plan is saved to `docs/superpowers/plans/2026-01-15-feature.md`, the tasks file MUST be saved to `docs/superpowers/plans/2026-01-15-feature.md.tasks.json`.

```json
{
  "planPath": "docs/superpowers/plans/2026-01-15-feature.md",
  "tasks": [
    {
      "id": 0,
      "subject": "Task 0: ...",
      "status": "pending",
      "description": "**Goal:** ...\n\n**Files:**\n...\n\n```json:metadata\n{\"files\": [\"path/to/file.py\"], \"verifyCommand\": \"pytest tests/ -v\", \"acceptanceCriteria\": [\"criterion 1\"], \"modelTier\": \"mechanical\"}\n```"
    },
    {
      "id": 1,
      "subject": "Task 1: ...",
      "status": "pending",
      "blockedBy": [0],
      "description": "**Goal:** ...\n\n```json:metadata\n{\"files\": [], \"verifyCommand\": \"\", \"acceptanceCriteria\": [], \"modelTier\": \"standard\"}\n```"
    }
  ],
  "lastUpdated": "<timestamp>"
}
```

Both the plan `.md` and `.tasks.json` must be co-located in `docs/superpowers/plans/`.

### Resuming Work

Any new session can resume by running:
```
/superpowers:executing-plans <plan-path>
```

The skill reads the `.tasks.json` file and continues from where it left off.
