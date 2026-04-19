# 12. Changelog From V3

> 문서 성격: V3 -> V4 policy changelog
> 코드 반영 상태: docs-only
> 핵심 정책: V3의 방향성은 살리되, current/target 혼선을 제거한다.

## 1. V4가 V3에서 바로잡은 것

[V4_DECISION]

V3의 문제는 방향성이 아니라 권한 구조였다. V3에는 현재 구현과 미래 목표가 같은 강도로 선언되어 있어, 다음 개발 세션에서 잘못된 코드 변경을 유도할 수 있었다.

V4는 다음을 바로잡는다.

| 영역 | V3 위험 | V4 수정 |
|---|---|---|
| 문서 권한 | target을 즉시 구현 기준처럼 표현 | `[CURRENT]`, `[TARGET]`, `[FUTURE]`, `[EXPERIMENT]` 분리 |
| One Pair | 10점 current처럼 읽힐 위험 | V4 기본은 0점 dead line |
| Station | 30 Station 확정처럼 읽힘 | 구조 target, 숫자는 미확정 |
| Entry/Pressure/Lock | current 전제처럼 읽힘 | Station modifier target |
| 저장 | Drift/SQLite가 즉시 기준처럼 읽힘 | current active run save v2 보호 |
| 코드 rename | StationState 등 즉시 rename 위험 | UI-first, code rename later |
| Migration | 오래된 5장 완성 프로토타입에서 출발하는 듯함 | 현재 즉시 확정 build에서 출발 |
| 콘텐츠 | Run Kit/Permit/Glyph 등을 current처럼 읽힘 | content layers target으로 격리 |

## 2. One Pair 정책 변경

[V4_DECISION]

V4는 One Pair를 0점 dead line으로 고정한다.

이유:

- 현재 코드와 일치한다.
- dead line 압박을 유지한다.
- contributor 제거 전략을 보호한다.
- Jester pair condition 폭발을 막는다.
- target score curve 재작업을 피한다.

One Pair 10점은 별도 실험이다.

## 3. Run Structure 정책 변경

[V4_DECISION]

V4는 현재 stage loop를 인정한다.

현재:

```text
stage + cash-out + Jester shop + next stage
```

Target:

```text
sector + station + market + archive
```

전환은 개념/UX부터 진행하고 코드 rename은 나중이다.

## 4. Save 정책 변경

[V4_DECISION]

V4는 현재 save를 제품 안정성의 핵심으로 본다.

현재 save:

- active run snapshot
- GetStorage
- HMAC
- schemaVersion 2
- stageStartSnapshot

Target save:

- profile
- active run
- checkpoint
- run history
- archive
- stats

단, target save는 current save를 즉시 대체하지 않는다.

## 5. Content 정책 변경

[V4_DECISION]

V4는 Jester 중심 current를 인정하고, 장기 content layer를 target으로 둔다.

현재:

- curated common Jester 38종
- current scoring/economy/stateful subset
- Jester-only shop

Target:

- Jester
- Run Kit
- Permit
- Glyph
- Orbit
- Echo
- Sigil
- Risk Grade
- Trial
- Archive

## 6. Implementation Policy 변경

[V4_DECISION]

V4 기준 구현 순서:

```text
docs lock
→ regression tests
→ compatibility wrapper
→ ruleset config
→ UI terminology
→ market adapter
→ save adapter
→ station modifier
→ archive/stats
→ balance pass
```

V3처럼 큰 target 문서를 근거로 한 번에 code rewrite하지 않는다.
