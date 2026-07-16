# Reverse Design Synthesis

> 역할: 2026-07-17 역기획·유사 장르 비교·광고 BM 조사 결과의 실행 판단 요약. runtime 계약은 [docs/core](../core/GAME_DESIGN.md)가 소유한다. 런타임 미반영 항목은 후보·보류로만 표시한다.

## 결론

1. 현재 제품의 우선 리스크는 콘텐츠 부족이 아니라 **보상 진실성·저장 신뢰·정산 멱등성**이다.
2. Balatro류에서 가져올 것은 **짧은 효과 문구, 가시적 위험/보상, 순서 있는 연출, 수평 목표**이며, exact score 숨김·카지노 테마·콘텐츠 수 확대는 가져오지 않는다.
3. 출시 BM 기본안은 **premium / no-ad / no gameplay IAP**다. 광고가 비즈니스 필수가 되기 전에는 구현하지 않는다.
4. 광고를 시험할 경우 유일한 조건부 후보는 **S1 Boss cash-out 완료 후 · Market 진입 전 · 선택형 1회 · 다음 원가 5G 리롤 0G voucher**다.

## 현재 게임 역기획 요약

| 영역 | 현재 사실 | 문서/표시 주의 |
|---|---|---|
| 루프 | Station = Scout→Clash→Boss, 각 Blind 후 Settlement·Market, S8 완료/Endless | Blind Select는 순서 확인에 가깝고 경제 분기가 아니다 |
| 전투 | 5×5, 12줄, partial hand, overlap, contributor-only 제거 | 점수 계산 순서와 연출 순서가 다를 수 있다 |
| 경제 | 시작 0G, 기본 Blind 4G, 가격 ×11/5, lane 리롤 5→+2 | UI rewardPreview 4/8/12는 거짓; High Stakes ×1.12는 기본 4G에만 곱해 효과 0 |
| 성장 | 점수 족보 레벨업, Boss 타일, S2/S4/S6 슬롯 해금 | Market 자동 지급은 금지, 전투 결과 보상은 허용 |
| 저장 | schema v2, battle/shop/blindSelect, HMAC | first-save gap, 비원자 write, cash-out/terminal 재지급 위험 |
| 측정 | funnel event 존재 | retry/abandon, resume context, save health 미흡 |

상세 불일치는 core 문서의 Known Gaps 절을 본다.

- [GAME_DESIGN](../core/GAME_DESIGN.md)
- [RUN_ECONOMY](../core/RUN_ECONOMY.md)
- [UI_UX](../core/UI_UX.md)
- [SAVE_DATA](../core/SAVE_DATA.md)
- [CONTENT_SYSTEM](../core/CONTENT_SYSTEM.md)
- [SYSTEM_ARCHITECTURE](../core/SYSTEM_ARCHITECTURE.md)

## 재미 강화 후보

상태 표기: `후보` = 런타임 미반영, `선행 수정` = 기존 버그/거짓 정보 수정이 먼저.

| 우선순위 | 후보 | 근거 비교축 | 기대 효과 | 위험 | 검증 지표 | 상태 |
|---|---|---|---|---|---|---|
| P0 | Blind reward preview를 실제 4/4/4(+modifier)와 일치 | Balatro/deckbuilder: 보상 진실이 위험보상 전제 | 선택 신뢰 회복 | 없음; 표시 수정 | Blind Select 표시 = Settlement base | 선행 수정 |
| P0 | Settlement/terminal reward 멱등성 | save trust | 골드·Insight 중복 지급 제거 | save schema/phase 추가 필요 | kill/restore 후 1회만 지급 | 선행 수정 |
| P0 | first-save gap / Market exit flush / payload+signature 원자성 | premium mobile peer 불만 축 | 이어하기 신뢰 | storage 경계 변경 | New Run 직후 kill, Market→Title 복원 | 선행 수정 |
| P1 | Game Over에 부족 점수·남은 행동 사실 카드 + `loss_snapshot` | player reception: 실패 attribution | 재도전 판단 비용 감소 | 인과 비난 문구 금지; retention 미검증 | 이해도 QA, event join | 후보 |
| P1 | 정산 라벨/연출을 계산 순서(growth→overlap→Jester→tile→Item→Boss)에 맞춤 | Balatro ordered theatrical resolve | 빌드 학습 | 연출 시간 증가 | 라벨 정확도 테스트 | 후보 |
| P1 | Challenge carryover 실제 기록 또는 UI 약속 제거 | 현재 거짓 안내 | meta 목표 신뢰 | 밸런스 영향 | S8 complete→Challenge 시작 snapshot | 선행 수정 또는 문구 삭제 |
| P2 | Market 다음 Blind/Boss 요약 미리보기 | deckbuilder visible tradeoff | 구매 판단 맥락 | rewardPreview 수정 선행; 정보 과다 | Market 내 다음 Blind 목표/자원 정확도 | 후보 |
| P2 | build-relevant offer 정의·계측 후 steering 개선 | Balatro/STS lateral discovery | dead Market 감소 | 현재 relevant 정의/지표 없음 | Station별 relevant hit rate | 후보/계측 선행 |
| P2 | 원자적 효과 문구 상한·미사용/과강 효과 정리 | Balatro terse Jokers | 가독성·조합 공간 | 콘텐츠 삭제 반발 | 효과 이해 테스트, usage | 후보 |
| 보류 | exact score 미리보기 제거 | Balatro suspense | 긴장감 | 5×5/12줄 밀도에서 불공정 인식 | A/B 이해·이탈 | 전이 금지 기본 |
| 보류 | 콘텐츠 수 확대만으로 리플레이 강화 | catalog breadth | 다양성 착시 | 조향/가독성 악화 | 재사용률 | 비권고 |
| 보류 | 영구 계정 전투 파워/시작 골드 | F2P ladder | 단기 진행감 | 런 정체성 훼손 | 장기 밸런스 | 비권고 |

