import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../logic/rummi_poker_grid/item_definition.dart';
import '../../../logic/rummi_poker_grid/item_effect_runtime.dart';
import '../../../logic/rummi_poker_grid/item_presentation_event.dart';
import '../../../logic/rummi_poker_grid/jester_meta.dart';
import '../../../logic/rummi_poker_grid/line_ref.dart';
import '../../../logic/rummi_poker_grid/rummi_battle_facade.dart';
import '../../../logic/rummi_poker_grid/rummi_market_facade.dart';
import '../../../logic/rummi_poker_grid/models/board.dart';
import '../../../logic/rummi_poker_grid/models/poker_deck.dart';
import '../../../logic/rummi_poker_grid/models/tile.dart';
import '../../../logic/rummi_poker_grid/rummi_poker_grid_session.dart';
import '../../../logic/rummi_poker_grid/rummi_blind_state.dart';
import '../../../logic/rummi_poker_grid/rummi_ruleset.dart';
import '../../../logic/rummi_poker_grid/rummi_station_facade.dart';
import '../../../services/active_run_save_facade.dart';
import '../../../services/active_run_save_service.dart';
import '../../../services/blind_selection_setup.dart';
import '../../../services/new_run_setup.dart';
import '../../../services/run_unlock_state_service.dart';
import 'game_session_state.dart';

part 'game_session_notifier_models.dart';
part 'game_session_notifier_bootstrap.dart';
part 'game_session_notifier_save_commands.dart';
part 'game_session_notifier_presentation_commands.dart';
part 'game_session_notifier_battle_commands.dart';
part 'game_session_notifier_market_commands.dart';
part 'game_session_notifier_station_commands.dart';

/// 전투 화면의 세션/선택/UI 잠금 상태를 한곳에서 관리한다.
final gameSessionNotifierProvider =
    NotifierProvider.family<
      GameSessionNotifier,
      GameSessionState,
      GameSessionArgs
    >(GameSessionNotifier.new);

ActiveRunRuntimeState buildInitialRunRuntime(GameSessionArgs args) {
  final state = _buildInitialGameSessionState(args);
  final session = state.session!;
  final runProgress = state.runProgress!.copySnapshot()
    ..currentStationBlindTierIndex = -1;
  final startSnapshot = ActiveRunSaveService.captureStageStartSnapshot(
    session: session,
    runProgress: runProgress,
  );
  final blindSelectBossModifier = BlindSelectionSetup.resolveSpec(
    tier: BlindTier.boss,
    stationIndex: runProgress.stageIndex,
    difficulty: args.difficulty,
    runModifier: args.runModifier,
    runSeed: session.runSeed,
    ruleset: session.ruleset,
  ).bossModifier;
  return ActiveRunRuntimeState(
    activeScene: ActiveRunScene.blindSelect,
    difficulty: args.difficulty,
    runModifier: args.runModifier,
    blindSelectBossModifier: blindSelectBossModifier,
    session: session,
    runProgress: runProgress,
    stageStartSnapshot: startSnapshot,
    stakeStartSnapshot: startSnapshot,
  );
}

class DeckPeekBattleUseResult {
  const DeckPeekBattleUseResult._({required this.candidates, this.failMessage});

  const DeckPeekBattleUseResult.success(List<Tile> candidates)
    : this._(candidates: candidates);

  const DeckPeekBattleUseResult.failure(String message)
    : this._(candidates: const [], failMessage: message);

  final List<Tile> candidates;
  final String? failMessage;

  bool get isSuccess => failMessage == null;
}

class GameSessionNotifier
    extends FamilyNotifier<GameSessionState, GameSessionArgs>
    with
        GameSessionNotifierSaveCommands,
        GameSessionNotifierPresentationCommands,
        GameSessionNotifierBattleCommands,
        GameSessionNotifierMarketCommands,
        GameSessionNotifierStationCommands {
  @override
  GameSessionState build(GameSessionArgs args) {
    return _withDerivedViews(_buildInitialGameSessionState(args));
  }

  // -- Business logic --

  // -- 전투 액션 (View에서 직접 session을 조작하던 것을 이관) --

  @override
  void _replaceState(GameSessionState next) {
    state = _withDerivedViews(next);
  }

  GameSessionState _withDerivedViews(GameSessionState next) {
    final session = next.session;
    final runProgress = next.runProgress;
    if (session == null || runProgress == null) {
      return next.copyWith(
        stationView: null,
        marketView: null,
        battleView: null,
        activeRunSaveView: null,
      );
    }

    return next.copyWith(
      stationView: RummiStationRuntimeFacade.fromSession(session),
      marketView: RummiMarketRuntimeFacade.fromRunProgress(
        runProgress,
        pressureProfile: _marketPressureProfileFor(next.runModifier),
      ),
      battleView: RummiBattleRuntimeFacade.fromRuntime(
        session: session,
        runProgress: runProgress,
      ),
      activeRunSaveView: RummiActiveRunSaveFacade.fromRuntimeState(
        ActiveRunRuntimeState(
          activeScene: next.activeRunScene,
          difficulty: arg.difficulty,
          runModifier: next.runModifier,
          session: session,
          runProgress: runProgress,
          stageStartSnapshot:
              next.stageStartSnapshot ??
              ActiveRunSaveService.captureStageStartSnapshot(
                session: session,
                runProgress: runProgress,
              ),
          stakeStartSnapshot:
              next.stakeStartSnapshot ??
              next.stageStartSnapshot ??
              ActiveRunSaveService.captureStageStartSnapshot(
                session: session,
                runProgress: runProgress,
              ),
        ),
      ),
    );
  }

  @override
  RummiMarketPressureProfile _marketPressureProfileFor(
    NewRunModifier modifier,
  ) {
    return modifier == NewRunModifier.highStakes
        ? RummiMarketPressureProfile.highStakes
        : RummiMarketPressureProfile.standard;
  }
}
