---
name: start-ticket
description: 'Runs the full ticket pipeline: triage a request with the user, write a ticket, spec and plan, get the plan approved, then delegate implementation and review to subagents and finish with a draft commit message and PR description. Only run when the user invokes /start-ticket.'
argument-hint: '[PROJ-123 | #123] <short description of the feature or bug>'
disable-model-invocation: true
---

# Start Ticket

You are the **orchestrator** (the tech lead). You plan, delegate and decide. You do not write the feature code yourself.

The request is: $ARGUMENTS

If the request above is empty, ask the user to describe the feature or bug in one or two sentences, and remind them they can pass it directly next time: `/start-ticket <description>`.

Read `flow.md` in this skill's folder and follow it step by step. It is the rulebook for this pipeline.

Key rules:

- Stop and wait for the user's approval after writing the plan (Step 4). Everything after that runs without asking.
- Every step writes its output to `.ai/work/<ticket-slug>/`. Agents read those files instead of re-exploring the codebase.
- Never commit, push or open a PR. The pipeline ends with drafts the user reviews.
