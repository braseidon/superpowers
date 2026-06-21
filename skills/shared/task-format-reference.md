# Native Task Format Reference

Skills that create native tasks (TaskCreate) MUST follow this format.

## Task Description Template

Every TaskCreate description MUST follow this structure:

### Required Sections

**Goal:** One sentence — what this task produces (not how).

**Files:**
- Create/Modify/Delete: `exact/path/to/file.py` (with line ranges for modifications)

**Acceptance Criteria:**
- [ ] Concrete, testable criterion
- [ ] Another criterion

**Verify:** `exact command to run` → expected output summary

### Optional Sections (include when relevant)

**Context:** Why this task exists, what depends on it, architectural notes.
Only needed when the task can't be understood from Goal + Files alone.

**Steps:** Ordered implementation steps (only for multi-step tasks where order matters).
TDD cycles happen WITHIN steps, not as separate steps.

## Metadata Schema

Embed metadata as a `json:metadata` code fence at the end of the TaskCreate description. The `metadata` parameter on TaskCreate is accepted but **not returned by TaskGet** — embedding in the description is the only reliable way.

| Key | Type | Required | Purpose |
|-----|------|----------|---------|
| `files` | string[] | yes | Paths to create/modify/delete |
| `verifyCommand` | string | yes | Command to verify task completion |
| `acceptanceCriteria` | string[] | yes | List of testable criteria |
| `estimatedScope` | "small" \| "medium" \| "large" | no | Relative effort indicator |
| `tags` | string[] | no | Free-form tags (e.g. `["verification", "perf"]`). Opt-in hooks can key off tags. |
| `subagentType` | string | no | Required `subagent_type` value for Agent dispatches during this task (e.g. `general-purpose`, `local`, `Explore`). The `pre-agent-task-dispatch-validate` hook blocks Agent calls that disagree. |
| `model` | string | no | Required `model` value for Agent dispatches during this task (e.g. `haiku`, `sonnet`, `opus`). Use when the task is sensitive to tier choice — empirical A/B measurements need a pinned model, coordinator quality calls need Opus, cheap bulk work needs Haiku. Enforced by `pre-agent-task-dispatch-validate` when the hook is registered. Overrides `modelTier`. |
| `modelTier` | "mechanical" \| "standard" \| "frontier" | no | Abstract capability tier for subagents executing this task. Belongs to the opt-in model-routing flow: when the routing file exists (project `docs/superpowers/model-routing.json`, else user-level `~/.claude/superpowers/model-routing.json`), plugin gates require it on every plan task (`pre-taskcreate-model-tier`) and enforce the resolved Agent `model` at dispatch (`pre-agent-model-routing`); the session-start notice carries the rules. File absent → gates are dormant, the key is inert metadata, and every subagent inherits the session model. `"inherit"` as a mapping value means omit the Agent `model` param. A concrete `model` pin (above) always wins over the tier. Full design: `docs/model-routing-flow.md`. |
| `dispatchBrief` | string | no | Substring that the Agent `prompt` MUST contain verbatim. Use for dispatches where a specific preamble is mandatory (e.g. `COMMIT EXECUTOR SUBAGENT`, `local 35`). Checked as a substring match. |
| `requireEvidenceTokens` | string[][] | no | List of evidence axes. Each axis is a list of alternative tokens; the subagent's return (assistant text + tool_result content) must contain at least one token from EACH axis. Fully generic: 2 axes for A/B, 3+ for multi-arm experiments, arbitrary tokens for domain-specific pairs (`v2`/`v3` for migration, `control`/`variant-a`/`variant-b` for 3-arm perf, `vulnerable`/`patched` for security, etc.). Enforced by `post-agent-return-validate`. |
| `requireABCompare` | boolean | no | Shortcut for the canonical before/after pair. Equivalent to `requireEvidenceTokens: [["baseline","old","before","v0","v1","iter-0","iter0","original","pre"], ["new","refactored","after","v2","iter-1","iter1","post","updated","replacement"]]`. Use for empirical refactors where the default tokens match your vocabulary. For any other domain, use `requireEvidenceTokens` directly. |

## Task Granularity

### The Right Scope

A task is **a coherent unit of work that produces a testable, committable outcome**.

**Scope test — ask these questions:**
1. Does this task produce something I can verify independently? (if no → too small)
2. Does it touch more than one concern? (if yes → too big)
3. Would it get its own commit? (if no → too small; if commit message needs bullet points → too big)

### Examples

| Scope | Example | Why |
|-------|---------|-----|
| Too small | "Write failing test for X" | Not independently verifiable — needs implementation |
| Too small | "Run pytest" | Verification step, not a task |
| Too small | "Add import statement" | Part of a larger change |
| **Right** | "Implement WebSocket protocol layer with tests" | Coherent unit, testable, one commit |
| **Right** | "Add JIT selection prompt to Pre-flight" | Single concern, verifiable, one commit |
| **Right** | "Create optimizer test class for SOC 73% case" | Complete test suite for one scenario |
| Too big | "Implement entire auth system" | Multiple concerns, multiple commits |
| Too big | "Fix all /hame output issues" | Multiple independent changes |

### TDD Within Tasks (Not Across Tasks)

TDD cycles (write test → verify fail → implement → verify pass) happen WITHIN a single task, not as separate tasks. The task is "Implement X with tests" — the TDD steps are execution detail, not task boundaries.

### Commit Boundary = Task Boundary

Each task should produce exactly one commit. If a task needs multiple commits, split it. If separate tasks share a commit, merge them.
