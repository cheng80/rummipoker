# daily_logs Folder Definition

`docs/planning/verification/daily_logs/`는 날짜별 검증/산출물 이력을 기록하는 폴더다.

GCSE 역할: `Execution`

## Purpose

- 하루 단위로 의미 있는 검증 명령, 실구동 시나리오, 산출물 경로를 남긴다.
- `STATUS.md`가 긴 로그로 비대해지는 것을 막는다.
- 최신 상태 판단은 `docs/planning/STATUS.md`가 맡고, 상세 검증 이력 검색은 이 폴더가 맡는다.

## File Naming

```text
YYYY-MM-DD.md
```

예:

```text
2026-04-22.md
```

## Write Rule

날짜별 파일에는 아래만 남긴다.

- 검증 목적
- 실행 명령
- 결과 요약
- 실패/주의사항
- 산출물 경로
- 관련 문서/코드 변경 링크

최신 진행률이나 다음 작업 판단은 `docs/planning/STATUS.md`에 둔다.
오래된 날짜별 히스토리가 너무 커지면 `docs/archive/legacy/verification_history/`로 이동한다.
