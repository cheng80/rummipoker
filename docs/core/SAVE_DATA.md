# 저장 데이터

저장은 ‘지금 어느 화면에 있는지’와 ‘다음에 이어갈 게임 상태’를 함께 기록한다. 연출 중인 화면은 저장하지 않고, 다시 열 때 안정된 상태에서 시작한다.

## 저장 파일의 기본 틀

[active_run_save_service.dart](../../lib/services/active_run_save_service.dart)의 `ActiveRunSaveService.schemaVersion = 2`가 현재 저장 형식의 버전이다. 저장 파일 맨 위에는 다음 항목이 들어간다.

| 항목 | 자료형과 의미 |
|---|---|
| `schemaVersion` | integer, 반드시 2 |
| `savedAt` | UTC ISO-8601 string |
| `activeScene` | `battle`, `shop`, `blindSelect` 중 하나 |
| `difficulty` | New Run difficulty name |
| `runModifier` | run modifier ID |
| `session` | current `SavedSessionData` |
| `runProgress` | current `SavedRunProgressData` |
| `stageStartSession` | Station-start session snapshot |
| `stageStartRunProgress` | Station-start run snapshot |
| `stakeStartSession` | current Blind-start session snapshot |
| `stakeStartRunProgress` | current Blind-start run snapshot |

`stakeStart*`가 없는 v2 저장 파일은 불러올 때 `stageStart*`를 대신 사용한다. 같은 v2 안에서 빠진 선택 항목을 보완하는 처리이며, 예전 버전을 새 버전으로 바꾸는 migration은 아니다. 항목 이름과 읽는 방법은 [active_run_save_models.dart](../../lib/services/active_run_save_models.dart)가 정한다.

## 화면별 저장 시점

| 저장 상태 | 언제 저장하나 | 앱을 다시 열면 |
|---|---|---|
| `battle` | Battle action 뒤 stable state, clear/cash-out 전후의 명시적 boundary, retry | `/game`으로 restore; 이미 target을 넘긴 battle이면 cash-out 재개 가능 |
| `shop` | cash-out 뒤 Market 진입, 구매·판매·사용·리롤, options/lifecycle flush | `/game`으로 restore한 뒤 catalog가 준비되면 Market fullscreen dialog 재개 |
| `blindSelect` | Market 종료 후 다음 Blind 선택 직전 | `/blind-select`로 restore하고 current Station/tier availability 표시 |

enum은 [active_run_save_models.dart](../../lib/services/active_run_save_models.dart)의 `ActiveRunScene { battle, shop, blindSelect }`다. UI의 `Market` 명칭은 save string `shop`의 presentation alias이며 저장 값 자체를 바꾸지 않는다.

## 게임을 이어가기 위해 저장하는 상태

`session`과 각 session snapshot은 다음 key를 저장한다.

```text
runSeed, rulesetId, deckCopiesPerTile, initialDeckSizeForBlind,
maxHandSize, runRandomState, blind, deckPile, boardCells, hand, eliminated,
boardMoveHistory, nextBoardMoveSlideBonusQueued,
slideBonusTriggerCountThisStation, confirmModifiers,
confirmCountThisStation, firstConfirmScoreThisStation,
confirmedRanksThisStation, expiryGuardUsedThisStation
```

`blind` 안에는 target/score, 보드·손패 버림과 보드 이동의 remaining/max, optional Boss modifier가 들어간다. 타일 JSON은 color, number, physical ID와 optional enhancement/seal/edition persistence value를 보존한다.

`runProgress`와 각 run-progress snapshot은 다음 key를 저장한다.

```text
stageIndex, currentStationBlindTierIndex, runCompletionRewardClaimed, gold,
rerollCost, tileRerollCost, itemRerollCost, quickSlotRerollCost,
passiveRerollCost, toolRerollCost, gearRerollCost,
ownedJesterIds, shopOffers, statefulValuesBySlot, playedHandCounts,
handGrowthStates, stationRankFinalScores, overkillGrowthClaimedStationKeys,
addedDeckTiles, tileOffers, pendingBossTileReward,
firstShopRerollDiscountConsumed, firstShopRerollDiscountConsumedLanes,
unlockedJesterSlots, unlockedQuickSlotCapacity,
unlockedPassiveRelicCapacity, pendingSlotUnlockPresentations,
itemInventory, marketModifiers, seenMarketJesterIds, seenMarketItemIds,
boughtJesterIds, boughtItemIds, seenBossModifierIds, clearedStationKeys
```

