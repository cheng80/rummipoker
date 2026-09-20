<!-- tools/build_sfx.py 가 만든다. 직접 고치지 말고 스크립트를 고친 뒤 다시 실행한다. -->

# 효과음 출처

`assets/audio/sfx/`의 효과음이 어디에서 왔고 어떤 가공을 거쳤는지 적는다.

## 새로 넣은 효과음

원본은 모두 Kenney(<https://kenney.nl>)의 CC0 오디오 팩이다. CC0는 저작자 표시
의무가 없고 상업적으로 써도 된다. 팩마다 들어 있는 `License.txt`에서 직접
확인했다. 라이선스 전문은 <https://creativecommons.org/publicdomain/zero/1.0/>
에 있다.

공통 가공은 다음과 같다. mono 44.1kHz로 바꾸고, 앞쪽의 -50 dB 이하 무음을
잘라 입력 직후 바로 소리가 나게 했다. 계열마다 정한 상한까지 길이를 자르고,
끝에는 짧은 fade out을 넣어 잘린 자리가 튀지 않게 했다. 음량은 기존 효과음
7개를 잰 값에 맞춰 평균 -22 dB 수준으로 올리되 최대치가 -1 dB를 넘지 않게
했다. 만드는 과정은 `tools/build_sfx.py` 하나에 들어 있다.


| 파일 | 계열 | 원본 팩 | 원본 파일 | 라이선스 | 길이 | 최대 음량 | 용량 |
|---|---|---|---|---|---|---|---|
| `UiToggle.wav` | 토글·탭 전환 | [interface-sounds](https://kenney.nl/assets/interface-sounds) | `Audio/toggle_001.ogg` | CC0 | 0.14초 | -8.9 dB | 11.8 KB |
| `PanelOpen.mp3` | 모달 열림 | [interface-sounds](https://kenney.nl/assets/interface-sounds) | `Audio/open_004.ogg` | CC0 | 0.32초 | -6.1 dB | 6.2 KB |
| `PanelClose.mp3` | 모달 닫힘 | [interface-sounds](https://kenney.nl/assets/interface-sounds) | `Audio/close_004.ogg` | CC0 | 0.32초 | -4.4 dB | 6.2 KB |
| `Deny.mp3` | 거부 | [interface-sounds](https://kenney.nl/assets/interface-sounds) | `Audio/error_008.ogg` | CC0 | 0.14초 | -2.8 dB | 3.3 KB |
| `TilePick.wav` | 타일 집기 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/card-slide-4.ogg` | CC0 | 0.25초 | -1.0 dB | 21.4 KB |
| `TilePlace.wav` | 타일 놓기 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/card-place-1.ogg` | CC0 | 0.30초 | -1.0 dB | 25.9 KB |
| `CardDraw.mp3` | 드로우 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/card-slide-1.ogg` | CC0 | 0.40초 | -1.5 dB | 7.4 KB |
| `CardToss.mp3` | 버리기 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/card-shove-2.ogg` | CC0 | 0.50초 | -1.3 dB | 9.0 KB |
| `LineLoad.mp3` | 줄 장전 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/chips-stack-3.ogg` | CC0 | 0.37초 | -1.8 dB | 7.0 KB |
| `StationTick.wav` | 정산 단계 | [interface-sounds](https://kenney.nl/assets/interface-sounds) | `Audio/confirmation_001.ogg` | CC0 | 0.29초 | -11.6 dB | 25.0 KB |
| `ScoreTick.wav` | 점수 카운트 | [interface-sounds](https://kenney.nl/assets/interface-sounds) | `Audio/pluck_001.ogg` | CC0 | 0.10초 | -1.6 dB | 8.6 KB |
| `MultHit.mp3` | 배수 타격 | [impact-sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactPunch_medium_000.ogg` | CC0 | 0.43초 | -6.4 dB | 7.8 KB |
| `JesterFire.mp3` | Jester·Item 발동 | [digital-audio](https://kenney.nl/assets/digital-audio) | `Audio/phaserUp3.ogg` | CC0 | 0.46초 | -9.2 dB | 8.2 KB |
| `ScoreImpact.mp3` | 최종 점수 | [impact-sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactPlate_heavy_000.ogg` | CC0 | 0.49초 | -1.6 dB | 8.6 KB |
| `Gold.mp3` | gold 거래 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/chips-collide-1.ogg` | CC0 | 0.18초 | -1.2 dB | 3.7 KB |
| `Shuffle.mp3` | 리롤 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/card-shuffle.ogg` | CC0 | 1.20초 | -1.6 dB | 19.6 KB |
| `BossIntro.mp3` | Boss 등장 | [impact-sounds](https://kenney.nl/assets/impact-sounds) | `Audio/impactBell_heavy_000.ogg` | CC0 | 1.48초 | -1.5 dB | 24.1 KB |
| `Reward.mp3` | 보상 공개 | [music-jingles](https://kenney.nl/assets/music-jingles) | `Audio/Steel jingles/jingles_STEEL00.ogg` | CC0 | 0.93초 | -6.1 dB | 15.6 KB |

## 원래 있던 효과음

`BtnSnd.mp3`, `Clear.mp3`, `Collect.mp3`, `Fail.mp3`, `Start.mp3`,
`TimeTic.mp3`, `TimeUp.wav`는 이 저장소에 먼저 있던 파일이다. 이번 작업에서
건드리지 않았고 출처 기록도 따로 남아 있지 않다.
