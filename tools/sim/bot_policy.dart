import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';
import 'package:rummipoker/logic/rummi_poker_grid/rummi_poker_grid_session.dart';

/// CLI 시뮬레이터가 전투 상태에서 다음 행동을 고르는 최소 정책 경계.
abstract class BalanceSimBotPolicy {
  const BalanceSimBotPolicy();

  String get id;

  BalanceSimAction chooseAction(
    RummiPokerGridSession session, {
    required List<RummiJesterCard> jesters,
  });
}

enum BalanceSimActionType { draw, place, confirm, discardBoard, stop }

class BalanceSimAction {
  const BalanceSimAction._({
    required this.type,
    this.handIndex,
    this.row,
    this.col,
    this.reason,
  });

  const BalanceSimAction.draw() : this._(type: BalanceSimActionType.draw);

  const BalanceSimAction.confirm() : this._(type: BalanceSimActionType.confirm);

  const BalanceSimAction.place({
    required int handIndex,
    required int row,
    required int col,
  }) : this._(
         type: BalanceSimActionType.place,
         handIndex: handIndex,
         row: row,
         col: col,
       );

  const BalanceSimAction.discardBoard({required int row, required int col})
    : this._(type: BalanceSimActionType.discardBoard, row: row, col: col);

  const BalanceSimAction.stop(String reason)
    : this._(type: BalanceSimActionType.stop, reason: reason);

  final BalanceSimActionType type;
  final int? handIndex;
  final int? row;
  final int? col;
  final String? reason;
}
