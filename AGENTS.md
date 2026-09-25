## Agent skills

### Issue tracker

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the default labels `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, and `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Use the single-context layout: root `CONTEXT.md` and `docs/adr/`. See `docs/agents/domain.md`.

### Codex delegation

Codex handoffs use gpt-repo-local Delegation v3. Create durable handoffs with the Delegation v3 task writer so the prompt, manifest, result contract, and review gate stay bound together; do not hand-author standalone Codex prompts.