slot capacity key 세 개는 encoder가 non-null일 때 쓴다. decoder는 빠진 optional v2 field를 current model default로 복원하지만 필수 field type/shape가 잘못되면 전체 load를 invalid/null로 처리한다. encode/restore mapping은 [active_run_save_codec.dart](../../lib/services/active_run_save_codec.dart)가 소유한다.

선택된 타일, overlay, tutorial, dialog, settlement animation step/tick, pause veil 같은 presentation state는 저장하지 않는다. restore/restart는 [game_session_presentation_state.dart](../../lib/providers/features/rummi_poker_grid/game_session_presentation_state.dart)의 initial state로 시작한다.

## 다시 시작할 때 돌아갈 기준점과 북마크

- `stageStartSnapshot`: Station 시작 기준이다. 같은 Station의 Scout/Clash/Boss 사이에는 보존되고 Boss 뒤 새 Station에서 교체된다. `restartCurrentStage`는 current session/run progress를 이 snapshot으로 되돌린다.
- `stakeStartSnapshot`: 현재 Blind 시작 기준이다. Blind를 선택할 때마다 갱신된다. `restartCurrentStake`는 이 snapshot으로 되돌리되 Station snapshot은 유지한다.
- bookmark: 3개 slot이 각각 current runtime 전체와 signature를 저장한다. 저장 시 같은 slot을 덮어쓰며, 불러오기는 먼저 bookmark를 verify/restore한 뒤 active-run payload를 그 runtime으로 덮어쓴다.
- active run과 bookmark는 같은 schema/codec/HMAC을 사용하지만 서로 다른 StorageHelper key를 사용한다.

snapshot 복사와 restart command는 [game_session_notifier_save_commands.dart](../../lib/providers/features/rummi_poker_grid/game_session_notifier_save_commands.dart), bookmark UI flow는 [game_bookmark_slot_dialog.dart](../../lib/views/game/widgets/game_bookmark_slot_dialog.dart)가 소유한다.

## 저장 위치와 위변조 확인

| 저장 항목 | 현재 동작 |
|---|---|
| payload store | `StorageHelper`가 감싼 SharedPreferences string |
| active keys | `active_run_payload_v1`, `active_run_signature_v1` |
| bookmark keys | payload/signature prefix + slot index 0..2 |
| device key | 처음 저장할 때 32 random bytes를 base64url encode; `DeviceKeyStore` 기본 구현도 StorageHelper의 `save_device_key_v1` 사용 |
| signature | device key를 secret으로 한 HMAC-SHA256 over exact UTF-8 JSON payload |
| verification | payload와 signature, device key, HMAC, JSON parse, exact schema version을 모두 통과해야 available/load 가능 |

HMAC은 payload integrity check이며 암호화가 아니다. payload와 default device key가 같은 local preference boundary에 있으므로 서버 인증이나 공격자가 storage 전체를 통제하는 상황의 보안을 보증하지 않는다. write는 payload 뒤 signature 순서의 두 작업이며 transactional rollback은 없다. 중간 상태는 다음 inspect에서 none/invalid recovery path로 간다. device key abstraction은 [device_key_store.dart](../../lib/services/device_key_store.dart), 기본 store는 [device_key_store_default.dart](../../lib/services/device_key_store_default.dart), primitive store는 [storage_helper.dart](../../lib/utils/storage_helper.dart)가 소유한다.

## Encode, Persist, Restore, and Delete

```text
runtime
→ build current + stage/stake DTO
→ JSON encode with schemaVersion 2 and savedAt
→ ensure device key
→ HMAC-SHA256
→ payload write
→ signature write
```

```text
inspect/load
→ read payload + signature
→ read device key
→ constant string equality against recomputed HMAC
→ JSON decode
→ exact version check
→ Jester catalog load and ID rebind
→ session/runProgress/stage/stake restore
→ scene-specific route
```

- continue: Title이 `available`일 때만 load하며 restored scene에 맞는 route로 이동한다.
- restart: provider가 in-memory stage/stake snapshot을 copy해 current runtime을 교체하고 presentation을 reset한 뒤 save한다.
- bookmark restore: verified slot을 active run으로 다시 저장한 뒤 route한다.
- delete: `clearActiveRun`은 active payload와 signature만 지운다. bookmark, device key, settings, unlock/collection state는 지우지 않는다.
- terminal: run complete, game-over new run/exit 경로는 run result를 기록한 뒤 active payload/signature를 지운다.

