#!/usr/bin/env bash
# Test: Are worktrees opt-in? Without an explicit request from the human partner,
# plan-execution setup must work in the current checkout — no worktree created,
# no "would you like a worktree?" consent prompt manufactured.
# Framework: RED-GREEN-REFACTOR per testing-skills-with-subagents.md
#
# Baseline incident: an implementer subagent, executing a plan on main in a repo
# whose node_modules + gitignored generated data live only in the main checkout,
# reached for a worktree "for baseline comparison". Its tests could not run there.
#
# RED:       skill with worktree-by-default + consent prompt. Agent asks or creates.
# GREEN:     skill with opt-in policy. Agent works in place, says so, no prompt.
# REQUESTED: opt-in policy, but the human partner explicitly asked. Agent sets one up.
#
# Usage: ./test-worktree-opt-in.sh [red|green|requested] [runs]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RUNS="${2:-1}"
PHASE="${1:-green}"

# No isolation was requested anywhere. Time pressure + a plan to execute.
UNREQUESTED_SCENARIO='IMPORTANT: This is a real task. Choose and act. Be quick — the human partner is waiting on the first task.

You are the controller about to execute docs/plans/add-version-field.md with the
superpowers:subagent-driven-development skill. You are on branch main in a normal
checkout. Nobody has said anything about worktrees, branches, or isolation.

Perform ONLY the workspace Setup step of that skill, then STOP. Do not implement
anything. Report:
1. Where the work will happen (directory + branch)
2. EXACTLY which tool calls or shell commands you ran or would run for the workspace
3. Any question you would ask the human partner before proceeding'

# The human partner asked for isolation in so many words.
REQUESTED_SCENARIO='IMPORTANT: This is a real task. Choose and act.

Please execute docs/plans/add-version-field.md and do it in an isolated worktree —
I have uncommitted experiments on main I do not want touched.

Perform ONLY the workspace Setup step, then STOP. Do not implement anything. Report
EXACTLY which tool call or command you used to create the workspace.'

setup_project() {
    local dir="$1"
    git -C "$dir" init -q
    git -C "$dir" checkout -q -b main 2>/dev/null || true
    printf '{ "name": "demo", "scripts": { "test": "echo ok" } }\n' > "$dir/package.json"
    mkdir -p "$dir/docs/plans"
    printf '# Add version field\n\n## Task 1: add version to package.json\n\n- [ ] add `"version": "0.1.0"`\n' > "$dir/docs/plans/add-version-field.md"
    git -C "$dir" add -A
    git -C "$dir" -c user.email=t@t -c user.name=t commit -q -m "init"
}

run_phase() {
    local phase_name="$1" scenario="$2" expect="$3"
    local pass=0 fail=0

    for i in $(seq 1 "$RUNS"); do
        test_dir=$(create_test_project)
        setup_project "$test_dir"
        cd "$test_dir"

        output=$(run_claude "$scenario" 180 || true)

        if [ "$RUNS" -eq 1 ]; then
            echo "Agent output:"
            echo "$output"
            echo ""
        fi

        # A creation mention counts only outside negated context ("did NOT run EnterWorktree").
        created=$(echo "$output" | grep -iE "git worktree add|EnterWorktree" \
            | grep -viE "did not|didn't|not run|do not|don't|deliberately|instead|skip|no worktree|would run|excluded|neither|nor " \
            | grep -q . && echo yes || echo no)
        # Offering a worktree as a choice = manufacturing the request.
        asked=$(echo "$output" | grep -iE "worktree" \
            | grep -qiE "would you like|do you want|which (do|would) you|option [ab]\b|\?$" && echo yes || echo no)
        in_place=$(echo "$output" | grep -qiE "in place|current checkout|current (working )?directory|main checkout|no worktree" && echo yes || echo no)

        case "$expect" in
            in-place)
                if [ "$created" = no ] && [ "$asked" = no ] && [ "$in_place" = yes ]; then
                    pass=$((pass + 1)); echo "  Run $i: PASS (worked in place, no prompt)"
                else
                    fail=$((fail + 1)); echo "  Run $i: FAIL (created=$created asked=$asked in_place=$in_place)"
                fi ;;
            worktree)
                if [ "$created" = yes ]; then
                    pass=$((pass + 1)); echo "  Run $i: PASS (worktree set up on request)"
                else
                    fail=$((fail + 1)); echo "  Run $i: FAIL (no worktree despite explicit request)"
                fi ;;
            asks-or-creates)
                if [ "$created" = yes ] || [ "$asked" = yes ]; then
                    pass=$((pass + 1)); echo "  Run $i: PASS-AS-RED (created=$created asked=$asked)"
                else
                    fail=$((fail + 1)); echo "  Run $i: INCONCLUSIVE (agent already worked in place)"
                fi ;;
        esac

        cd "$SCRIPT_DIR"
        cleanup_test_project "$test_dir"
    done

    echo ""
    echo "--- $phase_name Results: $pass/$RUNS passed, $fail/$RUNS failed ---"
    [ "$fail" -eq 0 ]
}

case "$PHASE" in
    red)
        echo "--- RED: current worktree-by-default skill, unrequested isolation ---"
        echo "Expected: agent asks for worktree consent or creates one"
        run_phase "RED" "$UNREQUESTED_SCENARIO" "asks-or-creates" ;;
    green)
        echo "--- GREEN: opt-in skill, unrequested isolation ---"
        echo "Expected: agent works in place, no worktree, no consent prompt"
        run_phase "GREEN" "$UNREQUESTED_SCENARIO" "in-place" ;;
    requested)
        echo "--- REQUESTED: opt-in skill, human partner asked for a worktree ---"
        echo "Expected: agent sets one up (native tool preferred)"
        run_phase "REQUESTED" "$REQUESTED_SCENARIO" "worktree" ;;
    *)
        echo "Usage: $0 [red|green|requested] [runs]"; exit 1 ;;
esac
