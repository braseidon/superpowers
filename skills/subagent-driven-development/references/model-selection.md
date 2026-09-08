# Model selection — tier routing detail

The SKILL.md body carries the four binding rules (dispatch at the plan's tier, one bump, reviewer tiers, always name the model). This file holds the default routing and the reasoning, for projects whose routing file or instruction file names none.

## Tier → model defaults

- `mechanical`, `standard` → mid tier (Sonnet). Both are transcription plus testing when the plan carries the code — and a plan written by writing-plans always does. Multi-file is not a reason to upgrade; a decision left open at edit time is.
- `frontier` → top tier (Opus): a design choice remains, broad codebase understanding is needed, or the task sits in a domain the project's instruction file routes to its top tier.
- Never the cheap tier (Haiku) for implementation: it routinely takes 2-3× the turns on multi-step work and costs more overall.

## Effort (effort-pinned agent types)

**Implementers default to HIGH effort at every tier.** Top tier at xhigh does not implement more accurately than top tier at high, and it takes substantially longer — measured across many plan executions on this project. The reason is structural: a plan written by writing-plans carries the code, the line anchors and the verify command, so almost nothing is left to decide at edit time, and extra reasoning budget has nothing to buy. Investigation is where the difference showed up at all, and even there it was small.

**Dispatch a task at xhigh when its own text leaves the implementer something to decide.** Three observable triggers, any one of which is enough: the task carries a `[FABLE-ADJUDICATE]` or `[D]` marker; its Steps name an outcome without giving the code or the exact edit (a measurement to interpret, a design to pick, a diff to review); or an acceptance criterion asks the implementer to choose between named alternatives rather than to satisfy a stated one. Read the task and check — do not upgrade on a feeling that it looks hard. Multi-file is not a trigger, and neither is a long task.

Mid-tier models run high effort, always. Benched at medium effort, the mid tier skipped investigation steps and conflated dispatch-prompt instructions with agent-definition instructions — dangerous, not just slow; high and xhigh were fine. Medium effort on the mid tier is for trivial transcription with a small brief, nothing else.

Effort is not tier. Dropping an implementer from xhigh to high leaves `frontier` on the top tier and changes only the thinking budget, so it is not a tier re-decision and needs no ruling.

## Why tiers must not be re-decided

Re-deciding is where tiers creep upward: a controller "unsure" about a well-specified task upgrades it, and the savings the tiering exists for never arrive. The plan writer tiered the task with its full text in hand. A tier is wrong only when the brief contradicts it — a `mechanical` task whose steps leave a design choice open — and that correction is a ledgered ruling, never a silent upgrade.

## The one bump

A mid-tier implementer stuck on REASONING — BLOCKED, or DONE_WITH_CONCERNS about correctness, with the context it needed already in hand — is re-dispatched FRESH on the top tier carrying the brief path, the report-file path, and its concerns verbatim. Never a second mid-tier attempt at the same task.

A missing fact is not a reasoning problem: NEEDS_CONTEXT, or a BLOCKED whose cause the plan header or your cross-task context answers, gets the answer and a resume of the same agent — and the bump only if it comes back stuck again. A subagent's model is fixed at launch (a resume message cannot change it); the report file is the handoff between models.

## Reviewer tiers

Task and checkpoint reviews run on the top tier — the reviewer's job is catching what the implementer missed, and a mid-tier implementer under a top-tier reviewer is where the savings are safe; the reverse pairing is not. Scoped re-reviews (verdict named findings in a small fix diff) run on the mid tier. The final whole-branch review and fix-loop rounds 4-5 run on the top tier.
