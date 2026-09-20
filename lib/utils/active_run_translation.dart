import 'package:flutter/widgets.dart';

import '../services/active_run_save_facade.dart';
import '../services/blind_selection_spec.dart';
import '../services/new_run_setup.dart';
import 'app_translation.dart';

extension ActiveRunTranslation on BuildContext {
  String activeRunLocation(RummiActiveRunSaveFacade summary) => translate(
    'coreSaveLocation',
    namedArgs: {
      'station': '${summary.currentStationIndex}',
      'scene': translate(switch (summary.sceneAlias) {
        RummiSaveSceneAlias.battle => 'coreSaveSceneBattle',
        RummiSaveSceneAlias.market => 'coreSaveSceneMarket',
        RummiSaveSceneAlias.blindSelect => 'coreSaveSceneBlindSelect',
      }),
      'gold': '${summary.currentGold}',
    },
  );

  String activeRunSnapshot(RummiActiveRunSaveFacade summary) => translate(
    'coreSaveSnapshot',
    namedArgs: {
      'location': activeRunLocation(summary),
      'checkpoint': translate(
        'coreSaveCheckpoint',
        namedArgs: {'station': '${summary.checkpoint.stationIndex}'},
      ),
    },
  );

  String activeRunContinueMessage(RummiActiveRunSaveFacade summary) =>
      translate(
        'coreSaveContinue',
        namedArgs: {'summary': activeRunSnapshot(summary)},
      );

  String runModeLabel({
    NewRunDifficulty? difficulty,
    NewRunModifier? runModifier,
    String? difficultyLabel,
    String? runModifierLabel,
  }) {
    final shownDifficulty = difficulty == null
        ? difficultyLabel ?? translate(NewRunDifficulty.standard.labelKey)
        : translate(difficulty.labelKey);
    final shownModifier = runModifier == null
        ? runModifierLabel
        : runModifier == NewRunModifier.basic
        ? null
        : translate(runModifier.labelKey);
    return shownModifier == null || shownModifier.isEmpty
        ? shownDifficulty
        : translate(
            'coreSaveModeModifier',
            namedArgs: {
              'difficulty': shownDifficulty,
              'modifier': shownModifier,
            },
          );
  }

  String activeRunBookmark(RummiActiveRunSaveFacade summary) {
    final mode = runModeLabel(
      difficulty: summary.difficulty,
      runModifier: summary.runModifier,
      difficultyLabel: summary.difficultyLabel,
      runModifierLabel: summary.runModifierLabel,
    );
    return translate(
      'coreSaveBookmark',
      namedArgs: {
        'station':
            '${summary.currentStageIndex >= 9 ? '∞' : ''}S${summary.currentStageIndex}',
        'mode': mode,
        'blind': switch (summary.currentBlindTierIndex) {
          0 => 'SCOUT',
          1 => 'CLASH',
          2 => 'BOSS',
          _ => translate('coreSaveBlindUnselected'),
        },
      },
    );
  }

  String activeRunSlotTitle(ActiveRunBookmarkSlotView slot) => translate(
    'coreSaveSlotTitle',
    namedArgs: {'slot': '${slot.slotIndex + 1}'},
  );

  String activeRunSlotLabel(ActiveRunBookmarkSlotView slot) =>
      slot.summary == null
      ? translate('coreSaveEmpty')
      : activeRunBookmark(slot.summary!);

  String activeRunSlotSemantic(ActiveRunBookmarkSlotView slot) => translate(
    'coreSaveSlotSemantic',
    namedArgs: {
      'slot': activeRunSlotTitle(slot),
      'summary': activeRunSlotLabel(slot),
    },
  );

  String blindLockReason(BlindSelectionSpec spec) {
    final requiredTier = spec.requiredClearedTier;
    if (requiredTier == null) {
      return spec.lockReason ?? translate('menuNotSelectable');
    }
    return translate(
      'coreSaveBlindUnlock',
      namedArgs: {
        'required': _tierName(requiredTier),
        'blind': _tierName(spec.tier),
      },
    );
  }
}

String _tierName(BlindTier tier) => switch (tier) {
  BlindTier.small => 'Scout',
  BlindTier.big => 'Clash',
  BlindTier.boss => 'Boss',
};
