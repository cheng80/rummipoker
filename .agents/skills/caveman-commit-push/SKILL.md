---
name: caveman-commit-push
description: Safely commit current repository changes with a caveman-commit style Conventional Commit message and push the current branch. Use when the user says "커밋 푸시", "커밋/푸시", "commit push", "caveman commit push", or asks to commit and push with a terse commit message.
---

# Caveman Commit Push

Commit and push repository changes safely. Generate the commit message using
`caveman-commit` rules: terse, exact, Conventional Commits format.

## Workflow

Use this skill from the repository root. Keep secrets and generated artifacts
out of commits.

1. Inspect repository state:

```bash
git status --short
git branch --show-current
git diff --stat
```

2. Identify commit candidates.

Include source, docs, scripts, tests, and skill files that match the user's
requested scope. Exclude ignored/generated/sensitive files such as:

```text
.env
.env.*
.rummipoker_deploy.env
build/
rummipoker/
rummipoker.zip
*.log
```

Never run `git add .` blindly. Stage explicit paths only.

3. Review enough diff to write a correct message:

```bash
git diff -- <paths>
git diff --cached --stat
git diff --cached --check
```

If the diff contains secrets, credentials, tokens, private keys, or unintended
generated artifacts, stop and report the exact file path without printing the
secret.

4. Generate the commit message with `caveman-commit` rules.

Subject:

```text
<type>(<scope>): <imperative summary>
```

Rules:

- Types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `chore`,
  `build`, `ci`, `style`, `revert`
- Scope is optional.
- Prefer <=50 chars, hard cap 72.
- No trailing period.
- Body only for non-obvious why, breaking changes, migrations, security fixes,
  or reverts.
- No AI attribution.

Examples:

```text
fix(market): stabilize tab content height
```

```text
docs(skills): add caveman commit push flow
```

5. Stage explicit paths and commit:

```bash
git add <explicit paths>
git commit -m "<subject>"
```

For a required body:

```bash
git commit -m "<subject>" -m "<body>"
```

6. Push the current branch:

```bash
git push
```

If the branch has no upstream:

```bash
git push -u origin "$(git branch --show-current)"
```

Do not force push. Do not run `git reset --hard`, `git checkout --`, or
destructive cleanup commands unless the user explicitly asks.

## Reporting

Report in Korean with:

- Files committed.
- Commit message.
- Commit hash.
- Branch pushed.
- Push result.

If there is nothing to commit, say so and do not create an empty commit unless
the user explicitly asks.
