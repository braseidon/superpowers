---
name: subagent-driven-development
description: Use when executing implementation plans with independent tasks in the current session
---

# Subagent-Driven Development

Execute a plan by dispatching a fresh subagent per task, with a two-stage review after each (spec compliance, then code quality). Subagents get isolated, precisely constructed context — never your session history; your own context stays for coordination. Independent tasks run at the same time.

**Continuous execution:** never pause to check in between tasks. Stop only for BLOCKED you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete.

## When to Use

- Have a plan whose tasks are mostly independent, and staying in this session → this skill.
- Same plan, but a separate/parallel session → superpowers:executing-plans.
- No plan, or tightly coupled tasks → manual execution or brainstorm first.

**Review checkpoints override the per-task loop.** If the project's CLAUDE.md or the plan declares review checkpoints, those govern: batched review across grouped tasks is correct and is not "skipping reviews." Every task still gets reviewed — checkpoints decide when and how grouped.

## Setup

- Work in place in the current checkout. Never implement on main/master without your human partner's consent.
- Each plan owns a workspace: run this skill's `scripts/sdd-workspace PLAN_FILE` — it prints the plan's git-ignored directory (`<repo-root>/.superpowers/sdd/<plan-basename>/`), home to every artifact for THIS plan: ledger, briefs, reports, review packages. Another plan's directory is never yours to read or write.
- **The ledger (`<workspace>/progress.md`) is your recovery map** — conversation memory does not survive compaction; after one, trust the ledger and `git log` over recollection. Check for it first: first line names your plan file → tasks with a `Task <N>: complete` line are DONE, resume at the first without one; a task whose last line is a fix round resumes at the next round. First line names another plan (or a stray ledger at the old flat path `.superpowers/sdd/progress.md`) → leave it, start your own with `# SDD ledger — plan: <plan file path>` as line 1. `git clean -fdx` destroys the workspace; recover from `git log`.
- **The ledger records STATE, not reasoning.** One event, one line, in the forms this skill names (dispatch, fix round, complete, minor, parked, ruling, BLOCKED); only a parked ruling may run to three. Every decision taken on your human partner's behalf — a plan contradiction resolved from the header's recorded decisions, a tier correction, a breaker adjudication — is a `Task <N>: ruling — <what> — <why> — <cost if wrong>` line. No narration, praise, self-correction essays, or restated facts — every line is re-read every later turn. Process lessons go in your final report: the workspace is deleted at Finish.
- Append entries with a shell append (`cat >> progress.md <<'EOF'`), not Edit — Edit re-sends growing anchor text and fires a permission prompt per entry.
- Read the plan once, note its context and Global Constraints, and TaskCreate a task per plan task with the full task text.

## Dispatching with Metadata

1. Read the task's description via TaskGet — metadata is a `json:metadata` fence at the end.
2. Map its fields (files, acceptanceCriteria, verifyCommand, modelTier) to the implementer prompt sections. The implementer receives ALL structured data — never make it parse prose.

## Model Selection

- **Dispatch the implementer at the plan's `modelTier` (`mechanical` | `standard` | `frontier`). Do not re-decide.** A tier is wrong only when the brief contradicts it (a `mechanical` task with a design choice left open): ledger `Task <N>: ruling — tier mechanical→frontier — <why>` and dispatch at the corrected tier.
- Tier → model, effort and agent type come from the project's routing (routing file or instruction file); defaults when it names none, the effort floor, and the reasoning: [references/model-selection.md](references/model-selection.md). A project implementer agent (contract, effort pin, turn cap in its definition) is dispatched by `subagent_type`, model on the call, brief = the task only; none → `general-purpose` + full template. Never the cheap tier (Haiku) for implementation; mid tier at medium effort only for trivial transcription.
- **A partial return (turn cap) is not DONE:** resume with "continue from where you stopped" (transcript intact; the partial text may lag), re-brief, or bump.
- **One bump, no retry.** A mid-tier implementer stuck on REASONING (BLOCKED, or DONE_WITH_CONCERNS about correctness, with the context it needed in hand) → FRESH dispatch on the top tier with brief path, report-file path, concerns verbatim; never a second mid-tier attempt. A missing fact (NEEDS_CONTEXT, or a BLOCKED your context answers) gets the answer and a resume of the same agent — the bump only if it sticks again.
- **Reviewers:** task/checkpoint reviews, fix rounds 4-5, final whole-branch review → top tier. Scoped re-reviews → mid tier. Project reviewer agent named by the routing → `subagent_type`, model on the call, prompt = inputs only; none → `general-purpose` + full template.
- **Always name the model explicitly on every dispatch** — an omitted model inherits your session's, usually the most expensive.

