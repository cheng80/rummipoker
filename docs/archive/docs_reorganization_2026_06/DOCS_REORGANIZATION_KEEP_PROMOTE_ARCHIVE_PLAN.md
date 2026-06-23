# Docs Reorganization Keep / Promote / Archive Plan

> 목적: 다시 처음부터 Rummi Poker를 만든다고 해도 필요한 문서, 미래 확장/출시/도구 문서, 실제 정책 보존에 필요한 이력만 남기고 나머지는 archive-only 또는 삭제 후보로 정리한다.

## 결론

- ML/레벨링 실험 원문과 generated report는 승격하지 않는다. 현재 게임 정책은 `CURRENT_LEVELING_POLICY.md`, `CURRENT_LEVELING_RUNTIME_SPEC.md`, `HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` 같은 압축된 current 문서만 남긴다.
- archive라도 `DESIGN.md`, 보스/제약 taxonomy, 제약 visual language, Jester/Item taxonomy처럼 실제 정책·UI 품질이 무너질 수 있는 원칙은 원문 이동이 아니라 current/spec 문서로 요약 승격한다.
- 공모전/full_run_bot/daily log는 제출 증거와 과거 이력이다. 새 게임 재구축/출시 준비의 source-of-truth로 읽지 않는다.
- `old_doc_data`는 현행 `submission_kit`과 parity 확인 후 삭제 후보로 둔다.

## 판정 수

- `KEEP_REBUILD_CORE`: 20
- `KEEP_POLICY`: 6
- `KEEP_RELEASE`: 14
- `KEEP_TOOL`: 3
- `KEEP_FUTURE_EXECUTION`: 12
- `promote-summary`: 5
- `future-candidate`: 1
- `merge-if-needed`: 3
- `MERGE_OR_ARCHIVE`: 14
- `ARCHIVE_ONLY_EXPERIMENT`: 15
- `ARCHIVE_ONLY_HISTORY`: 27
- `ARCHIVE_ONLY_LEGACY`: 12
- `ARCHIVE_ONLY_FEATURE_HISTORY`: 4
- `DELETE_CANDIDATE_AFTER_PARITY`: 9

## 1차 실행 순서

1. 승격 후보 원문에서 필요한 정책만 추출해 `docs/specs/V4/` 또는 `docs/current_system/`에 흡수한다.
2. `START_HERE.md`, `README.md`, `docs/00_docs_README.md`의 읽는 순서를 새 구조에 맞춘다.
3. release/tool 문서를 `docs/release/submission_kit/`, `docs/tools/` 기준으로 재배치할지 결정한다.
4. ML/공모전/generated/daily log 경로는 archive-only index로만 연결한다.
5. `rg docs/archive START_HERE.md README.md docs/current_system docs/specs docs/planning`으로 archive가 현재 기준처럼 참조되는지 재검사한다.

## 파일별 판정표

