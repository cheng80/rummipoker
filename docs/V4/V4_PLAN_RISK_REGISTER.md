# V4 Plan Risk Register

문서 목적: V4 마이그레이션 초기 단계에서 회귀 가능성이 큰 영역을 식별하고 보호 장치를 정리한다.

| Risk | Impact | Likelihood | Mitigation | Guardrail Test |
|---|---|---|---|---|
| One Pair 10점 오도입 | Critical | Medium | `hand_rank.dart` 기준을 baseline lock, PR 체크리스트에 명시 | `One Pair == 0`, confirm 후보 아님 |
| contributor 제거 대신 line 전체 제거 회귀 | Critical | Medium | confirm 변경은 compatibility wrapper 뒤에서만 수행 | Two Pair 키커 유지 테스트 |
| overlap multiplier 상수 변경 | High | Medium | alpha/cap을 ruleset default에 명시하되 current default 보호 | overlap alpha/cap regression test |
| Jester 발동 순서 변경 | High | Medium | 슬롯 순서 처리 정책 문서화, refactor 전 snapshot test | Jester effect ordering test |
| `stageStartSnapshot` 손상 | Critical | Medium | save/restart adapter는 read-only shadow mode부터 시작 | restart returns exact stage-start state |
| active run save/load 호환성 파손 | Critical | Medium | save schema 교체 금지, adapter layer만 허용 | save/load parity + HMAC verify |
| 코드 rename으로 Provider/UI/save 연결 파손 | High | Medium | terminology 전환은 docs → UI copy → code rename 순서 고정 | route + provider smoke tests |
| Station 용어가 current runtime으로 오해됨 | Medium | High | plan/docs에 target label 강제, feature flag 전까지 UI-only 용어 제한 | review checklist for labels |
| DB 도입으로 continue 깨짐 | Critical | Medium | DB는 read model 또는 adapter 준비 단계까지만 허용 | continue load existing save v2 |
| Jester catalog id 변경 | Critical | Low | id rename 금지 정책 명시 | catalog load + saved state restore |
| economy 수치와 전투 룰 동시 변경 | High | Medium | combat PR과 balance PR 분리 | PR scope checklist |
| UI-only 변경이 도메인 변경으로 번짐 | High | Medium | 전투 로직 수정과 UI 리디자인 PR 분리 | UI PR must not touch logic files |
| `Blind`/`Stage` alias 도입이 저장 필드 rename으로 이어짐 | High | Medium | alias 문서화만 먼저, persistence key rename 금지 | save payload field snapshot |
| ruleset config skeleton이 current behavior를 바꿈 | High | Medium | default config는 current constants mirror only | current ruleset parity tests |
| shop adapter 작업 중 기존 reroll/buy/sell 흐름 파손 | High | Medium | adapter는 `jester_meta.dart` 앞단에 얇게 두기 | shop buy/sell/reroll smoke test |
| archive/stats read model이 active run과 결합됨 | Medium | Medium | read model은 append-only summary from existing state | no active run schema diff review |
