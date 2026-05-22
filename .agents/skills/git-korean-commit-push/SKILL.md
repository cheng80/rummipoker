---
name: git-korean-commit-push
description: Safely commit current repository changes with a concise Korean summary commit message and push the current branch. Use when the user says "커밋 푸시해줘", "커밋/푸시해줘", "한글 커밋해줘", "변경사항 커밋하고 푸시", "git commit push", or asks for a Korean summary commit message.
---

# Git Korean Commit Push

## Workflow

Use this skill from the repository root. Keep secrets and generated artifacts out of commits.

1. Inspect repository state:

```bash
git status --short
git branch --show-current
git diff --stat
```

2. Identify commit candidates.

Include source, docs, scripts, tests, and skill files that match the user's requested scope. Exclude ignored/generated/sensitive files such as:

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

3. Review enough diff to write a correct Korean summary:

```bash
git diff -- <paths>
git diff --cached --stat
git diff --cached --check
```

If the diff contains secrets, credentials, tokens, private keys, or unintended generated artifacts, stop and report the exact file path without printing the secret.

4. Create a concise Korean one-line commit message.

Examples:

```text
NAS 웹 배포 자동화 절차 추가
NAS 웹 빌드 검증 스킬 추가
상점 카드 설명 줄바꿈 안정화
```

Prefer a short noun phrase or verb phrase. Do not include token values, URLs with secrets, or overly broad messages such as `작업`.

5. Commit:

```bash
git add <explicit paths>
git commit -m "<Korean summary>"
```

6. Push the current branch:

```bash
git push
```

If the branch has no upstream, use:

```bash
git push -u origin "$(git branch --show-current)"
```

Do not force push. Do not run `git reset --hard`, `git checkout --`, or destructive cleanup commands unless the user explicitly asks.

## Reporting

Report in Korean with:

- Files committed.
- Commit message.
- Commit hash.
- Branch pushed.
- Push result.

If there is nothing to commit, say so and do not create an empty commit unless the user explicitly asks.
