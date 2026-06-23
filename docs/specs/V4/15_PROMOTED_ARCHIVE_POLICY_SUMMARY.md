# 15. Promoted Archive Policy Summary

이 문서는 과거 원문 중 현재 게임 정책이 무너지지 않게 보존해야 하는 원칙만 승격한 요약이다.

과거 원문은 현재 source-of-truth가 아니다. 새 구현 판단은 이 문서와 `docs/current_system/`, `docs/specs/V4/`, 실제 코드/테스트를 우선한다.

## 1. 승격 원칙

| 승격 원칙 | 현재로 승격한 내용 |
| --- | --- |
| restrained tabletop UI | felt/tabletop 계열의 절제된 카드 게임 UI, 정보 위계, 과장된 랜딩/장식 배제 |
| boss modifier taxonomy | 보스 제약은 단순 숫자 penalty만이 아니라 배치, 사용, 순서, 변형, 비활성 제약을 포함한다 |
| constraint visual language | 보스/제약은 전투 중 읽히는 시각 언어와 설명 문구를 함께 가져야 한다 |
| Jester extension taxonomy | Jester는 점수 가산 외에 보드/라인/마켓/자원/조건부 운용 축으로 확장한다 |
| Item/Tool/Gear/Ritual/Fate timing taxonomy | Item/Tool/Gear/Ritual/Fate는 사용 타이밍, 지속성, 저장/복원, 전투 표시 책임을 분리한다 |

## 2. 디자인 원칙

- 운영 도구처럼 조용하고 읽기 쉬운 화면을 우선한다.
- 카드, 타일, 보드, 마켓 후보는 정보 위계를 먼저 세우고 장식은 그 다음에 둔다.
- 초록 felt 배경을 쓰더라도 tooltip, tutorial, 경고, 제약 표시는 배경과 충분히 분리한다.
- 카드 이미지나 일러스트는 UI 텍스트와 경쟁하지 않아야 하며, safe zone을 침범하지 않는다.

## 3. 보스/제약 확장 원칙

- 보스 pool은 숫자 penalty, family variant만으로 닫지 않는다.
- 배치 금지, 특정 줄/칸 비활성, 순서 변경, 조건부 사용 제한, 타일 변형처럼 플레이 양상을 바꾸는 룰을 후보로 둔다.
- 단, 유저 선택 강제, 자동 지급, 특정 슬롯 고정 같은 금지 원칙은 유지한다.
- 새 제약은 저장/복원, preview, 전투 중 표시, 정산 검증, 튜토리얼/QA fixture를 함께 설계한다.

## 4. Jester / Market 확장 원칙

- Jester는 단순 점수 증가만이 아니라 line shape, tile color, hand rank, market reroll, resource pressure, risk/reward를 건드릴 수 있다.
- Market 후보는 현재 lane/reroll 단위로 고정한다. 구매한 후보 빈자리는 같은 마켓에서 자동 보충하지 않는다.
- 희귀도와 offer count를 바꾸는 정책은 현재 레벨링 문서와 충돌하지 않는지 먼저 확인한다.

## 5. Item / Tool / Gear / Ritual / Fate 원칙

- 사용형 item은 실제 전투 중 보유, 사용 가능 상태, target, 결과를 플레이어가 읽을 수 있어야 한다.
- 지속형 gear/passive는 저장/복원과 Market/전투 표시가 함께 검증돼야 한다.
- Ritual/Fate 계열은 `가장 강한 줄` 같은 불투명 자동 판정보다 유저가 보드 선을 직접 선택하고 확인하는 흐름을 우선한다.
- 다음 확정 임시 보정으로 축소하면 안 되는 성장류는 별도 성장 지원류로 분리한다.

## 6. Archive 사용 규칙

- 위 원문은 세부 후보를 다시 검토할 때만 읽는다.
- 새 source-of-truth를 만들 때는 원문 문장을 복사하지 말고 현재 runtime, 저장, UI, QA 기준에 맞게 다시 요약한다.
- 원문과 현재 문서가 충돌하면 현재 문서와 실제 코드/테스트를 우선한다.
