# Native Task Format Reference

Skills that create native tasks (TaskCreate) MUST follow this format.

## Subject

Keep subjects compact (aim for ≤ 60 characters, no trailing detail). The harness re-injects every task's subject line into context during periodic reminders, so long subjects are paid for repeatedly. Details belong in the description.

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
| `checkpoint` | string | no | Review-checkpoint label from the plan's `## Review checkpoints` section (e.g. `CP2`). Not a native task field — the `.tasks.json` carries no checkpoints otherwise, so a JSON-only orchestrator loses every review gate. Conditional dependencies (edges that exist only if a gated task proceeds) are likewise not expressible in `blockedBy`; encode them as an `ORCHESTRATOR:` line in the description. |
| `estimatedScope` | "small" \| "medium" \| "large" | no | Relative effort indicator |
| `subagentType` | string | no | Required `subagent_type` value for Agent dispatches during this task (e.g. `general-purpose`, `local`, `Explore`). The `pre-agent-task-dispatch-validate` hook blocks Agent calls that disagree. |
| `model` | string | no | Required `model` value for Agent dispatches during this task (e.g. `haiku`, `sonnet`, `opus`). Use when the task is sensitive to tier choice — empirical A/B measurements need a pinned model, coordinator quality calls need Opus, cheap bulk work needs Haiku. Enforced by `pre-agent-task-dispatch-validate` when the hook is registered. Overrides `modelTier`. |
| `modelTier` | "mechanical" \| "standard" \| "frontier" | no | Abstract capability tier for subagents executing this task. Belongs to the opt-in model-routing flow: when the routing file exists (project `docs/superpowers/model-routing.json`, else user-level `~/.claude/superpowers/model-routing.json`), plugin gates require it on every plan task (`pre-taskcreate-model-tier`) and enforce the resolved Agent `model` at dispatch (`pre-agent-model-routing`); the session-start notice carries the rules. File absent → gates are dormant, the key is inert metadata, and every subagent inherits the session model. `"inherit"` as a mapping value means omit the Agent `model` param. A concrete `model` pin (above) always wins over the tier. Full design: `docs/model-routing-flow.md`. |
| `dispatchBrief` | string | no | Substring that the Agent `prompt` MUST contain verbatim. Use for dispatches where a specific preamble is mandatory (e.g. `COMMIT EXECUTOR SUBAGENT`, `local 35`). Checked as a substring match. |

### Example

```yaml
TaskCreate:
  subject: "Add JIT selection prompt to /hame Pre-flight"
  description: |
    **Goal:** Replace auto-latest JIT selection with interactive 3-option prompt.

    **Files:**
    - Modify: `.claude/commands/hame-optimal-cycle-inspection.md:45-60`

    **Acceptance Criteria:**
    - [ ] AskUserQuestion presents 3 most recent JIT messages
    - [ ] Selected JIT's SOC and schedule are parsed into variables
    - [ ] --jit override bypasses the prompt (backwards compat)

    **Verify:** Read the Pre-flight Step 2 section and confirm AskUserQuestion block with 3 JIT options

    ```json:metadata
    {"files": [".claude/commands/hame-optimal-cycle-inspection.md"], "verifyCommand": "grep -A 20 'Step 2' .claude/commands/hame-optimal-cycle-inspection.md", "acceptanceCriteria": ["AskUserQuestion with 3 JIT options", "SOC + schedule parsed from selection", "--jit override bypasses prompt"]}
    ```
```

## Task Granularity

### The Right Scope

A task is **a coherent unit of work that produces a testable, committable outcome**.

**Scope test — ask these questions:**
1. Does this task produce something I can verify independently? (if no → too small)
2. Does it touch more than one concern? (if yes → too big)
3. Would it get its own commit? (if no → too small; if commit message needs bullet points → too big)
4. Could a reviewer meaningfully reject this task while approving its neighbor? (if no → merge them — that's the only boundary worth a fresh reviewer's gate)

**Fold-in rule:** setup, configuration, scaffolding, and documentation steps are not tasks of their own — fold each into the task whose deliverable needs it.

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
