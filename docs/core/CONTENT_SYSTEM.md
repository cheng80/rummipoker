# Content System

## Authority와 Four Families

정확한 Jester·Item 행 목록은 [CONTENT_CATALOG.md](../generated/CONTENT_CATALOG.md), Boss 금지칸 mask는 [BOSS_PATTERNS.md](../generated/BOSS_PATTERNS.md)가 소유한다. 이 문서는 목록을 복제하지 않고 콘텐츠가 runtime에 도달하는 계약만 소유한다.

| Family | 정의 권위 | Run ownership·placement | 발동 권위 | Pool·offer 권위 |
|---|---|---|---|---|
| Jester | [jesters_common_phase5.json](../../data/common/jesters_common_phase5.json), [jester_card.dart](../../lib/logic/rummi_poker_grid/jester_card.dart) | `RummiRunProgress.ownedJesters`; 순서가 있는 Jester slot, 기본 4·최대 5 | [jester_effect_runtime.dart](../../lib/logic/rummi_poker_grid/jester_effect_runtime.dart), [rummi_poker_grid_session.dart](../../lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart), round-end/state 갱신은 [jester_run_progress.dart](../../lib/logic/rummi_poker_grid/jester_run_progress.dart) | `shopCatalog`가 runtime 지원 항목만 허용하고 Station band·희귀도·성장축 가중치로 후보 생성 |
| Item | [items_common_v1.json](../../data/common/items_common_v1.json), [item_definition.dart](../../lib/logic/rummi_poker_grid/item_definition.dart) | `RunInventoryState`; Quick, Passive, Tool inventory, Gear placement와 Item별 stack | `effect.timing + effect.op`를 [item_effect_runtime.dart](../../lib/logic/rummi_poker_grid/item_effect_runtime.dart)와 handlers가 dispatch | placement별 후보, rarity/tag/Station 가중치, 소비·고정·리롤 offset을 Market facade가 계산 |
| Tile modifier | [tile.dart](../../lib/logic/rummi_poker_grid/models/tile.dart)의 enhancement·seal·edition enum과 persistence value | 각 물리 `Tile`에 최대 enhancement 1, seal 1, edition 1; 덱·손패·보드 이동과 함께 유지 | [rummi_poker_grid_session.dart](../../lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart)의 line 정산과 관련 Item handler | Market 타일 후보와 Boss/Item 보상이 타일을 생성·변형; ID 대신 enum persistence value가 정체성 |
| Boss | [boss_modifier.dart](../../lib/logic/rummi_poker_grid/boss_modifier.dart)의 known modifier 상수 | 현재 Blind의 `RummiBlindState.bossModifier`; Boss tier에만 하나 배치 | 배치 금지 precondition과 확정 마지막 점수 제약을 session이 적용 | [blind_selection_spec.dart](../../lib/services/blind_selection_spec.dart)의 난이도별 Station pool에서 seed로 결정 |

## ID와 Schema Stability

- Jester ID는 catalog lookup, owned slot, Market offer, 수집 상태, active-run restore의 join key다. active save는 ID만 저장하고 restore 시 현재 catalog에서 다시 찾으므로 ID 제거·변경은 저장 복원을 깨뜨린다.
- Item ID는 catalog, translation, inventory, offer, 효과 event, save의 join key다. parser의 canonicalization은 입력 호환 경계일 뿐 새 저장과 runtime ownership은 canonical ID를 사용한다.
- Item JSON은 `schemaVersion`, `catalogId`, `rarityWeights`, `items`를 가진다. 현재 parser는 필드를 읽되 특정 version을 거부하지 않으므로 schema 검증을 강화할 때 loader test와 save compatibility를 함께 바꿔야 한다.
- Jester JSON은 현재 최상위 배열이며 별도 schema version wrapper가 없다. wrapper를 추가하려면 loader와 generator를 함께 변경해야 한다.
- Tile modifier는 enum의 `persistenceValue`가 저장 키다. 이름 변경보다 persistence value 안정성이 우선이며 알 수 없는 값은 modifier 없음으로 복원된다.
- Boss save는 modifier ID와 rule fields를 직렬화하고 restore는 known ID를 우선 해석한다. ID, category 또는 rule 의미 변경은 Blind save와 score 재현성에 영향을 준다.
- 같은 family 안에서 ID는 고유해야 한다. 정확한 catalog 수량과 중복 검사는 생성 문서의 self-check와 [generate_docs_test.dart](../../test/tools/generate_docs_test.dart)가 담당한다.

## Ownership과 Lifecycle

