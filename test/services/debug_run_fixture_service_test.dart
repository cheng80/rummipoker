import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/services/debug_run_fixture_service.dart';
import 'package:rummipoker/services/active_run_save_service.dart';

void main() {
  test('fixture registry exposes stage2 scoring snapshot entry', () {
    final fixtures = DebugRunFixtureService.fixtures;
    final fixture = fixtures.where(
      (entry) => entry.id == DebugRunFixtureService.stage2ScoringSnapshot,
    );

    expect(fixture, isNotEmpty);
    expect(fixture.single.label, isNotEmpty);
    expect(fixture.single.description, isNotEmpty);
  });

  test('fixture registry exposes stage2 market resume entry', () {
    final fixtures = DebugRunFixtureService.fixtures;
    final fixture = fixtures.where(
      (entry) => entry.id == DebugRunFixtureService.stage2MarketResume,
    );

    expect(fixture, isNotEmpty);
    expect(fixture.single.label, isNotEmpty);
    expect(fixture.single.description, isNotEmpty);
  });

  test('stage2 scoring snapshot fixture restores expected board and meta', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.stage2ScoringSnapshot,
    );

    expect(fixture, isNotNull);
    expect(fixture!.runProgress.stageIndex, 2);
    expect(fixture.runProgress.gold, 36);
    expect(fixture.runProgress.ownedJesters.map((card) => card.id).toList(), [
      'crazy_jester',
      'scary_face',
    ]);
    expect(fixture.session.blind.targetScore, 480);
    expect(fixture.session.blind.scoreTowardBlind, 0);
    expect(fixture.session.deck.remaining, 34);
    expect(fixture.session.hand, isEmpty);
    expect(fixture.session.board.cellAt(0, 0)?.number, 12);
    expect(fixture.session.board.cellAt(0, 1)?.number, 11);
    expect(fixture.session.board.cellAt(4, 2)?.number, 7);
    expect(fixture.session.board.cellAt(4, 4)?.number, 12);
  });

  test('stage2 market resume fixture opens in shop scene with offers', () {
    final fixture = DebugRunFixtureService.build(
      DebugRunFixtureService.stage2MarketResume,
    );

    expect(fixture, isNotNull);
    expect(fixture!.activeScene, ActiveRunScene.shop);
    expect(fixture.runProgress.stageIndex, 2);
    expect(fixture.runProgress.gold, 46);
    expect(fixture.runProgress.shopOffers.length, 2);
    expect(
      fixture.runProgress.shopOffers.map((offer) => offer.card.id).toList(),
      ['green_jester', 'popcorn'],
    );
  });

  test(
    'deck needle battle fixture starts with quick slot item and known deck top',
    () {
      final fixture = DebugRunFixtureService.build(
        DebugRunFixtureService.deckNeedleBattle,
      );

      expect(fixture, isNotNull);
      expect(fixture!.activeScene, ActiveRunScene.battle);
      expect(fixture.runProgress.itemInventory.quickSlotItemIds, [
        'deck_needle',
      ]);
      expect(fixture.session.peekDeckTop(3).map((tile) => tile.number), [
        1,
        2,
        3,
      ]);
    },
  );
}
