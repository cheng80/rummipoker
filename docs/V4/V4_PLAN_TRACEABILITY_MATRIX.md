# V4 Plan Traceability Matrix

문서 목적: `V4_IMPLEMENTATION_PLAN.md`의 근거가 되는 현재 코드와 V4 문서의 연결 관계를 추적한다.

| Area | Current Source | V4 Source | Status | Notes |
|---|---|---|---|---|
| Combat board size | `lib/logic/rummi_poker_grid/models/board.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | 5x5 고정 |
| Hand rank scoring | `lib/logic/rummi_poker_grid/hand_rank.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | One Pair 0점 |
| Partial line evaluation | `lib/logic/rummi_poker_grid/hand_evaluator.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/01_CURRENT_BASELINE.md` | [CODE VERIFIED] | 2~5장 평가 |
| Line scan scope | `lib/logic/rummi_poker_grid/rummi_poker_grid_engine.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | 행/열/대각 12줄 |
| Confirm removal policy | `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | contributor union만 제거 |
| Overlap constants | `lib/logic/rummi_poker_grid/rummi_poker_grid_session.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/02_CORE_COMBAT_RULES.md` | [CODE VERIFIED] | alpha 0.3, cap 2.0 |
| Stage resource model | `lib/logic/rummi_poker_grid/rummi_blind_state.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/03_RUN_META_ECONOMY.md` | [CODE VERIFIED] | `Blind` 명칭 유지 |
| Jester/economy/shop | `lib/logic/rummi_poker_grid/jester_meta.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/04_JESTER_MARKET_CONTENT.md` | [CODE VERIFIED] | Jester 중심 shop |
| Active run save | `lib/services/active_run_save_service.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/05_SAVE_CHECKPOINT_DATA.md` | [CODE VERIFIED] | save v2 + stageStartSnapshot |
| Save storage backend | `lib/utils/storage_helper.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/05_SAVE_CHECKPOINT_DATA.md` | [CODE VERIFIED] | GetStorage wrapper |
| Runtime orchestration | `lib/providers/features/rummi_poker_grid/game_session_notifier.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/07_TECHNICAL_ARCHITECTURE.md` | [CODE VERIFIED] | confirm/cash-out/shop/stage flow |
| Title continue flow | `lib/providers/features/rummi_poker_grid/title_notifier.dart`, `lib/views/title_view.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/06_UI_UX_FLOW.md` | [CODE VERIFIED] | continue/delete/corrupt save 분기 |
| Game UI flow | `lib/views/game_view.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/06_UI_UX_FLOW.md` | [CODE VERIFIED] | battle → cash-out → shop |
| Shop UI | `lib/views/game/widgets/game_shop_screen.dart` | `docs/V4/rummi_poker_grid_design_docs_v4/06_UI_UX_FLOW.md` | [CODE VERIFIED] | full-screen shop 유지 |
| Current baseline summary | `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md` | `docs/V4/rummi_poker_grid_design_docs_v4/01_CURRENT_BASELINE.md` | [DOC VERIFIED] | current baseline 보조 문서 |
| Code ownership map | `docs/current_system/CURRENT_CODE_MAP.md` | `docs/V4/rummi_poker_grid_design_docs_v4/07_TECHNICAL_ARCHITECTURE.md` | [DOC VERIFIED] | 파일 책임 정리 |
| Current-to-target gap | `docs/current_system/CURRENT_TO_V4_GAP.md` | `docs/V4/rummi_poker_grid_design_docs_v4/08_MIGRATION_ROADMAP.md` | [DOC VERIFIED] | target 단계화 근거 |
| One Pair future pressure | `docs/V4/rummi_poker_grid_design_docs_v4/11_OPEN_DECISIONS.md` | `docs/V4/rummi_poker_grid_design_docs_v4/02_CORE_COMBAT_RULES.md` | [CONFLICT] | 일부 타겟 논의와 current code 충돌 가능, 초기 계획에서는 보호 대상 |
