# Boss Pool Expansion Mapping

> 문서 성격: planning / reference-only mapping
> 목적: 공모전용 boss pool 1차 확장을 위해 외부 reference boss pattern을 우리 게임 룰 패턴으로 재작성한다.
> 주의: 아래 reference 이름은 매핑 검토용이다. 런타임 표시명, 저장 id, UI copy로 그대로 쓰지 않는다.

## 1. Current State

현재 우리 게임의 boss pool은 두 층으로 나뉜다.

| Layer | Count | Notes |
|---|---:|---|
| Simulation proxy pool | 10 | `CURRENT_LEVELING_RUNTIME_SPEC.md`의 boss constraint proxy 기준 |
| Runtime modifier type | 8 | battle/save/display/settlement penalty 경로가 있는 modifier 타입 |
| S1~S8 runtime cycle slot | 8 | Station마다 1개씩 고정 배치 |

현재 문제:

- S1~S8에 boss가 8번만 나오므로 반복 run에서 전략 학습 폭이 좁다.
- reference boss pattern은 28개인데, 현재는 이를 10개 family로 압축했다.
- 공모전용 vertical slice 기준에서도 boss 다양성은 전략성 인상에 직접 영향을 준다.

## 2. Mapping Policy

- reference 이름과 테마를 그대로 쓰지 않는다.
- 우리 게임의 타일/라인/확정/자원/골드/마켓/아이템/Jester 발동 제한으로 다시 쓴다.
- 자동 자원 지급, 직접 지급, 고정 offer slot, 강제 판매/강제 구매는 금지한다.
- 유저 선택을 빼앗는 효과는 simulation-only 또는 제외한다.
- 저장 포맷이 필요한 후보는 출품 전 1차 구현에서 제외하거나 별도 승인 대상으로 둔다.

## 3. Reference Pattern Mapping

| # | Reference pattern | Core pressure | Current absorption | Proposed game pattern | 1차 판단 |
|---:|---|---|---|---|---|
| 1 | The Hook | play 후 hand disruption | not absorbed | 확정 후 손패 1~2장 임시 잠금 또는 추가 discard pressure | simulation first |
| 2 | The Ox | 특정 hand type 사용 시 money reset | partial via economy tax ideas | 가장 많이 확정한 족보를 다시 쓰면 이번 Station reward 일부 tax | runtime possible |
| 3 | The House | first hand hidden | not absorbed | 전투 시작 손패 일부를 첫 이동 전까지 정보 숨김 | risky UI, defer |
| 4 | The Wall | larger target | proxy `target_spike_wall` | Boss target multiplier spike | simulation only first |
| 5 | The Wheel | random hidden cards | not absorbed | 드로우된 손패 일부가 값/색 중 하나를 늦게 reveal | risky UI, defer |
| 6 | The Arm | played hand level down | partial via score dampening | 확정한 족보 family의 다음 점수 base 감소 | runtime possible |
| 7 | The Club | suit debuff | absorbed by color dampener | 특정 색상 타일 포함 라인 점수 감소 | already absorbed |
| 8 | The Fish | hidden after each play | not absorbed | 확정 후 다음 드로우 일부 늦게 reveal | risky UI, defer |
| 9 | The Psychic | fixed play size | not absorbed | 확정 라인의 최소 기여 타일 수 조건 | runtime possible |
| 10 | The Goad | suit debuff | absorbed by color dampener | 특정 색상 타일 포함 라인 점수 감소 | already absorbed |
| 11 | The Water | no discard | partial via resource squeeze | hand discard 0 또는 discard cost 증가 | simulation first |
| 12 | The Window | suit debuff | absorbed by color dampener | 특정 색상 타일 포함 라인 점수 감소 | already absorbed |
| 13 | The Manacle | hand size -1 | proxy `resource_squeeze` | max hand size pressure | simulation first, runtime risky |
| 14 | The Eye | no repeated hand type | implemented repeat pressure | 같은 족보 반복 확정 시 점수 감소 또는 무효화 | implemented, not in cycle |
| 15 | The Mouth | only one hand type | implemented single rank pressure | 첫 확정 족보 family만 고효율, 다른 family penalty | implemented, not in cycle |
| 16 | The Plant | face card debuff | absorbed by face tile dampener | 11~13 포함 라인 점수 감소 | already absorbed |
| 17 | The Serpent | draw count fixed | not absorbed | 확정/버림 후 refill 수 제한 또는 고정 | simulation first |
| 18 | The Pillar | previous ante cards debuff | not absorbed | 이전 Station에서 많이 쓴 rank/color가 다음 Boss에서 약화 | needs tracking, defer |
| 19 | The Needle | one hand only | not absorbed | confirm 횟수 1회 제한 또는 2회차 이후 큰 tax | runtime possible via confirm count |
| 20 | The Head | suit debuff | absorbed by color dampener | 특정 색상 타일 포함 라인 점수 감소 | already absorbed |
| 21 | The Tooth | played card money loss | not absorbed | 확정 기여 타일 수만큼 reward tax | runtime possible |
| 22 | The Flint | base chip/mult halved | absorbed by all score dampener | 모든 점수 라인 감소 | already absorbed |
| 23 | The Mark | face cards hidden | not absorbed | 11~13 타일 정보 일부 늦게 reveal | risky UI, defer |
| 24 | Amber Acorn | Joker hidden/reordered | not absorbed | Jester 발동 순서 일부 셔플 또는 표시 지연 | risky, defer |
| 25 | Verdant Leaf | sell Joker to remove debuff | not allowed as forced sell | 판매 강제 대신 보유 Jester 수에 따른 boss tax | simulation only / redesign |
| 26 | Violet Vessel | very large target | proxy `target_spike_wall` | Boss target multiplier spike stronger variant | simulation only first |
| 27 | Crimson Heart | random Joker disabled each hand | not absorbed | 매 confirm마다 Jester 1개 발동 제외 | runtime possible, high risk |
| 28 | Cerulean Bell | force selected card | not absorbed | 손패/보드 후보 1개를 이번 액션에 반드시 포함하면 bonus, 미포함 penalty는 금지 | redesign needed |

