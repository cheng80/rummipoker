# Reverse Design Synthesis

> 역할: 2026-07-17 조사 결과를 실제 제품 판단에 쓸 수 있게 정리한 문서다. 현재 동작은 [docs/core](../core/GAME_DESIGN.md)가 기준이며, 아직 구현하지 않은 내용은 후보나 보류로 표시한다.

## 먼저 읽을 결론

1. 지금 가장 먼저 고칠 문제는 콘텐츠 수가 아니다. 보상 안내가 실제 계산과 맞는지, 저장한 게임을 믿고 이어갈 수 있는지, 보상이 두 번 지급되지 않는지가 더 중요하다.
2. Balatro에서 참고할 부분은 짧은 효과 문구, 눈에 보이는 위험과 보상, 순서가 느껴지는 연출, 여러 방식으로 도전하게 하는 목표다. 정확한 점수를 일부러 숨기는 방식, 카지노 분위기, 콘텐츠 수 경쟁은 가져오지 않는다.
3. 출시 때는 유료 완성형 게임, 광고 없음, 게임플레이를 바꾸는 결제 없음이 가장 잘 맞는다. 광고가 정말 필요해질 때만 별도 검증을 시작한다.
4. 광고를 시험한다면 S1 Boss 정산이 끝난 뒤 Market에 들어가기 전에 한 번만 선택형 광고를 보여 주고, 다음 5G 리롤 1회를 무료로 만드는 안이 유일한 후보다.

## 현재 게임을 쉽게 요약하면

| 영역 | 지금 게임에서 실제로 일어나는 일 | 문서나 화면에서 조심할 점 |
|---|---|---|
| 진행 | Station은 Scout→Clash→Boss 순서다. Blind가 끝나면 정산과 Market을 거친다. S8에서 완료하거나 Endless로 이어간다 | Blind Select는 큰 보상 분기라기보다 다음 전투를 확인하는 화면이다 |
| 전투 | 5×5 보드의 12줄을 보고, 일부만 놓인 줄도 평가한다. 여러 줄에 쓰인 타일은 겹침으로 보너스를 받는다 | 점수를 계산하는 순서와 화면에 보여 주는 순서는 다를 수 있다 |
| 돈 | 0G로 시작한다. 기본 Blind 보상은 4G이고, Market 리롤은 5G에서 시작해 사용한 줄만 2G씩 오른다 | 화면의 4/8/12 보상 미리보기는 실제 정산과 맞지 않는다. High Stakes ×1.12도 기본 4G를 반올림하면 4G다 |
| 성장 | 점수 족보를 완성하면 성장하고, Boss를 깨면 타일이나 슬롯 해금을 받는다 | Market이 대신 사 주는 것은 금지하지만, 전투를 이겨 받는 보상은 자동 적용된다 |
| 저장 | v2 형식으로 전투·Market·Blind Select 상태와 복원용 기준점을 저장한다 | 새 게임의 첫 저장 전 종료, 두 단계 저장, 정산 후 재진입 위험이 있다 |
| 측정 | 시작·전투·Market 같은 기본 이벤트는 있다 | 재시작과 포기, 복원한 런의 상태, 저장 실패는 제대로 구분하지 못한다 |

상세 불일치는 core 문서의 Known Gaps 절을 본다.

- [GAME_DESIGN](../core/GAME_DESIGN.md)
- [RUN_ECONOMY](../core/RUN_ECONOMY.md)
- [UI_UX](../core/UI_UX.md)
- [SAVE_DATA](../core/SAVE_DATA.md)
- [CONTENT_SYSTEM](../core/CONTENT_SYSTEM.md)
- [SYSTEM_ARCHITECTURE](../core/SYSTEM_ARCHITECTURE.md)

## 재미를 키울 후보

상태는 이렇게 읽는다. `후보`는 아직 게임에 넣지 않은 아이디어고, `선행 수정`은 기존 오류나 잘못된 안내를 먼저 고쳐야 한다는 뜻이다.

