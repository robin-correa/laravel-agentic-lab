---
name: commit-msg
description: 'Drafts a commit message for the staged changes, using the ticket reference from the branch name, and commits only after the user confirms. Only run when the user invokes /commit-msg.'
argument-hint: '[optional hint, e.g. "fix review feedback"]'
disable-model-invocation: true
---

# Commit Message

Draft a commit message for the **staged** changes. Optional hint from the user: $ARGUMENTS

## 1. Read the changes

```bash
git branch --show-current
git diff --cached --stat
git diff --cached
```

If nothing is staged, stop. Show `git status --short` and tell the user to stage the files they want first (`git add <files>`). Never stage files yourself.

## 2. Find the ticket reference in the branch name

Check in this order and stop at the first match:

| Branch contains                          | Ticket ref  | Example branch                    |
| ---------------------------------------- | ----------- | --------------------------------- |
| `GH-<number>`                            | `#<number>` | `fix/GH-45-login-redirect`        |
| Jira key: uppercase letters, `-`, number | `PROJ-123`  | `feature/PROJ-123-invoice-export` |
| Neither                                  | none        | `chore/gate-sail-support`         |

Never invent a ticket ref.

## 3. Pick the type

Use the branch prefix when there is one: `feature/` → `feat`, `fix/` → `fix`, `chore/` → `chore`. Otherwise choose from the diff: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`.

## 4. Write the message

```
<type>: [<ticket ref>] <summary>

<body>

<trailer>
```

- **Summary:** imperative mood ("add", not "added"), lowercase after the colon, no period, under 72 characters including the prefix.
- **Body:** what changed and why, wrapped at 72 characters. Skip it for trivial changes. Use the user's hint if given.
- **Ticket parts:**

| Ticket ref | Summary                             | Trailer          |
| ---------- | ----------------------------------- | ---------------- |
| `PROJ-123` | `feat: PROJ-123 add invoice export` | `Refs: PROJ-123` |
| `#45`      | `fix: resolve login redirect (#45)` | `Closes #45`     |
| none       | `chore: run tests through Sail`     | (omit)           |

Describe only what is in the staged diff, not unstaged or untracked files.

## 5. Confirm, then commit

Show the message in a code block and ask: "Commit with this message?"

- **Yes** → `git commit -F -` with the message via a heredoc. Show the resulting `git log --oneline -1`.
- **Changes requested** → revise and ask again.
- Never push, amend or stage as part of this command.