## 4. 1차 확장 후보

출품 전 1차로 비교적 안전한 후보:

| Candidate | Base reference | Why |
|---|---|---|
| `reward_tax_by_repeat_rank_v1` | Ox / Tooth | reward tax는 저장 포맷 변경 없이 settlement/economy trace로 검증 가능 |
| `min_contributor_count_v1` | Psychic | 확정 후보 계산 경로에 붙일 수 있고 전략성이 분명함 |
| `confirm_limit_tax_v1` | Needle | 기존 confirm count tax 경로를 확장 가능 |
| `rank_family_decay_v1` | Arm | 기존 repeat/single rank pressure와 유사한 저장/표시 구조 활용 가능 |
| `jester_skip_one_v1` | Crimson Heart | 전략성은 강하지만 UI/정산 feedback이 필요하므로 마지막 후보 |

1차 runtime 편입 우선순위:

1. `confirm_limit_tax_v1`
2. `min_contributor_count_v1`
3. `reward_tax_by_repeat_rank_v1`
4. `rank_family_decay_v1`
5. `jester_skip_one_v1`

## 5. Excluded From 1차

- hidden card 계열: UI/정보 reveal 작업이 커서 출품 전 위험하다.
- forced sell / forced selection 계열: 유저 선택 강제처럼 보일 수 있어 재설계 필요.
- previous Station memory 계열: 새 tracking이 필요해 저장/복원 리스크가 있다.
- very large target 계열: target spike는 시뮬레이션으로만 먼저 본다.

## 6. Next Step

1. 위 1차 후보를 simulation proxy id로 추가한다.
2. S1~S8 cycle에 바로 넣지 않고 experiment axis로 r80~r120 smoke를 돌린다.
3. S1/S2/S3/S7/S8 병목과 board/draw stop을 확인한다.
4. 안전한 후보만 runtime modifier 구현 대상으로 좁힌다.
