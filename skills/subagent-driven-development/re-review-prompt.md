# Scoped Re-Review Prompt Template

Use this template when dispatching a re-review after a fix round. The
re-reviewer verifies the findings were addressed and checks the fix diff for
new breakage. It is not a fresh review — the full review already happened.

Two shapes, as in task-reviewer-prompt.md: a project reviewer agent type
(contract in its definition) gets the **Task** section only, by
`subagent_type` with the model on the call; `general-purpose` gets the Task
section plus the **Contract** section verbatim.

## Task section (always)

```
Agent tool:
  subagent_type: <project reviewer agent, or general-purpose>
  model: <the re-reviewer tier's model from the project's routing — always
         explicit; scoped re-reviews of small fix diffs take the mid tier>
  description: "Re-review Task N fix round R"
  prompt: |
    You are re-reviewing one task's fix round. A previous review produced
    findings; an implementer has attempted to fix them. Your job is to
    verdict each finding and inspect the fix diff — nothing else.

    ## The Task

    Read the task brief: [BRIEF_FILE]

    ## The Findings Under Verification

    Open finding IDs: [OPEN_FINDINGS]
    Read them in the review file: [REVIEW_FILE]
    Append your re-review to that file under `## Fix round [R]`.

    ## The Fix

    Read the implementer's report (fix reports are appended at the end):
    [REPORT_FILE]

    **Fix base:** [FIX_BASE_SHA] (the head the previous review saw)
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]
```

## Contract section (only when the agent definition does not carry it)

```
    Read the diff file once — it contains the fix commits, a stat summary,
    and the fix diff with surrounding context. Do not re-run git commands.
    If the diff file is missing, fetch the diff yourself:
    `git diff --stat [FIX_BASE_SHA]..[HEAD_SHA]` and
    `git diff [FIX_BASE_SHA]..[HEAD_SHA]`.

    Your review is read-only on this checkout. Do not mutate the working
    tree, the index, HEAD, or branch state in any way.

    ## You Do Not Dispatch Subagents

    Do all of this review yourself. Never spawn a subagent to review part
    of the diff, and never spawn another reviewer for a second opinion.
    This process already provides every review seat the work gets; a
    reviewer you spawn duplicates one of them at full cost, and its
    verdict counts for nothing. If the diff feels too large for one
    pass, review it in passes yourself and say so in your report.

    ## Scope

    Your scope is the open finding IDs and the fix diff. Verdict every finding.
    Inspect the fix diff for new problems the fix itself introduced. Do NOT
    re-review code the fix did not touch: if you notice an issue entirely
    outside the fix diff, report it under Out-of-Scope Observations — it
    does not block this task and does not extend the loop. A broad
    whole-branch review happens after all tasks are complete.

    ## Tests

    The implementer re-ran the tests covering the amended code and appended
    the results to the report file. Treat the report as unverified claims:
    confirm the fix report names the covering tests and shows their output,
    and verify the claims against the diff. Do not re-run the suite to
    confirm their report. Run a test only when reading the code raises a
    specific doubt that no existing run answers — and then a focused test,
    never a package-wide suite.

    ## Output Format

    Appended to the review file under `## Fix round [R]`:

    ### Finding Verdicts
    For each open finding ID, in order:
    - **I1** — ADDRESSED | NOT ADDRESSED, with file:line evidence.
      "Attempted" is not addressed: the specific defect must no longer exist.
    ### New Breakage in the Fix Diff
    Anything the fix itself broke or introduced, numbered on from the
    review's last ID (C2, I4 …), with severity and file:line. "None" if clean.
    ### Out-of-Scope Observations
    Issues you noticed entirely outside the fix diff. Non-blocking; the
    controller ledgers these for the final review. "None" if none.
    ### Verdict
    **Fix round:** [All findings addressed, no new Critical/Important
    breakage | Findings remain open] — list the open IDs.

    Final message (the index, under 12 lines):

    Review: <review file path> · fix round [R]
    I1 ADDRESSED `path:line` · I2 NOT ADDRESSED `path:line` — why
    New breakage: none | C2 `path:line` — problem. fix.
    Out of scope: <n> (in file)
    Verdict: all addressed | open: I2
```

**Placeholders:**
- `[BRIEF_FILE]` — the task brief file (same file the implementer worked from)
- `[OPEN_FINDINGS]` — the IDs still open (`C1, I2, I3`), never the text
- `[REVIEW_FILE]` — the review file the full review was written to; fix
  rounds append to it
- `[R]` — the round number
- `[REPORT_FILE]` — the implementer's report file (fix reports appended)
- `[FIX_BASE_SHA]` — the head the previous review saw
- `[HEAD_SHA]` — current commit
- `[DIFF_FILE]` — the path `scripts/review-package PLAN_FILE FIX_BASE HEAD` printed

**Re-reviewer returns:** the index — one verdict per open ID (ADDRESSED /
NOT ADDRESSED), new breakage one line each, out-of-scope count, round
verdict. The detail is appended to `[REVIEW_FILE]`.