| 단계 | Jester | Item | Tile modifier | Boss |
|---|---|---|---|---|
| Load | asset JSON → `RummiJesterCatalog` | asset JSON → `ItemCatalog` | enum은 code load | known constants는 code load |
| Offer | 지원 subset에서 Jester lane 생성 | placement별 Item lane 생성 | 타일 offer 생성 | Blind Select에서 Boss tier modifier 결정 |
| Acquire | 골드 차감 후 slot에 append | 골드 차감 후 inventory/placement에 추가 | 타일 구매·보상·Item 변형으로 물리 타일에 부착 | 구매 대상 아님; 선택한 Boss Blind가 소유 |
| Battle | slot 순서와 상태 snapshot으로 점수 계산 | 수동 사용 또는 timing hook; consume 규칙 적용 | 타일과 함께 이동하고 contributor 정산 때 적용 | 금지칸은 행동 precondition, 감점은 line 정산 마지막 |
| Settlement/Market | state decay와 경제 효과, 판매·재배치 | settlement/enter-market/boss-clear hook, 사용·판매 | 골드·성장·파괴 결과 반영 | Boss clear 기록·보상 후 다음 Blind에서 교체 |
| Save/restore | ID·slot state 저장, catalog로 재결합 | ID/count/placement/active 저장, catalog로 정의 결합 | 각 Tile JSON에 persistence value 저장 | Blind JSON에 modifier 저장 |

보유 인스턴스와 정의를 결합하는 read model은 [owned_content_instance.dart](../../lib/logic/rummi_poker_grid/owned_content_instance.dart), save 결합은 [active_run_save_codec.dart](../../lib/services/active_run_save_codec.dart)가 소유한다.

## Trigger, Stacking, Order

확정 line 하나의 현재 계산 순서는 다음과 같다.

1. 족보 성장 상태를 기본 점수에 반영한다.
2. overlap 배율을 적용한다.
3. Jester를 장착 slot index 0부터 끝까지 평가하고 각 score delta를 더한다.
4. contributor 타일을 순서대로 돌며 seal, enhancement, edition을 적용한다.
5. 등록된 Item confirm modifier를 저장된 순서로 적용하고 성공한 one-shot을 소비한다.
6. Boss 점수 제약을 마지막에 적용한다.

이 순서는 [GAME_RULES.md](GAME_RULES.md)의 Confirm Transaction과 동일해야 한다. Family별 stacking 계약은 다음과 같다.

- Jester: slot마다 독립 조건·상태를 읽는다. 동일 ID 중복 가능 여부는 구매·slot 상태가 결정하며, 상태형 값도 slot index로 저장한다.
- Item: `stackable=false`면 같은 ID를 다시 얻을 수 없고, `stackable=true`면 `maxStack`까지만 count를 올린다. 자동 hook은 owned ID 순서로 한 번씩 평가하며 `consume=true`인 성공 효과는 한 count를 제거한다. Quick Item은 명시적 사용 경로가 우선이며 자동 hook에서 제외되는 timing이 있다.
- Tile modifier: 한 타일 안에서는 seal → enhancement → edition 순서다. `redSeal`은 enhancement를 한 번 더 발동시키며, 여러 contributor 타일은 line의 scoring tile 순서대로 누적된다.
- Boss: 한 Blind에 modifier 하나다. `boardCellBlock`은 점수 배율과 stack하지 않고 배치·이동을 거부하며, 나머지 category는 조건이 맞는 line마다 한 번 적용된다.

## Pool과 Offer

- Jester catalog 전체가 곧 Market pool은 아니다. `isSupportedInCurrentRunMeta`를 통과한 카드만 `shopCatalog`에 들어간다.
- Item 정의의 `timing:op`가 runtime handler에 연결되는지는 [item_effect_catalog_support.dart](../../lib/logic/rummi_poker_grid/item_effect_catalog_support.dart)가 판정한다. catalog에 존재한다는 사실만으로 모든 상황에서 자동 발동하는 것은 아니다.
- Market 가중치는 early S1~S2, mid S3~S5, late S6+ band, rarity, Item tag, 부족한 성장축, `high_stakes` pressure를 입력으로 사용한다. 이는 등장 확률을 바꾸며 직접 지급을 만들지 않는다.
- Jester, Tile, Quick, Passive, Tool, Gear lane은 리롤 비용과 offset을 분리한다. 구매한 후보는 소비 상태가 되며 같은 Market에서 자동 보충되지 않는다.
- Boss pool은 난이도별 Station 순서와 run seed로 결정한다. S9+는 pool 길이를 순환하며 endless Station에서도 같은 결정식을 사용한다.

Market 후보 구현은 [jester_catalog_models.dart](../../lib/logic/rummi_poker_grid/jester_catalog_models.dart), [rummi_market_facade_builders.dart](../../lib/logic/rummi_poker_grid/rummi_market_facade_builders.dart), [jester_run_progress.dart](../../lib/logic/rummi_poker_grid/jester_run_progress.dart)가 함께 소유한다.

