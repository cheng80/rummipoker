---
name: caveman-commit-push
description: Safely commit current repository changes with a caveman-commit style Conventional Commit message, push the current branch, create a Pull Request, and merge it after verification. Use when the user says "커밋 푸시", "커밋/푸시", "commit push", "caveman commit push", or asks to commit, push, and integrate changes.
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

7. Create a Pull Request only after the commit is pushed and the diff and CI
checks are reviewed. Use a Korean title and body with these sections:

```text
## 변경 내용
## 변경 이유
## 검증
## 제외 범위 및 주의사항
```

Keep the Pull Request limited to one logical purpose. Do not create a Draft
Pull Request for work that is ready to merge.

8. After CI and the final diff review pass, squash-merge the Pull Request and
delete the feature branch. Do not merge when CI is failing or required review
is missing. If merge is blocked, report the blocker and its smallest fix.

```bash
gh pr merge <number> --squash --delete-branch
```

After a successful merge, synchronize the base branch and remove any local
feature worktree or branch that is no longer needed. Never force-push or use
destructive reset/checkout commands.

## Reporting

Report in Korean with:

- Files committed.
- Commit message.
- Commit hash.
- Branch pushed.
- Push result.
- Pull Request URL, title, and review/CI result.
- Merge commit and branch/worktree cleanup result.

If there is nothing to commit, say so and do not create an empty commit unless
the user explicitly asks. If there is no new commit but an existing pushed
branch has an unmerged Pull Request, inspect it and continue only when the
user requested the full integration flow.
