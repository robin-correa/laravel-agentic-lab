# Orchestration Flow

```
Triage → Ticket → Context → Plan → [USER APPROVES] → Implement → Review → Gate + Verdict ─┐
                                                          ▲                               │
                                                          └─────── needs changes ─────────┘
                                                                   (max 2 rounds)
                                                        approved → Draft PR
```

## Roles

| Role         | Who                    | Writes                                                                       |
| ------------ | ---------------------- | ---------------------------------------------------------------------------- |
| Orchestrator | The main session (you) | `git-start.txt`, `ticket.md`, `context.md`, `plan.md`, `verdict.md`, `pr.md` |
| Implementer  | `implementer` subagent | Code, tests, `implementation-<round>.md`                                     |
| Reviewer     | `reviewer` subagent    | `review-<round>.md`                                                          |

## Handoff folder

All artifacts live in `.ai/work/<ticket-slug>/`.
Subagents start with no memory of this conversation. These files are the only context they get, so make them complete but short.

### Ticket reference

Look for a ticket reference at the start of the request and build `<ticket-slug>` from it plus 2–4 kebab-case words describing the work:

| Request starts with                   | Ticket ref | `<ticket-slug>`           |
| ------------------------------------- | ---------- | ------------------------- |
| Jira key, e.g. `PROJ-123`             | `PROJ-123` | `PROJ-123-invoice-export` |
| GitHub issue, e.g. `#123` or `GH-123` | `GH-123`   | `GH-123-invoice-export`   |
| Nothing                               | none       | `invoice-export`          |

Jira keys are uppercase letters, a dash and a number. Keep the key's original casing. Never invent a ticket ref; if none was given, use words only.
Record the ticket ref at the top of `ticket.md`.

Suggest a matching branch name to the user, e.g. `feature/PROJ-123-invoice-export` or `fix/GH-123-login-redirect`. Do not create or switch branches yourself.

---

## Step 1: Triage

Talk with the user until the request is clear. Ask only what you cannot answer from the code:

- What problem does this solve, and for whom?
- What is in scope and what is explicitly out of scope?
- How will we know it works (acceptance criteria)?

Keep it brief. Two or three questions is usually enough.

Also run `.ai/scripts/gate.sh full` once now. If it already fails before any change, tell the user. Otherwise the gate in Step 7 cannot tell your failures from existing ones.

Then record the git state before any change:

```bash
mkdir -p .ai/work/<ticket-slug>
{ git branch --show-current; git status --short; } > .ai/work/<ticket-slug>/git-start.txt
```

If `git status --short` shows uncommitted changes, tell the user they will be mixed into the ticket's diff and recommend committing or stashing them before approving the plan. Continue either way; `git-start.txt` lets the agents tell old changes from new ones.

## Step 2: Ticket

Write `ticket.md` in this format (it mirrors a Jira ticket so it can be pasted or synced later):

```markdown
# <Title>

**Ticket:** PROJ-123 | GH-123 | none
**Type:** Feature | Bug | Chore

## Summary

One or two sentences.

## Acceptance Criteria

- [ ] Given ..., when ..., then ...

## Out of Scope

- ...
```

## Step 3: Context (the "fingerprint")

Explore the codebase once, then write `context.md` so no other agent has to repeat that exploration:

```markdown
## Relevant Files

- `app/Http/Controllers/...` — what it does, why it matters here

## Existing Patterns to Follow

- e.g. "Controllers use Form Requests for validation (see app/Http/Requests/...)"

## Applicable Rules

- Skills and AGENTS.md rules the implementer must follow (e.g. laravel-best-practices, wayfinder-development)
```

## Step 4: Plan — then STOP

Write `plan.md`:

```markdown
## Approach

A short paragraph.

## Steps

1. File to create/change — what changes

## Tests

- Feature: ...
- Unit: ...
- E2E (optional, only if the behavior is only verifiable in the browser): ...

## Risks / Open Questions
```

Show the user a summary of the plan and **wait for approval**. If they ask for changes, update `plan.md` and ask again.
After approval, continue through the remaining steps without stopping.

## Step 5: Implement

Spawn the `implementer` subagent. Give it the ticket folder path and the round number. Nothing else is needed; it reads the files.

## Step 6: Review

Spawn the `reviewer` subagent with the ticket folder path and the round number.

## Step 7: Verdict

First run the **final gate** yourself:

```bash
.ai/scripts/gate.sh full
```

It runs Pint, JS lint/format, TypeScript, Larastan and the full Pest suite, and prints one line per check plus the failure details. It ends with `GATE (full): PASSED` or `FAILED`. Do not trust a "tests pass" claim from an agent; trust this output.

Then check the git state:

```bash
git branch --show-current
git status --short
```

Compare it with `git-start.txt`:

- Every new or changed path must be either in `git-start.txt` or in the changed-files list of `implementation-<round>.md`. Anything else is out of scope: treat it as a blocking issue.
- A path from `git-start.txt` whose staging changed (e.g. `M ` became ` M`) or that disappeared means something touched git state. Agents are not allowed to do that. Report it to the user in your final message; it is not blocking, because no work is lost.
- If the branch changed, note it. The user may have switched branches on purpose.

Then read `review-<round>.md` and write `verdict.md` (include the gate result and the git check):

- **Approved** — the gate passes and no blocking issues remain. Go to Step 8.
- **Needs changes** — list the blocking issues to fix and go back to Step 5 with the next round number.

Hard limit: **2 implementation rounds.** If round 2 still has blocking issues, stop and report them to the user instead of looping.
Non-blocking suggestions go into `pr.md` as follow-ups, not into another round.

## Step 8: Draft PR

Write `pr.md`:

```markdown
## Commit Message

<type>: [<ticket ref>] <summary under 72 chars>

<body: what and why>

<trailer>

## PR Title

[<ticket ref>] <title>

## PR Description

<link line>

### Summary

### Changes

### Testing

### Follow-ups
```

Fill the ticket parts based on the ticket ref:

| Ticket ref | Commit summary                      | Trailer          | PR title                      | Link line in PR description |
| ---------- | ----------------------------------- | ---------------- | ----------------------------- | --------------------------- |
| `PROJ-123` | `feat: PROJ-123 add invoice export` | `Refs: PROJ-123` | `PROJ-123 Add invoice export` | `Jira: PROJ-123`            |
| `GH-123`   | `feat: add invoice export (#123)`   | `Closes #123`    | `Add invoice export (#123)`   | `Closes #123`               |
| none       | `feat: add invoice export`          | (omit)           | `Add invoice export`          | (omit)                      |

`Closes #123` makes GitHub close the issue automatically when the PR merges. Jira links commits and PRs that contain the key when the Jira–GitHub integration is enabled.

Finish by telling the user the work is ready, where `pr.md` is, and which tests ran. Do not commit or push.