## Data to UI to Test Chain

| Family | Data → loader/model → runtime → UI → test |
|---|---|
| Jester | JSON → [jester_catalog_loader.dart](../../lib/logic/rummi_poker_grid/jester_catalog_loader.dart) / `RummiJesterCard` → Jester effect·run progress → [game_jester_widgets.dart](../../lib/views/game/widgets/game_jester_widgets.dart) / Market card → [jester_effect_runtime_test.dart](../../test/logic/jester_effect_runtime_test.dart), [rummi_session_test.dart](../../test/logic/rummi_session_test.dart) |
| Item | JSON → [item_catalog_loader.dart](../../lib/logic/rummi_poker_grid/item_catalog_loader.dart) / `ItemDefinition` → Item effect runtime·handlers → [game_shared_item_widgets.dart](../../lib/views/game/widgets/game_shared_item_widgets.dart) / Market action flow → [item_definition_test.dart](../../test/logic/item_definition_test.dart), [item_effect_runtime_test.dart](../../test/logic/item_effect_runtime_test.dart) |
| Tile modifier | enum + Item effect payload → `Tile.fromJson` / Item handlers → session tile modifier resolver → [game_shared_tile_widgets.dart](../../lib/views/game/widgets/game_shared_tile_widgets.dart) → [tile_model_test.dart](../../test/logic/tile_model_test.dart), [game_tile_modifier_copy_test.dart](../../test/views/game/widgets/game_tile_modifier_copy_test.dart) |
| Boss | known constants + Station pool → `RummiBossModifier` / Blind spec → session precondition·penalty → Boss HUD·intro·tile marker → [blind_selection_setup_test.dart](../../test/services/blind_selection_setup_test.dart), [boss_intro_test.dart](../../test/views/game/boss_intro_test.dart), [rummi_session_test.dart](../../test/logic/rummi_session_test.dart) |

한 단계의 필드나 ID를 바꾸면 오른쪽의 모든 소비자를 같은 변경에서 확인한다. UI 문자열만 맞고 runtime op가 빠졌거나, runtime은 동작하지만 save lookup이 끊기는 상태를 유효한 콘텐츠로 보지 않는다.

## Localization과 Save Coupling

- Jester와 Item은 locale별 JSON을 ID로 조회한다. 번역이 없으면 catalog의 영문 `displayName`·`effectText` fallback을 사용한다. 경로와 fallback은 [jester_translation_scope.dart](../../lib/resources/jester_translation_scope.dart), [item_translation_scope.dart](../../lib/resources/item_translation_scope.dart)가 소유한다.
- 새 Jester/Item ID는 정의 JSON, 지원 runtime, 모든 지원 locale 번역, UI 노출, generator self-check, save restore test를 함께 만족해야 한다.
- 저장은 번역문을 소유하지 않는다. ID와 durable state만 저장하고 현재 catalog·translation을 다시 결합한다.
- Tile modifier의 player-facing 이름·설명과 Boss title·rule은 현재 Dart presentation/code에 있다. 외부 번역 JSON이 있다고 가정하지 않으며, locale 구조를 바꿀 때 persistence value와 Boss ID는 유지한다.
- active run에 남은 Jester ID가 catalog에 없으면 restore는 실패한다. Item lookup이 없으면 보유 entry는 남을 수 있지만 runtime/read model에서 정의를 결합하지 못한다. 따라서 정의 삭제는 save compatibility 검토 없이 허용하지 않는다.

## Generated Views

- [CONTENT_CATALOG.md](../generated/CONTENT_CATALOG.md): current Jester·Item ID, player-facing 한국어, 가격, placement, trigger/timing/op의 재현 가능한 전체 표
- [BOSS_PATTERNS.md](../generated/BOSS_PATTERNS.md): current `boardCellBlock` ID, rule, blocked coordinates, 5×5 mask
- 생성·검증 명령: `dart run tools/generate_docs.dart`, `dart run tools/generate_docs.dart --check`

Core 문서는 위 표의 행을 복제하지 않는다. generated view가 stale이면 원본을 수정한 뒤 generator를 실행하며 generated Markdown을 손으로 고치지 않는다.

## Source와 Update Trigger

코드·데이터·테스트가 이 문서보다 우선한다. 다음이 바뀌면 같은 변경에서 이 문서와 generated view를 갱신한다.

- family의 ID, JSON shape, enum persistence value, Boss known modifier
- loader filter, Item `timing:op` dispatch, trigger 또는 score 적용 순서
- placement·stack·slot cap, Market pool·가중치·리롤 lane
- translation key/fallback 또는 active-save lookup 방식
- data → loader → runtime → UI → test chain의 어느 경계든 소유 파일이 변경될 때