| Action | File | 문서 성격 / 처리 이유 |
|---|---|---|
| `KEEP_REBUILD_CORE` | `docs/00_docs_README.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/current_system/00_current_system_README.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/current_system/BOSS_BOARD_CELL_BLOCK_PATTERNS.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/current_system/CURRENT_BUILD_BASELINE.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/current_system/CURRENT_CARD_CATALOG_TABLE.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/current_system/CURRENT_CODE_MAP.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/current_system/CURRENT_SYSTEM_OVERVIEW.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/current_system/CURRENT_TO_V4_GAP.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/goals/00_goals_README.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/goals/V4_PRODUCT_GOAL.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/00_specs_README.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/V4/00_README.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/V4/02_CORE_COMBAT_RULES.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/V4/03_RUN_META_ECONOMY.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/V4/04_JESTER_MARKET_CONTENT.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/V4/05_SAVE_CHECKPOINT_DATA.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/V4/06_UI_UX_FLOW.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/V4/07_TECHNICAL_ARCHITECTURE.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/V4/10_TERMINOLOGY_ALIAS.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_REBUILD_CORE` | `docs/specs/V4/13_ITEM_SYSTEM_CONTRACT.md` | 다시 처음부터 게임을 만들 때 필요한 핵심 목표/현재 사실/기능 계약입니다. |
| `KEEP_POLICY` | `docs/current_system/CURRENT_LEVELING_POLICY.md` | ML 실험 원문은 버리되 현재 게임 정책을 지키는 압축된 레벨링/경제 정책 문서로 유지합니다. |
| `KEEP_POLICY` | `docs/current_system/CURRENT_LEVELING_RUNTIME_SPEC.md` | ML 실험 원문은 버리되 현재 게임 정책을 지키는 압축된 레벨링/경제 정책 문서로 유지합니다. |
| `KEEP_POLICY` | `docs/current_system/CURRENT_LEVELING_SIMULATION_BASELINE.md` | ML 실험 원문은 버리되 현재 게임 정책을 지키는 압축된 레벨링/경제 정책 문서로 유지합니다. |
| `KEEP_POLICY` | `docs/planning/leveling/ECONOMY_LEVELING_PLAN.md` | ML 실험 원문은 버리되 현재 게임 정책을 지키는 압축된 레벨링/경제 정책 문서로 유지합니다. |
| `KEEP_POLICY` | `docs/planning/leveling/HEURISTIC_LEVELING_SIMULATION_DIRECTION.md` | ML 실험 원문은 버리되 현재 게임 정책을 지키는 압축된 레벨링/경제 정책 문서로 유지합니다. |
| `KEEP_POLICY` | `docs/planning/leveling/LEVELING_APPLIED_STATUS.md` | ML 실험 원문은 버리되 현재 게임 정책을 지키는 압축된 레벨링/경제 정책 문서로 유지합니다. |
| `KEEP_RELEASE` | `docs/release/APP_STORE_SCREENSHOTS_SKILL_USAGE_KO.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/project_information_poster_image_prompt.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/rummipoker_nas_deploy.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/ANDROID_BUILD_NOTES.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/BUILD_GUIDE.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/IN_APP_REVIEW_GUIDE.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/IOS_PROFILE_BUILD.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/README.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/RELEASE_CHECKLIST.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/SCREENSHOT_PROMO_COPY_KO_EN.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/STORE_METADATA_KO_EN.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/TUTORIAL_COACH_MARK_PLAN.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/submission_kit/WEB_BUILD_GUIDE.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_RELEASE` | `docs/release/web_build.md` | 출시/빌드/스토어/스크린샷/배포에 필요한 문서입니다. release/tools 영역으로 정리합니다. |
| `KEEP_TOOL` | `docs/tools/card_assets/CARD_ITEM_ILLUSTRATION_GUIDE.md` | 카드/Jester 이미지 제작 기준입니다. 출시 이미지 품질과 future asset production에 필요하므로 tools 또는 visual-assets 영역으로 유지합니다. |
| `KEEP_TOOL` | `docs/tools/card_assets/CARD_ITEM_IMAGE_PROMPTS.md` | 카드/Jester 이미지 생성 프롬프트 팩입니다. 재생성 가능한 asset tool 문서로 유지합니다. |
| `KEEP_TOOL` | `docs/tools/huashu-design-codex-usage.md` | 작업 도구 사용법입니다. docs/tools로 분리 후보입니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/planning/ACTIVE_EXECUTION_PLAN.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/archive/planning_superseded/POST_RITUAL_RUNTIME_REMAINING_WORK.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/planning/feature_plans/ANIMATION_EFFECTS_PLAN.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/planning/feature_plans/ITEM_EFFECT_RUNTIME_MATRIX.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/planning/feature_plans/ITEM_POLICY_CLEANUP_AUDIT.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/planning/feature_plans/ITEM_PRESENTATION_CONTRACT_REVIEW.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/planning/feature_plans/OPEN_DECISIONS.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/archive/feature_plan_history/RUN_HAND_GROWTH_AND_RUN_INFO_PLAN.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/archive/feature_plan_history/TILE_MODIFIER_V1_V2_PLAN.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/planning/goal/OVERALL_GOAL_PROGRESS.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/planning/verification/MARKET_ITEM_SMOKE_CHECKLIST.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `KEEP_FUTURE_EXECUTION` | `docs/planning/verification/TEST_QA_ACCEPTANCE.md` | 미래 작업과 현재 실행 판단에 필요한 계획/QA 문서입니다. 중복은 줄이되 유지합니다. |
| `promote-summary` | `docs/archive/feature_plans_2026_04/BOSS_MODIFIER_TAXONOMY_PLAN.md` | 보스/제약 분류 원칙만 새 BOSS_AND_CONSTRAINTS spec 또는 03/06 spec에 흡수 |
| `promote-summary` | `docs/archive/feature_plans_2026_04/CONSTRAINT_VISUAL_LANGUAGE_PLAN.md` | 제약 표시/문구/가시성 규칙만 UI_UX_FLOW로 흡수 |
| `promote-summary` | `docs/archive/feature_plans_2026_04/CONSUMABLE_VOUCHER_REFERENCE_PLAN.md` | Item/Tool/Gear/Ritual/Fate 장기 분류 원칙만 13_ITEM_SYSTEM_CONTRACT로 흡수 |
| `promote-summary` | `docs/archive/feature_plans_2026_04/JESTER_REFERENCE_TAXONOMY_PLAN.md` | Jester 확장 taxonomy만 04_JESTER_MARKET_CONTENT로 흡수 |
| `promote-summary` | `docs/archive/legacy/DESIGN.md` | 디자인 시스템 핵심만 docs/specs/V4/VISUAL_DESIGN_SYSTEM.md 또는 06_UI_UX_FLOW.md로 승격 |
| `future-candidate` | `docs/archive/feature_plans_2026_04/STARTING_DECK_ARCHETYPE_PLAN.md` | 런 시작/덱 archetype을 실제로 열 때만 future spec으로 요약 승격 |
| `merge-if-needed` | `docs/archive/feature_plans_2026_04/BLIND_STATION_PACING_BASELINE_PLAN.md` | 현재 target curve에 남은 원칙만 CURRENT_LEVELING_RUNTIME_SPEC로 흡수 |
| `merge-if-needed` | `docs/archive/feature_plans_2026_04/MARKET_OFFER_COUNT_RARITY_ROLL_PLAN.md` | Market 후보/rarity/reroll 정책 중 현재 정책에 필요한 부분만 04 또는 current leveling policy로 흡수 |
| `merge-if-needed` | `docs/archive/feature_plans_2026_04/STATION_PREVIEW_MAP_SCOPE_PLAN.md` | Station preview scope 중 현재 BlindSelect/Station 목표와 연결되는 부분만 03_RUN_META_ECONOMY로 흡수 |
| `MERGE_OR_ARCHIVE` | `docs/archive/planning_superseded/00_planning_README.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/planning_superseded/DOCUMENTATION_CONSOLIDATION_PLAN.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/feature_plan_history/DECK_GROWTH_AND_HIDDEN_HANDS_PLAN.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/feature_plan_history/MOTION_PASS_EXAMPLE_CASHOUT.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/feature_plan_history/MOTION_PASS_TEMPLATE.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/feature_plan_history/NEXT_SESSION_ITEM_PRESENTATION_PROMPT.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/feature_plan_history/OVERKILL_HAND_GROWTH_PROGRESS_PLAN.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/leveling/llm_experiment_history/LLM_AUTOPLAY_LEVELING_PLAN.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/leveling/llm_experiment_history/LLM_LOCAL_SETUP_PLAN.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/leveling/target_curve_history/STATION_TARGET_LOG_CURVE_2026_05_19.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/leveling/target_curve_history/STATION_TARGET_QUICK_BRIEF.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/redundant_build_docs/web_build.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/leveling/automation_ml/14_BALANCE_AUTOMATION_ML.md` | 핵심 내용만 상위 current/spec/planning에 흡수하고 원문은 archive-only로 전환합니다. |
| `MERGE_OR_ARCHIVE` | `docs/archive/visual_asset_reviews/RITUAL_CARD_IMAGE_OVERLAP_REVIEW.md` | 특정 시점의 이미지 겹침 검수 결과입니다. 반복 적용할 safe-zone/overlap 규칙만 일러스트 가이드로 흡수하고 원문은 보관합니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/ML_LEVELING_SIMULATION_DIRECTION_HISTORY.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/deprecated_2026_05/BOSS_POOL_EXPANSION_MAPPING.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/deprecated_2026_05/CURRENT_LEVELING_ML_BASELINE.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/deprecated_2026_05/ML_LEVELING_SIMULATION_DIRECTION.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/deprecated_2026_05/README.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/README.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/reports/actual_ml_transition_human_review.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/reports/leveling_analysis_methodology.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/reports/model_recommendation_report.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/reports/preoutcome_baseline_model_report.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/reports/preoutcome_candidate_recommendation_report.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/reports/preoutcome_candidate_resimulation_report.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/reports/preoutcome_grouped_validation_report.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/reports/preoutcome_sequence_baseline_model_report.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_EXPERIMENT` | `docs/archive/leveling/legacy_ml_outputs_2026_05/reports/preoutcome_sequence_candidate_recommendation_report.md` | ML/레벨링 실험 원문입니다. 현재 정책 판단에서 제거하고 historical prior로만 둡니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/00_archive_README.md` | archive 보관 문서입니다. 현재 기준으로 직접 쓰지 않습니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/generated/00_generated_README.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/generated/RUMMI_POKER_GRID_V4_COMBINED.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/generated/V4_MASTER_SPEC.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/leveling/00_leveling_archive_README.md` | archive 보관 문서입니다. 현재 기준으로 직접 쓰지 않습니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/planning_legacy_2026_05/IMPLEMENTATION_PLAN.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/planning_legacy_2026_05/MIGRATION_ROADMAP.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/planning_legacy_2026_05/README.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/planning_legacy_2026_05/STATUS.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/planning_legacy_2026_05/TEMP_WORK_SEQUENCE_PLAN.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/prompts/00_prompts_README.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/prompts/CODEX_V4_PLAN_INSTRUCTION.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/competition_history_2026_06/COMPETITION_SUBMISSION_CHECKLIST.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/competition_history_2026_06/COMPUTE_BROWSER_FULL_PLAY_BOT.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/competition_history_2026_06/NEXT_SESSION_CHALLENGE_FULL_RUN_PROMPT.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/competition_history_2026_06/NEXT_SESSION_SUBMISSION_HANDOFF_PROMPT.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/00_daily_logs_README.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-04-22.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-04-25.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-04-26.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-04-27.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-04-28.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-04-30.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-05-16.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-05-17.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-06-09.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_HISTORY` | `docs/archive/verification_daily_logs/2026-06-10.md` | 생성본/프롬프트/공모전/검증 로그/과거 planning 이력입니다. 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/00_legacy_README.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/DOCS_REORGANIZATION_PLAN.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/V4_CHANGELOG_FROM_V3.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/V4_STATUS_HISTORY_2026-04-22.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/game_logic_constants.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/jesters_common_phase5.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/riverpod_architecture.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/rummi_poker_grid_execution_checklist.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/rummi_poker_grid_game_logic.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/rummi_poker_grid_gdd.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/rummi_poker_grid_v2_instant_confirm_overlap.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_LEGACY` | `docs/archive/legacy/save_resume_architecture.md` | legacy 설계/구현 참고입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_FEATURE_HISTORY` | `docs/archive/feature_plans_2026_04/00_feature_plans_2026_04_README.md` | 과거 feature plan입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_FEATURE_HISTORY` | `docs/archive/feature_plans_2026_04/BALANCE_SIMULATION_READINESS_PLAN.md` | 과거 feature plan입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_FEATURE_HISTORY` | `docs/archive/feature_plans_2026_04/BALATRO_STYLE_SCORING_FEEDBACK_PLAN.md` | 과거 feature plan입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `ARCHIVE_ONLY_FEATURE_HISTORY` | `docs/archive/feature_plans_2026_04/BOARD_MOVE_HAND_SIZE_ITEM_JESTER_PLAN.md` | 과거 feature plan입니다. 승격 후보가 아니면 현재 기준에서 제외합니다. |
| `DELETE_CANDIDATE_AFTER_PARITY` | `docs/archive/delete_candidates_after_parity/old_doc_data/ANDROID_GRADLE_MIGRATION.md` | 구 앱 자료입니다. submission_kit과 parity 확인 후 삭제 후보입니다. |
| `DELETE_CANDIDATE_AFTER_PARITY` | `docs/archive/delete_candidates_after_parity/old_doc_data/DRAWER_AND_VERSION_GUIDE.md` | 구 앱 자료입니다. submission_kit과 parity 확인 후 삭제 후보입니다. |
| `DELETE_CANDIDATE_AFTER_PARITY` | `docs/archive/delete_candidates_after_parity/old_doc_data/IN_APP_REVIEW_GUIDE.md` | 구 앱 자료입니다. submission_kit과 parity 확인 후 삭제 후보입니다. |
| `DELETE_CANDIDATE_AFTER_PARITY` | `docs/archive/delete_candidates_after_parity/old_doc_data/IOS_PROFILE_BUILD.md` | 구 앱 자료입니다. submission_kit과 parity 확인 후 삭제 후보입니다. |
| `DELETE_CANDIDATE_AFTER_PARITY` | `docs/archive/delete_candidates_after_parity/old_doc_data/RELEASE_BUILD.md` | 구 앱 자료입니다. submission_kit과 parity 확인 후 삭제 후보입니다. |
| `DELETE_CANDIDATE_AFTER_PARITY` | `docs/archive/delete_candidates_after_parity/old_doc_data/RELEASE_CHECKLIST.md` | 구 앱 자료입니다. submission_kit과 parity 확인 후 삭제 후보입니다. |
| `DELETE_CANDIDATE_AFTER_PARITY` | `docs/archive/delete_candidates_after_parity/old_doc_data/SCREENSHOT_PROMO_COPY_KO_EN.md` | 구 앱 자료입니다. submission_kit과 parity 확인 후 삭제 후보입니다. |
| `DELETE_CANDIDATE_AFTER_PARITY` | `docs/archive/delete_candidates_after_parity/old_doc_data/STORE_METADATA_PLAY_APPSTORE_2026.md` | 구 앱 자료입니다. submission_kit과 parity 확인 후 삭제 후보입니다. |
| `DELETE_CANDIDATE_AFTER_PARITY` | `docs/archive/delete_candidates_after_parity/old_doc_data/TUTORIAL_SHOWCASEVIEW_GUIDE.md` | 구 앱 자료입니다. submission_kit과 parity 확인 후 삭제 후보입니다. |