## The Task Loop

Everything pasted into a dispatch prompt, and everything a subagent prints back, stays resident in your context and is re-read every later turn. Hand artifacts over as files.

### 1. Dispatch the frontier

**The unit of dispatch is the frontier, not the next task.** Before every dispatch message compute it: every pending task whose `blockedBy` are all complete AND whose `files` share no path with any task in progress or in the same message. Dispatch the whole frontier in ONE message, every implementer in the background, and keep coordinating. Mark each task `in_progress` BEFORE its dispatch — routing gates resolve a dispatch against the in-progress set.

- `files` metadata IS the disjointness test. Overlap serializes; uncertainty serializes; an empty or visibly incomplete `files` list is not parallel-safe. Serial is the fallback for overlap, never the default — independent tasks run one after another is wall-clock you chose to burn. Never two writers on one file; that is the whole parallelism rule ("one implementer at a time" is not it).
- Read-only dispatches (audits, baselines, verification gates, long suites) are always parallel-safe.
- Per implementer, record BASE (`git rev-parse HEAD`) before dispatching — review packages and fix-round diffs need it. Parallel implementers interleave commits; each task's package is scoped to its own commits' files (§3).
- **Task brief:** `scripts/task-brief PLAN_FILE N` extracts the task text to a uniquely named file and prints the path — the single source of requirements. The dispatch carries: (1) one line on where the task fits; (2) the brief path, introduced as "read this first — it is your requirements, with the exact values to use verbatim"; (3) interfaces and decisions from earlier tasks the brief cannot know; (4) your resolution of any ambiguity you noticed; (5) the report-file path and report contract. Exact values (numbers, magic strings, signatures, test cases) appear only in the brief. Never make a subagent read the whole plan.
- **Report file:** named after the brief (`…/task-N-brief.md` → `…/task-N-report.md`), in the dispatch. The implementer writes the full report there and returns only status, commits, a one-line test summary, and concerns.
- **Review file:** same stem (`…/task-N-review.md`; checkpoint reviews `…/cpN-review.md`), in the reviewer dispatch. The reviewer writes the full review there, numbers findings (`C1`, `I1`, `M1`), and returns an index: spec verdict, one line per Critical/Important finding, Minor count, quality verdict. Fix briefs and re-reviews cite the IDs and the file; nobody copies finding text into a prompt, and the controller opens the file only to ledger minors or adjudicate.
- A dispatch describes one task, never the session's history ("state after Tasks 1-3"): task, interfaces it touches, global constraints.
- An earlier task parked a finding in this task's area? Carry a pointer to that ledger entry.
- Record the implementer's agent identity — fix rounds 1-3 resume it.

Template: [implementer-prompt.md](implementer-prompt.md)

### 2. Handle the report

- **DONE:** generate the review package (§3) and dispatch the task reviewer. Generate it only after the report lands — a pre-generated package is stale.
- **DONE_WITH_CONCERNS:** read the concerns. Correctness or scope → address before review; observations ("this file is getting large") → note and proceed.
- **NEEDS_CONTEXT:** provide the missing context and re-dispatch.
- **BLOCKED:** context problem → more context, same model; reasoning problem → fresh dispatch on a more capable model (one bump, Model Selection); too large → split; plan wrong → escalate to the human.

Never ignore an escalation or force the same model to retry unchanged; implementer questions, before or mid-task, get clear, complete answers.

**Escalating to your human partner** — before ANY execution-time AskUserQuestion, plan-scripted or relayed: (1) re-read the plan header's "User decisions (already made)" — a recorded decision answers it, don't ask; (2) if you do ask, name the artifact AND its role/state from the plan's facts, and make each option say what changes and what stays — an unanchored recommendation reads as a new proposal to someone who does not hold the plan in their head.

### 3. Review the task

