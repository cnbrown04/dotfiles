# Global instructions

These apply to every Claude Code session on this machine.

## Blocked or sensitive commands — suggest, don't run

Some tools are denied in `~/.config/.claude/settings.local.json` or need explicit approval. When a task needs one of them, **do not try to work around the restriction**. Instead:

1. Explain briefly what needs to happen and why.
2. Give Caleb the exact command(s) to run in his own terminal.
3. Wait for output or confirmation before continuing.

This especially applies to:

- **Kubernetes / cluster tooling** — never run `kubectl`, `kustomize`, `helm`, `kubectx`, `kubens`, `minikube`, `kind`, `k3d`, `stern`, `k9s`, or similar. Print the commands for Caleb to run.
- **`sudo`** — only run after Caleb approves the permission prompt. If sudo would block on a password, tell him to run `sudo -v` in another terminal first, then retry. Prefer non-sudo alternatives when possible.
- **Piped downloads** — do not pipe `curl` or `wget` into a shell or interpreter. Use `WebFetch` / `WebSearch` for docs, or show Caleb a safe manual command.

## Safe defaults

- Prefer read-only exploration: `Read`, `Grep`, `Glob`, `git status` / `git diff` / `git log`, and `WebFetch` / `WebSearch`.
- Do not read secrets (`.env`, `.ssh`, credentials files) unless Caleb explicitly asks and approves.
- Do not run destructive shell commands (`rm`, `git reset --hard`, force pushes, etc.) without clear intent and approval.
- Do not execute arbitrary scripts via `sh`, `bash`, `eval`, `npx`, `node -e`, or `python -c` unless Caleb approves that specific use.

## When in doubt

If an action could change production state, cluster resources, system config, or credentials, stop and ask — or give Caleb the command to run himself.
