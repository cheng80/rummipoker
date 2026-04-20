# Screen References

현재 시안을 만들 때 기준으로 삼을 원본 스크린샷 경로다.

## Core References

- Battle baseline:
  `/tmp/rummipoker_ios_smoke/economy_redesign_battle_20260421_seq/01_launch.png`
- Market baseline:
  `/tmp/rummipoker_ios_smoke/economy_redesign_market_20260421/01_launch.png`
- Continue dialog baseline:
  `/tmp/rp_playwright_smoke/title_continue_dialog_fixed.png`
- Blind start dialog baseline:
  `/tmp/rp_playwright_smoke/blind_start_dialog_fixed.png`

## What To Preserve

- Phone frame 안전 영역
- 진한 녹색 felt 계열 surface
- 상단 HUD와 하단 action의 게임 UI 톤
- 텍스트 버튼이 아닌 형태 버튼

## What Must Change

- Battle: Jester와 Item을 한 구조로 다루지 않는다
- Market: Jester와 Item은 section 자체를 분리한다
- Item 도입 이후에도 board/hand/action readability가 깨지지 않아야 한다

## Notes For Stitch

- 현재 화면은 Jester-only baseline이다
- 새 시안은 Jester-only 화면을 polish하는 것이 아니라
  `Jester + Item split architecture`를 보여줘야 한다
