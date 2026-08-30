# Model selection — tier routing detail

The SKILL.md body carries the four binding rules (dispatch at the plan's tier, one bump, reviewer tiers, always name the model). This file holds the default routing and the reasoning, for projects whose routing file or instruction file names none.

## Tier → model defaults

- `mechanical`, `standard` → mid tier (Sonnet). Both are transcription plus testing when the plan carries the code — and a plan written by writing-plans always does. Multi-file is not a reason to upgrade; a decision left open at edit time is.
- `frontier` → top tier (Opus): a design choice remains, broad codebase understanding is needed, or the task sits in a domain the project's instruction file routes to its top tier.
- Never the cheap tier (Haiku) for implementation: it routinely takes 2-3× the turns on multi-step work and costs more overall.

## Effort floor (effort-pinned agent types)

Mid-tier models run high effort, always. Benched at medium effort, the mid tier skipped investigation steps and conflated dispatch-prompt instructions with agent-definition instructions — dangerous, not just slow; high and xhigh were fine. Medium effort on the mid tier is for trivial transcription with a small brief, nothing else.

## Why tiers must not be re-decided

Re-deciding is where tiers creep upward: a controller "unsure" about a well-specified task upgrades it, and the savings the tiering exists for never arrive. The plan writer tiered the task with its full text in hand. A tier is wrong only when the brief contradicts it — a `mechanical` task whose steps leave a design choice open — and that correction is a ledgered ruling, never a silent upgrade.

## The one bump

A mid-tier implementer stuck on REASONING — BLOCKED, or DONE_WITH_CONCERNS about correctness, with the context it needed already in hand — is re-dispatched FRESH on the top tier carrying the brief path, the report-file path, and its concerns verbatim. Never a second mid-tier attempt at the same task.

A missing fact is not a reasoning problem: NEEDS_CONTEXT, or a BLOCKED whose cause the plan header or your cross-task context answers, gets the answer and a resume of the same agent — and the bump only if it comes back stuck again. A subagent's model is fixed at launch (a resume message cannot change it); the report file is the handoff between models.

## Reviewer tiers

Task and checkpoint reviews run on the top tier — the reviewer's job is catching what the implementer missed, and a mid-tier implementer under a top-tier reviewer is where the savings are safe; the reverse pairing is not. Scoped re-reviews (verdict named findings in a small fix diff) run on the mid tier. The final whole-branch review and fix-loop rounds 4-5 run on the top tier.
