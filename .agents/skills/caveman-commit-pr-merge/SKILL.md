---
name: caveman-commit-pr-merge
description: Use when the user explicitly asks to commit, push, open a Pull Request, or merge repository changes in one integration flow, including requests such as "커밋 푸시 PR 머지" or "커밋/푸시/PR/머지".
---

# Caveman Commit PR Merge

현재 저장소 변경을 검토하고, 목적별 커밋을 만든 뒤 원격 푸시·Pull Request·squash Merge까지 안전하게 완료한다.

## 실행 순서

1. 저장소 루트에서 상태와 범위를 확인한다.

```bash
git status --short
git branch --show-current
git diff --stat
git diff --cached --stat
```

2. 사용자 요청 범위에 맞는 파일만 후보로 삼는다. `git add .`를 사용하지
않고 경로를 명시한다. `.env*`, 배포 비밀정보, build 산출물, 로그,
압축물, 생성 캐시는 제외한다.

3. staged diff를 검토한다.

```bash
git diff -- <paths>
git diff --cached --check
```

비밀정보, 무관 변경, 의도하지 않은 생성물이 있으면 커밋을 중단하고
파일 경로와 제거 방법을 보고한다.

4. 프로젝트 규칙에 맞는 한국어 커밋 메시지로 목적별 커밋을 만든다.
한 커밋에 무관한 작업을 섞지 않는다.

```bash
git add <explicit paths>
git commit -m "<분류>: <변경 내용>"
```

5. 현재 브랜치를 푸시한다. upstream이 없으면 다음 명령을 사용한다.

```bash
git push
git push -u origin "$(git branch --show-current)"
```

force push, `git reset --hard`, `git checkout --`는 사용하지 않는다.

6. 푸시 성공 후 한국어 Pull Request를 생성한다. PR은 하나의 논리적
목적만 포함하고 다음 본문 구조를 사용한다.

```text
## 변경 내용
## 변경 이유
## 검증
## 제외 범위 및 주의사항
```

7. PR의 파일 diff와 CI 상태를 확인한다. 필수 체크가 실패하거나 승인·권한·
충돌이 해결되지 않았으면 Merge하지 않는다. 체크가 아예 보고되지 않으면
`통과`라고 쓰지 말고 `미보고`로 명시한 뒤 필수 보호 규칙이 없는 경우에만
로컬 검증 근거와 함께 진행한다.

8. 검증된 PR만 squash Merge하고 원격 feature 브랜치를 삭제한다.

```bash
gh pr merge <number> --squash --delete-branch
git fetch --prune origin
```

Merge 후 `main`과 `origin/main`의 SHA가 일치하고 작업 트리가 clean인지
확인한다. 미병합 브랜치는 삭제하지 않는다.

## 실패 처리

각 실패는 실제 명령·종료 코드·영향·확정 원인과 가설·권장 해결책·대안·
다음 검증을 함께 보고한다. 네트워크·인증·upstream·CI·충돌 문제를
무시하거나 성공으로 포장하지 않는다.

## 결과 보고

한국어로 커밋 파일·메시지·SHA, 푸시 브랜치와 결과, PR URL·상태, Merge
커밋과 브랜치 정리 결과를 보고한다. 변경이 없으면 빈 커밋을 만들지 않는다.
