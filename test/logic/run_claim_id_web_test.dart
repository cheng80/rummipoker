import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/logic/rummi_poker_grid/jester_meta.dart';

void main() {
  test('새 런 claim ID는 웹에서도 생성된다', () {
    final claimId = RummiRunProgress().runClaimId;

    expect(claimId, isNotEmpty);
    expect(claimId, contains('-'));
  });
}
