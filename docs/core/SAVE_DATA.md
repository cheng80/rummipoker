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
| `blindSelectBossModifier` | `blindSelect`에서 표시·선택할 optional Boss modifier JSON |
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

`blind` 안에는 target/score, 보드·손패 버림과 보드 이동의 remaining/max, optional Boss modifier가 들어간다. `blindSelectBossModifier`는 화면에 확정 표시한 현재 Station Boss의 전체 JSON을 별도로 보존한다. 필드가 없는 기존 v2 save는 run seed로 preview를 다시 만들고, 실제 Blind를 선택할 때 current `blind.bossModifier`를 선택 결과로 설정한다. 타일 JSON은 color, number, physical ID와 optional enhancement/seal/edition persistence value를 보존한다.

`runProgress`와 각 run-progress snapshot은 다음 key를 저장한다.

```text
stageIndex, currentStationBlindTierIndex, runCompletionRewardClaimed,
runClaimId, settlementReceiptKey, settlementReceipt, gold,
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
| active key | `{payload, signature}` JSON envelope을 담는 `active_run_record_v1` |
| legacy active keys | 기존 v2 호환용 `active_run_payload_v1`, `active_run_signature_v1`; 새 envelope이 없을 때만 읽고 다음 저장에서 제거 |
| bookmark keys | payload/signature prefix + slot index 0..2 |
| device key | 처음 저장할 때 32 random bytes를 base64url encode; `DeviceKeyStore` 기본 구현도 StorageHelper의 `save_device_key_v1` 사용 |
| signature | device key를 secret으로 한 HMAC-SHA256 over exact UTF-8 JSON payload |
| verification | record 안의 payload와 signature, device key, HMAC, JSON parse, exact schema version을 모두 통과해야 available/load 가능 |

HMAC은 payload 무결성을 확인할 뿐 암호화하지 않는다. payload와 default device key가 같은 local preference 경계에 있으므로 storage 전체를 통제하는 공격자나 서버 인증에 대한 보안은 보장하지 않는다. active run은 payload와 signature를 한 envelope에 담아 SharedPreferences에 한 번만 써서 두 키 사이의 종료 구간을 없앤다. 저장 API가 `false`를 반환하면 실패로 처리하고 기존 envelope은 먼저 지우지 않는다. bookmark는 기존 두 키 형식을 유지한다. device key abstraction은 [device_key_store.dart](../../lib/services/device_key_store.dart), 기본 store는 [device_key_store_default.dart](../../lib/services/device_key_store_default.dart), primitive store는 [storage_helper.dart](../../lib/utils/storage_helper.dart)가 소유한다.

## Encode, Persist, Restore, and Delete

```text
runtime
→ build current + stage/stake DTO
→ JSON encode with schemaVersion 2 and savedAt
→ ensure device key
→ HMAC-SHA256
→ {payload, signature} active envelope 단일 write
→ legacy active 두 키 제거
```

```text
inspect/load
→ read active record
→ record가 없을 때만 legacy payload + signature fallback
→ read device key
→ constant string equality against recomputed HMAC
→ JSON decode
→ exact version check
→ Jester catalog load and ID rebind
→ session/runProgress/stage/stake restore
→ runClaimId가 빠졌거나 snapshot끼리 다르면 하나로 정규화해 즉시 다시 저장
→ scene-specific route
```

- new run: `blindSelect` runtime을 먼저 저장하고, 성공한 같은 runtime을 route extra로 넘긴다. 저장 실패 시 기존 active run을 유지하고 New Run 화면에 남는다.
- continue: Title이 `available`일 때만 load하며 restored scene에 맞는 route로 이동한다.
- restart: provider가 in-memory stage/stake snapshot을 copy해 current runtime을 교체하고 presentation을 reset한 뒤 save한다.
- bookmark restore: verified slot을 active run으로 다시 저장한 뒤 route한다.
- delete: `clearActiveRun`은 active envelope과 legacy active 두 키를 지운다. bookmark, device key, settings, unlock/collection state는 지우지 않는다.
- terminal: run complete, game-over new run/exit 경로는 run result를 기록한 뒤 active envelope과 legacy active 두 키를 지운다.

## Corruption and Version Policy

- active envelope이 있으면 legacy key를 보지 않는다. envelope JSON이 깨졌거나 payload/signature가 빠지면 `invalid`/null이다.
- active envelope이 없을 때만 legacy payload/signature를 읽는다. 둘 중 하나만 남으면 inspect는 `none`, load는 null이며 raw key는 `hasStoredActiveRun`에서 감지해 Title 손상 복구를 제공할 수 있다.
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

현재 save/resume 계약의 남은 위험은 아래와 같다. 플레이어-facing “이어하기/북마크 보장”으로 과장하지 않는다.

- New Run은 initial `blindSelect` runtime을 저장한 뒤 이동한다. 기존 active run을 먼저 지우지 않고 새 envelope 한 번 쓰기로 교체하므로, 새 쓰기가 실패하면 이전 envelope을 유지한다.
- Battle pause save는 await하지 않는 best-effort다. Market의 state-changing action은 queue에 넣고 다음 Blind와 Title 이탈 전에 flush하지만, OS가 프로세스를 즉시 종료하는 상황까지 보장하지 않는다.
- cash-out receipt와 run claim ledger는 중복 지급을 막지만, 저장 장치 자체의 지속성은 SharedPreferences 성공 결과에 의존한다.
- restored Market과 already-cleared Battle은 Item catalog load 성공에 의존하며 실패 시 조용히 멈출 수 있다.
- 정확한 schema v2만 허용하며 cross-version migration은 없다.
- HMAC key와 payload가 같은 local preference 경계에 있어 서버 인증이나 storage 전체 탈취에 대한 보안 수단은 아니다.

## Source and Update Trigger

schema version/key set, exact-version policy, scene enum, durable field, stage/stake/bookmark semantics, device key/HMAC/storage boundary, corruption recovery, catalog ID coupling 또는 delete 범위가 바뀌면 이 문서와 save roundtrip·integrity·restart tests를 같은 변경에서 갱신한다.