| 우선순위 | 후보 | 근거 비교축 | 기대 효과 | 위험 | 검증 지표 | 상태 |
|---|---|---|---|---|---|---|
| P0 | Blind reward preview를 실제 4/4/4(+modifier)와 일치 | Balatro/deckbuilder: 보상 진실이 위험보상 전제 | 선택 신뢰 회복 | 없음; 표시 수정 | Blind Select 표시 = Settlement base | 선행 수정 |
| P0 | 정산·런 종료 보상을 한 번만 지급 | 저장 신뢰 | 골드·Insight 중복 지급 제거 | 저장 형식과 처리 단계 추가 필요 | 강제 종료 후 다시 열어도 1회만 지급 | 선행 수정 |
| P0 | first-save gap / Market exit flush / payload+signature 원자성 | premium mobile peer 불만 축 | 이어하기 신뢰 | storage 경계 변경 | New Run 직후 kill, Market→Title 복원 | 선행 수정 |
| P1 | Game Over에 부족 점수·남은 행동을 보여 주는 카드 + `loss_snapshot` | 플레이어의 실패 이해 | 다음 도전에서 판단하기 쉬움 | 원인을 단정하거나 비난하지 않음 | 이해도 QA, 이벤트 연결 | 후보 |
| P1 | 정산 라벨/연출을 계산 순서(growth→overlap→Jester→tile→Item→Boss)에 맞춤 | Balatro ordered theatrical resolve | 빌드 학습 | 연출 시간 증가 | 라벨 정확도 테스트 | 후보 |
| P1 | Challenge 계승을 실제로 기록하거나 안내 문구를 제거 | 현재 잘못된 안내 | 다음 런 목표를 믿고 세울 수 있음 | 밸런스 영향 | S8 완료 후 Challenge 시작 상태 확인 | 선행 수정 또는 문구 삭제 |
| P2 | Market에서 다음 Blind/Boss의 목표와 제약을 미리 보여 주기 | 덱빌더의 눈에 보이는 선택 | 무엇을 살지 판단하기 쉬움 | 보상 표시를 먼저 바로잡아야 함 | 다음 목표·자원 표시가 실제와 같은지 확인 | 후보 |
| P2 | ‘지금 빌드에 맞는 후보’의 기준을 정한 뒤 Market 조정 | Balatro/STS의 옆길 발견 | 쓸모없는 Market 감소 | 아직 기준과 측정 방법이 없음 | Station별 적합 후보 등장률 | 후보/측정 선행 |
| P2 | 원자적 효과 문구 상한·미사용/과강 효과 정리 | Balatro terse Jokers | 가독성·조합 공간 | 콘텐츠 삭제 반발 | 효과 이해 테스트, usage | 후보 |
| 보류 | 정확한 점수 미리보기를 없애기 | Balatro의 긴장감 | 결과를 기다리는 재미 | 5×5/12줄에서는 불공정하게 느낄 수 있음 | 비교 실험과 이해도 확인 | 기본적으로 가져오지 않음 |
| 보류 | 콘텐츠 수 확대만으로 리플레이 강화 | catalog breadth | 다양성 착시 | 조향/가독성 악화 | 재사용률 | 비권고 |
| 보류 | 영구 계정 전투 파워/시작 골드 | F2P ladder | 단기 진행감 | 런 정체성 훼손 | 장기 밸런스 | 비권고 |

### 다른 게임에서 참고할 점

- **Balatro**: 짧은 효과, 가시적 skip/risk, 순서 연출, 수평 도전. 1.1은 2026-07-17 기준 출시 미확인.
- **STS / Monster Train / Wildfrost / Slice & Dice**: 제한된 선택 + 주기적 두꺼운 빌드 선택. 전투 셸은 전이하지 않음.
- **Poker Squares / Sage Solitaire / Triple Town / Isle of Arrows / Grindstone**: 격자 배치, 공간 회복, 짧은 재도전.
- **비전이**: exact preview 부재, 숨은 핵심 규칙, 카지노 테마 강화, Completionist급 체크리스트 압박.