Per-task reviews are task-scoped gates; the broad review is at the end. Never skip one, never accept a report missing either verdict (spec compliance AND task quality); implementer self-review never replaces it.

- **Hand the reviewer its diff as a file:** `scripts/review-package PLAN_FILE BASE HEAD` (from this skill's directory) prints the unique path it wrote — commit list, stat summary, full `-U10` diff, one Read, nothing in your context. Without bash: `git log --oneline` + `git diff --stat` + `git diff -U10` for the range into one uniquely named file. BASE is the commit recorded before dispatch — never `HEAD~1`, which silently drops all but the last commit of a multi-commit task. Never dispatch a reviewer without a diff file.
- **Share the repo with anything else that commits? Scope the package** — `scripts/review-package PLAN_FILE BASE HEAD -- $(git show --name-only --format= <shas from the implementer's report>)`. Foreign commits land between yours whenever another session, agent or human works the checkout; `BASE..HEAD` sweeps them all in. A strictly sequential loop needs this too — the interleaving comes from outside.
- **The pathspec comes from the commits, never from the plan's `files` metadata.** A fix's test lands in a sibling `__tests__/` the metadata never named; a metadata-scoped package drops the hunk and the reviewer verdicts a fix without its tests. The script lists every dropped file (with its commits) in the package and warns on stderr — a warning naming a file from the implementer's shas means rescope, not dispatch.
- A package that still spans foreign commits: say so in the dispatch and name the task's own commit(s) — the header's commit list covers the whole range even when the body is scoped.
- **Reviewer inputs:** brief file, report file, review package, review file path, plus the global constraints that bind the task, copied verbatim from the plan's Global Constraints or the spec (exact values, formats, "same layout as X" relationships). That block is the reviewer's attention lens; the template carries the process rules.
- No open-ended directives ("check all uses") without a concrete task-specific reason. No re-running tests the implementer already ran on the same code — the report carries the evidence.
- **Never pre-judge findings.** Never tell a reviewer to ignore or not flag an issue; let it raise the finding and adjudicate in the loop. "Do not flag", "don't treat X as a defect", "at most Minor", "the plan chose" in your prompt = stop, you are sparing yourself a review loop.
- **"⚠️ Cannot verify from diff"** items (requirements in unchanged code or spanning tasks) don't block the review, but you resolve each yourself before completion — you hold the plan and cross-task context. A confirmed real gap is a failed spec review and enters the fix loop.

Template: [task-reviewer-prompt.md](task-reviewer-prompt.md)

### 4. The fix loop

Triggers on spec ❌, any Critical or Important finding, or a confirmed ⚠️ gap. Two routes leave it immediately:

- **Minor findings** go to the ledger (`Task <N>: minor (deferred): <one-liner>`) and the final review is pointed at that list to triage what must be fixed before merge. Minors never enter the loop; a roll-up nobody reads is a silent discard.
- **A finding that conflicts with the plan's text** (or is labeled plan-mandated) is the human's decision: present the finding and the plan text, ask which governs. Neither dismiss it because the plan mandates it nor dispatch a fix that contradicts the plan unasked.

Everything else enters the loop. A round = one fix dispatch + one scoped re-review. **Five rounds maximum per task.**

- **Rounds 1-3 — resume the original implementer** with the review file path and the open finding IDs; its context is intact. If the harness cannot message a live subagent, dispatch fresh with brief path, report-file path, review-file path and the IDs — the two files are the persistent memory either way.
- **Rounds 4-5 — fresh implementer on a more capable model**, with brief path, report-file path, review-file path, open finding IDs, and: "A prior implementer attempted this task [N] times; you own it now. Read the report file for what was tried." Three failed resumes = the implementer cannot see its own problem.
- **Every round:** the implementer fixes, re-runs the tests covering the amended code (name them in the fix message — a one-line fix does not need the whole suite), appends its fix report to the same report file, returns the short contract. Dispatch the re-review only once the fix report has the covering tests, the command, and the output.
- **The re-review is scoped:** `scripts/review-package PLAN_FILE FIX_BASE HEAD` (FIX_BASE = the head the previous review saw), dispatched with [re-review-prompt.md](re-review-prompt.md) plus open finding IDs, brief, report file, review file, diff path. It appends to the review file and verdicts each finding ADDRESSED / NOT ADDRESSED and flags new breakage in the fix diff only; new Critical/Important breakage joins the open list, out-of-scope observations go to the ledger as deferred minors and never extend the loop.
- **After each round:** `Task <N>: fix round <R>/5 (<X> addressed, <Y> open — <finding IDs>; commits <a7>..<b7>)`.
- **Never fix findings yourself in the controller session** — pollutes your context and skips review.

**The breaker.** Round 5's re-review still leaves findings open → stop dispatching and adjudicate each yourself:

- Reviewer wrong, or contestable → `Task <N>: parked — <finding> — ruling: <why the code stands>`. The final review sees both sides.
- Real, nothing downstream builds on it → park the same way; ruling says real and deferred.
- Real and load-bearing (a later task builds on it, or it reveals a plan defect) → STOP. `Task <N>: BLOCKED — <reason>`; report the finding, the plan text it collides with, and the fix history. Parking a structural failure hands every dependent task a problem nobody can fix.

Adjudicate only at the cap — earlier is pre-judging under another name. Every adjudication is a ledger entry; silent discards are forbidden.

### 5. Complete the task

Review clean, or every open finding parked with a ruling at the cap → ledger, in the same message as your other bookkeeping:

- `Task <N>: complete (commits <base7>..<head7>, review clean)`
- `Task <N>: complete (commits <base7>..<head7>, <K> parked)` after a tripped breaker

Then TaskUpdate completed, and in the same call shrink the description to its **Goal:** line plus `Complete — see ledger.` — the harness re-injects every task's full description on periodic reminders; the details survive in the plan, the brief, and `.tasks.json`. Then sync `<plan-path>.tasks.json`: `"status"` → `"completed"`, `"lastUpdated"` → current ISO timestamp — without it a new session sees the task as pending.

Never move on while Critical/Important issues are neither fixed nor parked-with-ruling at the cap.

## Final Review

`scripts/review-package PLAN_FILE MERGE_BASE HEAD` (MERGE_BASE = where the branch started, e.g. `git merge-base main HEAD`); dispatch superpowers:requesting-code-review's [code-reviewer.md](../requesting-code-review/code-reviewer.md) on the most capable model with the printed path and a review file (`<workspace>/final-review.md`), pointed at the ledger's deferred-minor and parked lines to triage what must be fixed before merge. It returns the index; fix dispatches cite its finding IDs and the file.

Findings → **ONE fix subagent with the complete list**, then exactly one scoped re-review of the fix range (`review-package PLAN_FILE FIX_BASE HEAD`, re-review-prompt.md). Adjudicate residuals as in the breaker. **No second fix wave** — residual load-bearing findings are reported to your human partner at Finish.

## Finish

Before deleting anything, collect every ledger `ruling` and `parked` line — preflight rulings, tier corrections, parked findings, breaker adjudications — into your final message under **"Rulings I made"**, in order, each with its cost if wrong. Exhaustive: the ledger holds it, the list holds it. It is the only place your decisions on your partner's behalf reach them; a ruling that dies with the workspace was made in secret.

Final review clean and fixes merged → `rm -rf <workspace>`; git history is the record. Sibling directories belong to other plans.

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Close enough on spec compliance" | Spec gaps = not done. Fix, or hit the cap and adjudicate — the only exits. |
| "One more round will converge" | Past the cap the failure is structural. Adjudicate and route. |
| "The reviewer will just find something new anyway" | Scoped re-reviews cannot wander. Findings on untouched code go to the ledger, not the loop. |
| "This finding is obviously wrong, I'll drop it" | Adjudicate only at the cap; every ruling is a ledger entry. Silent discards are forbidden. |
| "The fix was small, skip the re-review" | Unreviewed fixes are how regressions land. Every round ends with a scoped re-review. |
| "Reviews slow the loop down" | Without reviews the loop is unverified churn. |
| "This looks harder than `mechanical`, I'll send the top tier" | The plan writer tiered it with the task in hand. Decision left open → ledger a tier ruling; otherwise dispatch at the tier. |
| "The implementer spawned its own reviewer — free assurance" | A duplicate seat on the same diff; the task review is the gate. A worker-spawned reviewer is a defect to flag. |