### 전이 가능한 비교 교훈

- **Balatro**: 짧은 효과, 가시적 skip/risk, 순서 연출, 수평 도전. 1.1은 2026-07-17 기준 출시 미확인.
- **STS / Monster Train / Wildfrost / Slice & Dice**: 제한된 선택 + 주기적 두꺼운 빌드 선택. 전투 셸은 전이하지 않음.
- **Poker Squares / Sage Solitaire / Triple Town / Isle of Arrows / Grindstone**: 격자 배치, 공간 회복, 짧은 재도전.
- **비전이**: exact preview 부재, 숨은 핵심 규칙, 카지노 테마 강화, Completionist급 체크리스트 압박.

## 광고·BM 적용 방안

### 기본 권고

| 모델 | 판정 | 이유 |
|---|---|---|
| Premium / no ads / no gameplay IAP | **권고 기본** | 현재 코드·경제·save가 완결형 solo run에 맞음. ad/IAP/consent/ledger 없음 |
| S1 demo + 1회 전체 해금 | **이후 실험** | Peglin/Wildfrost/Slice & Dice형. restore/entitlement/save 게이트 후 |
| Ad-funded F2P / 배틀패스 / 에너지 / 가챠 | **현재 거절** | 운영·경제·정책 프로그램이 새 제품이 됨 |
| 구독 카탈로그 | **유통 옵션** | 런치 아키텍처로 설계하지 않음 |

### 광고 배치 맵

| 위치 | 판정 |
|---|---|
| Battle 중 / Blind 시작 / Start·Next 탭 직후 | 금지 |
| App load standard interstitial / Exit·Home·S8→Title | 금지 |
| Game Over 부활·진행 보존 | 거절 (무료 retry 존재, 실패 학습 오염) |
| Settlement 골드 더블 / Battle 자원 보급 | 거절 (경제 상한 붕괴) |
| Completed Blind 후 forced interstitial | 조건부만; cadence safe harbor 없음 |
| S1 Boss cash-out 후 Market 전 opt-in rewarded | **유일한 파일럿 후보** |

### P1 파일럿 계약 (후보, 미구현)

- 시점: S1 Boss cash-out 연출·보상 공개 완료 후, Market 열기 전.
- 선택: 정상 `Market 진입` 유지. 광고 CTA는 명시적 opt-in.
- 보상: 다음 원가 5G 리롤 1회를 0G로 만드는 non-stack voucher. Gold/Insight/타일/Item/Jester/성장/전투 파워 아님.
- 만료: 해당 Market 종료 시. run당 1회. 거절 시 같은 run 재제안 없음.
- S1 Scout Market 제외 (이미 첫 리롤 할인 존재).
- ad pods 비활성(한 영상 약속). no-fill/offline/미동의 시 제안 숨김.
- 선행 게이트: consent/ATT/age rating/creative filter/report-ad, true terminal analytics, grant ledger 또는 서버 검증, economy baseline.

### 실험 지표 (파일럿 시에만)

- Primary: assigned user 기준 ad revenue, D7/D14 return, S1 Boss reach, S8 reach.
- Guardrail: decline→Market 지속, crash-free, Gold/reroll/purchase 분포, 진행률, sample-ratio mismatch.
- Kill: 강제 노출, 거절 차단, 보상 누락/중복, 오디오 실패, 정책 위반.

## 다음 행동

1. 보상 진실·정산 멱등·save 신뢰 P0 수정 track을 연다.
2. 실패 사실 카드와 analytics terminal 분리를 후보 설계로 남긴다.
3. BM은 premium 기본으로 두고, 광고/IAP 구현은 비즈니스 결정 후에만 연다.
4. build-relevant guarantee 문구는 계측 정의 전까지 쓰지 않는다.

## 증거 위치

- 조사 세션: `.omo/ulw-research/20260717-071150/`
- 광고 정책/UX: `.omo/teams/team-1a03fc22/artifacts/ad-policy-map.md`, `ad-ux-economics.md`
- 모바일 포지셔닝: `.omo/teams/team-1a03fc22/artifacts/mobile-market.md`