## 광고와 수익 모델을 넣는다면

### 기본 방향

| 모델 | 판정 | 이유 |
|---|---|---|
| 유료 완성형·광고 없음·게임플레이 결제 없음 | **권고 기본** | 현재 게임 구조와 저장 방식에 가장 잘 맞고, 광고·결제·보상 장부가 아직 없다 |
| S1 체험판 + 1회 전체 해금 | **이후 실험** | Peglin·Wildfrost·Slice & Dice처럼 먼저 맛보고 한 번 결제하는 방식. 구매 복원과 저장 검증이 먼저다 |
| 무료 광고형·배틀패스·에너지·가챠 | **현재 거절** | 운영·경제·정책이 새 제품 수준으로 커진다 |
| 구독 카탈로그 | **유통 옵션** | 출시 구조로 미리 설계하지 않는다 |

### 광고를 넣어도 되는 위치와 안 되는 위치

| 위치 | 판단 |
|---|---|
| Battle 중 / Blind 시작 / Start·Next 탭 직후 | 금지 |
| App load standard interstitial / Exit·Home·S8→Title | 금지 |
| Game Over 부활·진행 보존 | 거절 (무료 재시작이 이미 있고 실패를 배우는 흐름을 흐린다) |
| Settlement 골드 더블 / Battle 자원 보급 | 거절 (경제 상한 붕괴) |
| Completed Blind 후 forced interstitial | 조건부만; cadence safe harbor 없음 |
| S1 Boss cash-out 후 Market 전 opt-in rewarded | **유일한 파일럿 후보** |

### 시험 운영 후보 (아직 미구현)

- 시점: S1 Boss cash-out 연출·보상 공개 완료 후, Market 열기 전.
- 선택: 정상 `Market 진입` 유지. 광고 CTA는 명시적 opt-in.
- 보상: 다음 원가 5G 리롤 1회를 0G로 만드는 non-stack voucher. Gold/Insight/타일/Item/Jester/성장/전투 파워 아님.
- 만료: 해당 Market 종료 시. run당 1회. 거절 시 같은 run 재제안 없음.
- S1 Scout Market 제외 (이미 첫 리롤 할인 존재).
- ad pods 비활성(한 영상 약속). no-fill/offline/미동의 시 제안 숨김.
- 선행 게이트: consent/ATT/age rating/creative filter/report-ad, true terminal analytics, grant ledger 또는 서버 검증, economy baseline.

### 시험할 때 볼 지표

- 핵심 지표: 배정된 사용자 기준 광고 수익, D7/D14 재방문, S1 Boss 도달, S8 도달.
- 보호 지표: 거절 뒤 Market을 계속하는 비율, 충돌 없이 플레이한 비율, 골드·리롤·구매 분포, 진행률, 표본 배정 오류.
- 바로 중단할 조건은 강제 노출, 거절 시 진행 차단, 보상 누락·중복, 소리 문제, 정책 위반이다.

## 다음에 할 일

1. 보상 진실·정산 멱등·save 신뢰 P0 수정 track을 연다.
2. 실패 사실 카드와 analytics terminal 분리를 후보 설계로 남긴다.
3. BM은 premium 기본으로 두고, 광고/IAP 구현은 비즈니스 결정 후에만 연다.
4. build-relevant guarantee 문구는 계측 정의 전까지 쓰지 않는다.

## 조사 자료 위치

- 조사 세션: `.omo/ulw-research/20260717-071150/`
- 광고 정책/UX: `.omo/teams/team-1a03fc22/artifacts/ad-policy-map.md`, `ad-ux-economics.md`
- 모바일 포지셔닝: `.omo/teams/team-1a03fc22/artifacts/mobile-market.md`