## Corruption and Version Policy

- payload 또는 signature가 모두 갖춰지지 않으면 load는 null이다. Title은 raw key가 남아 있으면 손상 dialog를 열 수 있다.
- device key가 없거나 HMAC이 다르면 `invalid`/null이다.
- malformed JSON, 잘못된 required field type, 알 수 없는 scene enum, 현재 catalog에 없는 owned Jester ID는 restore를 실패시킨다.
- `schemaVersion != 2`는 즉시 reject한다. current service에는 cross-version migration 함수, version chain, 자동 rewrite가 없다.
- invalid save는 자동 삭제하지 않는다. Title은 취소 또는 active save 삭제를 제공한다.
- bookmark invalid slot은 빈 slot처럼 보이고, index가 0..2 밖이면 RangeError다.

이 정책은 손상 상태를 gameplay에 부분 적용하지 않는다. 일부 optional v2 field fallback은 model default 또는 stage snapshot을 사용하지만 다른 schema version을 받아들이지는 않는다.

## Catalog ID Coupling

- owned Jester와 Jester offer는 ID만 저장하며 restore 시 current Jester catalog definition을 찾아 결합한다. ID가 없으면 restore 전체가 실패한다.
- Item inventory는 ID/count/placement/active와 placement lists를 저장한다. runtime/UI는 current Item catalog를 다시 결합하므로 ID 제거·의미 변경은 보유 Item 복원에 영향을 준다.
- tile modifier는 enum persistence value, Boss는 Blind JSON의 modifier ID/fields, hand growth는 `RummiHandRank.name`, ruleset은 persistence ID에 결합된다.
- content ID/schema를 바꿀 때 generated catalog freshness만으로는 충분하지 않으며 active save roundtrip과 restore test가 함께 필요하다.

콘텐츠 결합 규칙은 [CONTENT_SYSTEM.md](CONTENT_SYSTEM.md)가 소유한다.

## Source and Test Anchors

- schema/model/codec: [active_run_save_models.dart](../../lib/services/active_run_save_models.dart), [active_run_save_codec.dart](../../lib/services/active_run_save_codec.dart)
- persist/integrity/bookmark: [active_run_save_service.dart](../../lib/services/active_run_save_service.dart), [active_run_save_service_test.dart](../../test/services/active_run_save_service_test.dart)
- continue/delete: [title_notifier.dart](../../lib/providers/features/rummi_poker_grid/title_notifier.dart), [title_view_test.dart](../../test/views/title_view_test.dart)
- scene/restart/presentation reset: [game_session_notifier_save_commands.dart](../../lib/providers/features/rummi_poker_grid/game_session_notifier_save_commands.dart), [game_session_notifier_test.dart](../../test/providers/game_session_notifier_test.dart)
- StorageHelper: [storage_helper.dart](../../lib/utils/storage_helper.dart), [storage_helper_test.dart](../../test/utils/storage_helper_test.dart)



## Known Durability Gaps

현재 save/resume 계약은 아래 위험을 가진다. 플레이어-facing “이어하기/북마크 보장”으로 과장하지 않는다.

- New Run은 기존 active run을 먼저 지우고, 새 run의 첫 자동 저장은 GameView에서 Jester catalog load 성공 뒤에야 이뤄진다. 그 사이 강제 종료는 양쪽 run을 잃을 수 있다.
- payload와 signature는 순차 두 쓰기이며 원자적 rollback이 없다. 중간 상태는 invalid/none recovery로 간다.
- Battle pause save는 await하지 않는 best-effort이고, Market pause는 queue만 하며 detach/Main Menu/options exit가 flush를 보장하지 않는다.
- cash-out은 보상을 적용한 뒤 `battle` scene을 저장할 수 있어 복원 시 settlement를 재실행할 수 있다. settlement transaction ID가 없다.
- terminal Insight/collection 기록과 active-run 삭제 사이에 claim marker가 없거나 늦게 쓰여 재지급 위험이 있다.
- restored Market과 already-cleared Battle은 Item catalog load 성공에 의존하며 실패 시 조용히 멈출 수 있다.
- 정확한 schema v2만 허용하며 cross-version migration은 없다.

## Source and Update Trigger

schema version/key set, exact-version policy, scene enum, durable field, stage/stake/bookmark semantics, device key/HMAC/storage boundary, corruption recovery, catalog ID coupling 또는 delete 범위가 바뀌면 이 문서와 save roundtrip·integrity·restart tests를 같은 변경에서 갱신한다.
