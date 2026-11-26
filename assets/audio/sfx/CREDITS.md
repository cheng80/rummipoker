# 효과음 출처

추가한 아래 5개 파일은 커밋 `cb036111715184a2c9e02030c65c19499fe5fcfa`의 Kenney 후보에서 바이트 변경 없이 가져왔다. 해당 커밋의 CREDITS에 기록된 원본과 가공 정보를 아래에 보존한다. 기존 기록은 원본 팩의 License.txt에서 CC0를 확인했다고 명시한다. 이번 반영에서는 원본 팩을 다시 내려받거나 재가공하지 않았다.

기존 가공: mono 44.1kHz, 앞쪽 -50dB 이하 무음 제거, 길이 상한과 필요한 끝 fade, 평균 약 -22dB 및 최대 -1dB 목표. 표의 수치는 원 커밋 기록이다.

| 파일 | 계열 | 원본 팩 | 원본 파일 | 라이선스 | 길이 | 최대 음량 | 용량 |
|---|---|---|---|---|---|---|---|
| `Deny.mp3` | 거부 | [interface-sounds](https://kenney.nl/assets/interface-sounds) | `Audio/error_008.ogg` | CC0 | 0.14초 | -2.8 dB | 3.3 KB |
| `TilePick.wav` | 타일 집기 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/card-slide-4.ogg` | CC0 | 0.25초 | -1.0 dB | 21.4 KB |
| `TilePlace.wav` | 타일 놓기 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/card-place-1.ogg` | CC0 | 0.30초 | -1.0 dB | 25.9 KB |
| `CardToss.mp3` | 버리기 | [casino-audio](https://kenney.nl/assets/casino-audio) | `Audio/card-shove-2.ogg` | CC0 | 0.50초 | -1.3 dB | 9.0 KB |
| `Reward.mp3` | 보상 공개 | [music-jingles](https://kenney.nl/assets/music-jingles) | `Audio/Steel jingles/jingles_STEEL00.ogg` | CC0 | 0.93초 | -6.1 dB | 15.6 KB |

Kenney: https://kenney.nl · CC0: https://creativecommons.org/publicdomain/zero/1.0/

## ElevenLabs로 생성한 효과음 15개

2026-11-26에 ElevenLabs Sound Effects API(`POST /v1/sound-generation`, 모델 `eleven_text_to_sound_v3`, `prompt_influence` 0.5)로 생성했다. 생성 계정은 Creator 요금제다. 상업 이용 조건은 ElevenLabs 약관을 따른다. 이 문서를 쓰면서 약관을 따로 확인하지는 않았다.

모든 프롬프트 끝에는 같은 문장을 붙였다: "Single one-shot game sound effect, close and dry, no reverb tail, no music, no voice."

가공은 위 Kenney 파일과 같다. mono 44.1kHz, 앞뒤 -50dB 이하 무음 제거, 끝 fade, 평균 약 -22dB 및 최대 -1dB 목표다. 타일 두 개는 WAV, 나머지는 128kbps MP3다.

`Clear.mp3`는 유아 콘텐츠에 쓰던 음성 나레이션을 같은 이름의 말 없는 효과음으로 바꾼 것이다.

cue마다 후보를 2개씩 만들고 길이, 타격 수, 음량을 측정해서 골랐다. 사람이 들어 보고 고른 것이 아니므로 실제 청취 확인이 남아 있다.

| 파일 | 상황 | 프롬프트 | 길이 | 최대 음량 | 용량 |
|---|---|---|---|---|---|
| `TileDraw.wav` | 타일 드로우 | One hard plastic game tile slid off the top of a stack and picked up, quick crisp scrape and a light click. | 0.23초 | -6.5 dB | 20.0 KB |
| `TileMove.wav` | 타일 이동 | One hard plastic game tile pushed a short distance across a felt table and stopping with a soft tap. | 0.11초 | -1.0 dB | 9.5 KB |
| `ItemUse.mp3` | 아이템 사용 | A small magic charm being used: quick soft whoosh into a bright glassy sparkle, light and short. | 0.67초 | -4.1 dB | 11.5 KB |
| `LineTransform.mp3` | 줄 변환 | Five small plastic tiles flipping over one after another in a quick even row, tick tick tick tick tick, then a short bright shimmer. | 0.69초 | -5.8 dB | 11.9 KB |
| `Buy.mp3` | 구매 | A few gold coins dropped onto a wooden shop counter followed by one small cash register ding. | 0.77초 | -1.8 dB | 13.1 KB |
| `Sell.mp3` | 판매 | A small handful of gold coins poured into a leather pouch, short bright jingle. | 0.51초 | -1.7 dB | 9.0 KB |
| `Reroll.mp3` | 리롤 | A small stack of playing cards riffle shuffled once quickly and squared on a table. | 0.58초 | -1.4 dB | 10.2 KB |
| `Unlock.mp3` | 해금 | A metal latch clicks open, then a clear bright bell chime rings and fades. | 0.95초 | -1.5 dB | 16.0 KB |
| `StationAdvance.mp3` | Station 이동 | A soft upward whoosh into a clean rising two-note chime, moving on to the next stage. | 0.66초 | -7.6 dB | 11.5 KB |
| `RunStart.mp3` | 런 시작 | A deck of cards cut once, then a confident bright bell hit with a short warm ring, the start of a card game. | 1.00초 | -1.3 dB | 16.8 KB |
| `BattleStart.mp3` | 전투 시작 | One deep punchy drum hit together with a short sharp metallic shing, a tense round begins. | 0.55초 | -7.9 dB | 9.8 KB |
| `RunRestore.mp3` | 이어하기·북마크 복원 | A soft reverse swoosh rising into one gentle warm chime, returning to a saved game. | 0.77초 | -4.1 dB | 13.1 KB |
| `GameOver.mp3` | 게임 오버 | A low dull thud followed by two slow descending low brass notes, a somber defeat sting. | 0.83초 | -5.1 dB | 13.9 KB |
| `BossIntro.mp3` | Boss 인트로 | A dark low horn swell ending in one heavy deep impact, an ominous boss appears. | 1.44초 | -8.8 dB | 23.7 KB |
| `Clear.mp3` | 최종 정산창 등장 | A short bright triumphant sting: three quick rising chime notes with a sparkling shimmer and a soft flourish of coins, a stage is cleared. | 1.33초 | -3.6 dB | 21.7 KB |

기존 `BtnSnd.mp3`, `Collect.mp3`, `Fail.mp3`, `Start.mp3`, `TimeTic.mp3`, `TimeUp.wav`는 이 5개 Kenney 파일과 출처가 다르다. 기존 출처를 Kenney로 간주하지 않는다. BtnSnd는 사용자가 제공한 현재 파일을 그대로 유지한다.
