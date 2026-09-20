# I18N 용어집

게임 용어를 5개 언어로 어떻게 쓸지 정리한 목록이다. 번역 키를 추가하는 사람이 같은 개념에 매번 다른 말을 쓰지 않도록 여기를 먼저 본다. 번역 작업 절차와 키 이름 규칙은 [I18N](../core/I18N.md)이 소유한다.

읽는 법은 간단하다. **이미 번역된 용어**는 번역 파일에 실제로 들어 있는 값을 그대로 옮긴 것이고, 그것이 기준이다. **새 용어**는 아직 어느 번역 파일에도 없어서 초안만 적어 둔 것이고, 사용자 검수가 끝나기 전까지는 확정이 아니다.

Boss 28종의 이름·규칙·표시는 `assets/translations/src/core/<locale>.json`의 `coreBoss*Title`, `coreBoss*Rule`, `coreBoss*Marker`에서 관리한다. 저장 필드의 한국어 원문과 현재 locale의 표시 번역은 구분한다.

이 문서는 손으로 관리한다. 번역 파일에서 뽑았지만 생성물은 아니다.

## 1. 이미 번역된 용어

`assets/translations/<locale>.json`과 `assets/translations/data/<locale>/*.json`에서 그대로 옮겼다. 출처 열은 그 값이 들어 있는 번역 키다.

### 기본 개념

| 한국어 | English | 日本語 | 简体中文 | 繁體中文 | 출처 키 |
|---|---|---|---|---|---|
| 칩 | Chips | Chips | Chips | Chips | `gameTermChipsTitle` |
| 골드 | Gold | Gold | Gold | Gold | `gameTermGoldTitle` |
| 점수 +% | Score +% | 得点 +% | 分数 +% | 分數 +% | `gameTermScorePercentTitle` |
| 점수 xN | Score xN | 得点 xN | 分数 xN | 分數 xN | `gameTermScoreMultiplierTitle` |
| 최고 기록 | Best score | ベストスコア | 最好成绩 | 最佳成績 | `bestScore` |
| 런 정보 | Run Info | ラン情報 | 本轮信息 | 本輪資訊 | `runInfoTitle` |
| 시드 | Seed | シード | 种子 | 種子 | `runSeedLabel` |
| 보드 | Board | ボード | 棋盘 | 棋盤 | `tutorialBattleBoardTitle` |
| 도감 | Archive | 図鑑 | 图鉴 | 圖鑑 | `archiveTitle` |
| 게임결과 | Game Result | ゲーム結果 | 游戏结果 | 遊戲結果 | `gameResult` |

숫자를 끼워 쓰는 자리에서 칩은 `칩 {score}` / `Chips {score}`처럼 쓴다(`runInfoCurrentChips`). 일본어·중국어의 `Chips`와 `Jester`는 **결정됨: 영어 유지(2026-09-21 사용자 결정)**다. 문장과 합성어에도 적용하며 한국어 `칩`과 `Reroll Chip` 같은 고유명은 유지한다.

### 화면과 메뉴

| 한국어 | English | 日本語 | 简体中文 | 繁體中文 | 출처 키 |
|---|---|---|---|---|---|
| 설정 | Settings | 設定 | 设置 | 設定 | `settings` |
| 옵션 | Options | オプション | 选项 | 選項 | `gameOptions` |
| 언어 | Language | 言語 | 语言 | 語言 | `language` |
| 화면 | Screen | 画面 | 画面 | 畫面 | `sectionScreen` |
| 사운드 | Sound | サウンド | 声音 | 聲音 | `sectionSound` |
| 연출 | Effects | 演出 | 演出 | 演出 | `sectionEffects` |
| 배경음악 | BGM | BGM | BGM | BGM | `bgm` |
| 효과음 | SFX | 効果音 | 音效 | 音效 | `sfx` |
| 진동 | Vibration | 振動 | 振动 | 震動 | `haptics` |
| 이어하기 | Continue | 続きから | 继续 | 繼續 | `homeContinueSectionTitle` |
| 기타 | More | その他 | 其他 | 其他 | `homeOtherMenuSectionTitle` |

### 버튼과 상태

| 한국어 | English | 日本語 | 简体中文 | 繁體中文 | 출처 키 |
|---|---|---|---|---|---|
| 확인 | OK | OK | 确定 | 確定 | `ok` |
| 취소 | Cancel | キャンセル | 取消 | 取消 | `cancel` |
| 계속하기 | Continue | 続ける | 继续 | 繼續 | `continueGame` |
| 다시하기 | Retry | もう一度 | 再玩一次 | 再玩一次 | `retry` |
| 나가기 | Exit | 終了 | 退出 | 退出 | `exit` |
| 복사 | Copy | コピー | 复制 | 複製 | `copy` |
| 힌트 | Hint | ヒント | 提示 | 提示 | `hint` |
| 일시정지 | Paused | 一時停止 | 暂停 | 暫停 | `paused` |
| 완료 | Done | 完了 | 完成 | 完成 | `tutorialDone` |
| 다음 | Next | 次へ | 下一步 | 下一步 | `tutorialNext` |
| 스킵 | Skip | スキップ | 跳过 | 略過 | `tutorialSkip` |
| NEW | NEW | NEW | NEW | NEW | `flowArchiveNew`, `t3MarketNew` |

### 런 시작과 진행

| 한국어 | English | 日本語 | 简体中文 | 繁體中文 | 출처 키 |
|---|---|---|---|---|---|
| 랜덤 시작 | Random Start | ランダム開始 | 随机开始 | 隨機開始 | `entryRandomSeed` |
| 시드 시작 | Seed Start | シード開始 | 种子开始 | 種子開始 | `entryInputSeed` |
| 시드로 시작 | Start with seed | シードで開始 | 以种子开始 | 以種子開始 | `seedDialogTitle` |
| 숫자 | Numbers | 数字 | 数字 | 數字 | `modeNumber` |
| 알파벳 | Alphabet | アルファベット | 字母 | 字母 | `modeAlphabet` |
| 완성 {count}회 | Completed {count} | 完成 {count}回 | 完成 {count}次 | 完成 {count}次 | `runInfoCompletedCount` |
| Lv.{level} | Lv.{level} | Lv.{level} | Lv.{level} | Lv.{level} | `runInfoRankLevel` |

### 정산 등급

| 한국어 | English | 日本語 | 简体中文 | 繁體中文 | 출처 키 |
|---|---|---|---|---|---|
| 좋아요 | Nice | ナイス | 不错 | 不錯 | `settlementGrade0` |
| 훌륭해요! | Great! | グレート! | 很棒! | 很棒! | `settlementGrade1` |
| 대단해요!! | Superb!! | スーパー!! | 精彩!! | 精彩!! | `settlementGrade2` |
| 전설적!!! | Legendary!!! | レジェンド!!! | 传奇!!! | 傳奇!!! | `settlementGrade3` |
| Clear! | Clear! | Clear! | Clear! | Clear! | `clear` |

### 연출 강도

| 한국어 | English | 日本語 | 简体中文 | 繁體中文 | 출처 키 |
|---|---|---|---|---|---|
| 끔 | Off | オフ | 关 | 關 | `fxIntensityOff` |
| 보통 | Normal | 普通 | 普通 | 普通 | `fxIntensityNormal` |
| 강 | Strong | 強 | 强 | 強 | `fxIntensityStrong` |
| 즉시 | Instant | 即時 | 立即 | 立即 | `settlementSpeedInstant` |

### 이미 번역된 Item·Jester 이름

`assets/translations/data/<locale>/{items,jesters}.json`에 Item 91개와 Jester 43개의 이름·설명이 5개 언어로 모두 들어 있다. 이 이름들은 개별 콘텐츠이므로 여기에 옮겨 적지 않는다. 정확한 목록은 [CONTENT_CATALOG](../generated/CONTENT_CATALOG.md)를 본다.

번역 방식만 적어 두면, 영어·일본어·중국어의 Item 이름은 모두 영어 고유명(`Reroll Chip`, `Board Glove`, `Score Abacus`)을 그대로 쓴다. 한국어만 우리말 이름(`리롤 칩`, `보드 장갑`, `점수 주판`)을 쓴다. 새 Item·Jester를 추가할 때도 이 방식을 따른다.

### 통합에서 추가한 표시 용어

I1·I2·I3·I4의 조각과 대조한 실제 표시값이다. 같은 북마크 동작도 버튼 폭과 문맥에 따라 짧은 `Bookmarks`와 구체적인 `Load Bookmark`를 구분한다.

| 한국어 | English | 日本語 | 简体中文 | 繁體中文 | 출처 키 |
|---|---|---|---|---|---|
| 표준 | Standard | 標準 | 标准 | 標準 | `menuStandard` |
| 도전 | Challenge | チャレンジ | 挑战 | 挑戰 | `menuChallenge` |
| 하이 스테이크 | High Stakes | ハイステークス | 高风险 | 高風險 | `menuHighStakes` |
| 북마크 불러오기 | Bookmarks | ブックマーク | 书签 | 書籤 | `menuBookmarks` |
| 정산 완료 | Cash out complete | 精算完了 | 结算完成 | 結算完成 | `marketCashoutComplete` |
| 첫 리롤 무료 | First reroll free | 初回無料 | 首次免费重掷 | 首次免費重擲 | `marketRerollFirstFree` |
| 칩 박힘 | Chip Inlay | Chips埋め込み | Chips 镶嵌 | Chips 鑲嵌 | `battleWidgetsTileEnhancementChip` |
| 점수 도금 | Score Gilding | 得点メッキ | 分数镀金 | 分數鍍金 | `battleWidgetsTileEnhancementScore` |
| 유리 | Glass | ガラス | 玻璃 | 玻璃 | `battleWidgetsTileEnhancementGlass` |
| 경제형 | Economy | 経済型 | 经济型 | 經濟型 | `battleWidgetsCategoryEconomy` |
| 상태형 | Stateful | 状態型 | 状态型 | 狀態型 | `battleWidgetsCategoryStateful` |
| 점수형 | Score | 得点型 | 得分型 | 得分型 | `battleWidgetsCategoryScore` |
| 미완성/무득점 | Incomplete / no score | 未完成／得点なし | 未完成／无得分 | 未完成／無得分 | `battleNoScoringLine` |
| 덮어쓰기 | Overwrite | 上書き | 覆盖 | 覆寫 | `battleOverwrite` |
| 디버그 설정 | Debug settings | デバッグ設定 | 调试设置 | 偵錯設定 | `battleDebugSettings` |

## 2. 추가 용어와 검수 상태

족보 16종은 `assets/translations/src/core/<locale>.json`의 `coreHandRank*`에 반영했다. `미완성/무득점`은 `battleNoScoringLine`의 표시값이다. 아래 표는 각 키의 값과 일치하며 일본어 로우 스티플은 `ローストレートフラッシュ`다. 나머지 초안은 각 트랙의 번역 조각과 대조해 갱신한다. 사용자가 검수해 값을 고치면 그쪽이 기준이 된다.

### 족보 이름

이 게임의 족보 이름은 포커에서 빌려 왔다. 한국어 표기가 `스티플`(스트레이트 플러시)처럼 줄임말이라 영어를 그대로 되돌리면 안 되는 자리가 있다.

| 한국어 | English | 日本語 | 简体中文 | 繁體中文 |
|---|---|---|---|---|
| 하이 | High Card | ハイカード | 高牌 | 高牌 |
| 원페어 | One Pair | ワンペア | 一对 | 一對 |
| 투페어 | Two Pair | ツーペア | 两对 | 兩對 |
| 트리플 | Three of a Kind | スリーカード | 三条 | 三條 |
| 스트레이트 | Straight | ストレート | 顺子 | 順子 |
| 플러시 | Flush | フラッシュ | 同花 | 同花 |
| 풀하우스 | Full House | フルハウス | 葫芦 | 葫蘆 |
| 포카드 | Four of a Kind | フォーカード | 四条 | 四條 |
| 스티플 | Straight Flush | ストレートフラッシュ | 同花顺 | 同花順 |
| 로열 스티플 | Royal Straight Flush | ロイヤルストレートフラッシュ | 皇家同花顺 | 皇家同花順 |
| 로우 스티플 | Low Straight Flush | ローストレートフラッシュ | 小同花顺 | 小同花順 |
| 파이브 카드 | Five of a Kind | ファイブカード | 五条 | 五條 |
| 플러시 하우스 | Flush House | フラッシュハウス | 同花葫芦 | 同花葫蘆 |
| 플러시 파이브 | Flush Five | フラッシュファイブ | 同花五条 | 同花五條 |
| 크라운 포카드 | Crown Four of a Kind | クラウンフォーカード | 王冠四条 | 王冠四條 |
| 프리즘 스트레이트 | Prism Straight | プリズムストレート | 棱镜顺子 | 稜鏡順子 |
| 미완성/무득점 | Incomplete / no score | 未完成／得点なし | 未完成／无得分 | 未完成／無得分 |

### 희귀도

| 한국어 | English (초안) | 日本語 (초안) | 简体中文 (초안) | 繁體中文 (초안) |
|---|---|---|---|---|
| 일반 | Common | コモン | 普通 | 普通 |
| 희귀 | Uncommon | アンコモン | 罕见 | 罕見 |
| 레어 | Rare | レア | 稀有 | 稀有 |
| 전설 | Legendary | レジェンダリー | 传说 | 傳說 |

한국어의 `희귀`와 `레어`가 서로 다른 등급이다. 영어로 옮길 때 둘 다 `Rare`가 되지 않게 주의한다.

### 전투 용어

| 한국어 | English (초안) | 日本語 (초안) | 简体中文 (초안) | 繁體中文 (초안) |
|---|---|---|---|---|
| 확정 | Confirm | 確定 | 确定 | 確定 |
| 첫 확정 | First confirm | 最初の確定 | 首次确定 | 首次確定 |
| 손패 | Hand | 手札 | 手牌 | 手牌 |
| 드로우 | Draw | ドロー | 抽牌 | 抽牌 |
| 버림 | Discard | 捨て札 | 弃牌 | 棄牌 |
| 이동 | Move | 移動 | 移动 | 移動 |
| 선택 | Select | 選択 | 选择 | 選擇 |
| 라인 | Line | ライン | 线 | 線 |
| 점수 라인 | Scoring line | 得点ライン | 得分线 | 得分線 |
| 족보 성장 | Hand growth | 役成長 | 牌型成长 | 牌型成長 |
| 약화 | Weaken | 弱体 | 削弱 | 削弱 |
| 금지 | Blocked | 禁止 | 禁止 | 禁止 |
| 안전망 발동 | Safety net | セーフティネット発動 | 安全网触发 | 安全網觸發 |
| 대각 ↘ | Diagonal ↘ | 斜め ↘ | 斜线 ↘ | 斜線 ↘ |
| 대각 ↙ | Diagonal ↙ | 斜め ↙ | 斜线 ↙ | 斜線 ↙ |
| 패배 | Defeat | 敗北 | 失败 | 失敗 |

### Market과 정산

| 한국어 | English (초안) | 日本語 (초안) | 简体中文 (초안) | 繁體中文 (초안) |
|---|---|---|---|---|
| 리롤 | Reroll | リロール | 重掷 | 重擲 |
| 구매 | Buy | 購入 | 购买 | 購買 |
| 판매 | Sell | 売却 | 出售 | 出售 |
| 사용 | Use | 使用 | 使用 | 使用 |
| 슬롯 | Slot | スロット | 槽位 | 槽位 |
| 패시브 | Passive | パッシブ | 被动 | 被動 |
| 무료 | Free | 無料 | 免费 | 免費 |
| Gold 부족 | Not enough Gold | Gold が足りない | Gold 不足 | Gold 不足 |
| 정산 | Cash out | 精算 | 结算 | 結算 |
| 정산 결과 | Cash out result | 精算結果 | 结算结果 | 結算結果 |

### 갈라졌던 표기를 하나로 맞춘 것

같은 개념을 두 가지로 쓰던 자리를 정리했다. 용어집에 결정이 이미 있으면 그 값을 따랐고, 없으면 그때까지 더 많이 쓰인 표기로 맞췄다. 뒤의 두 열은 사용자 검수용이다.

| 개념 | 언어 | 택한 표기 | 버린 표기 | 바뀐 곳 | 근거 |
|---|---|---|---|---|---|
| 확정 | 简体中文 | 确定 | 确认 | 17 | 용어집 전투 용어 |
| 확정 | 繁體中文 | 確定 | 確認 | 17 | 용어집 전투 용어 |
| Royal 족보 | English | Royal Straight Flush | Royal Flush | 2 | 용어집 족보 이름 |
| Royal 족보 | 日本語 | ロイヤルストレートフラッシュ | ロイヤルフラッシュ | 2 | 용어집 족보 이름 |
| 골드 | 日本語 | Gold | ゴールド | 5 | 용어집 기본 개념 |
| 골드 | 简体中文 | Gold | 金币 | 6 | 용어집 기본 개념 |
| 골드 | 繁體中文 | Gold | 金幣 | 6 | 용어집 기본 개념 |
| 점수 | 日本語 | 得点 | スコア | 25 | 용어집 기본 개념·전투 용어 |
| 타일 | 简体中文 | 牌块 | 砖块 | 4 | 다수 표기 (7 대 4) |
| 타일 | 繁體中文 | 牌塊 | 磚塊 | 4 | 다수 표기 (7 대 4) |
| 전투 | 日本語 | バトル | 戦闘 | 8 | 다수 표기 (11 대 8) |
| Station | 日本語 | Station | ステーション | 4 | 다수 표기 (27 대 4) |
| Station | 简体中文 | Station | 站点 | 7 | 다수 표기 (23 대 7) |
| Station | 繁體中文 | Station | 站點 | 7 | 다수 표기 (23 대 7) |
| Market | 日本語 | Market | ショップ | 6 | 다수 표기 (18 대 6) |
| Market | 简体中文 | Market | 商店 | 10 | 다수 표기 (15 대 10) |
| Market | 繁體中文 | Market | 商店 | 10 | 다수 표기 (15 대 10) |

`최고 기록`의 일본어 `ベストスコア`는 이 표의 점수 규칙에서 뺐다. 위의 기본 개념 표가 그 값을 이미 정해 두었기 때문이다.

### 2026-09-20 사용자 결정 (확정)

위 표에서 근거가 `다수 표기`였던 항목은 사용자가 모두 확정했다. 더 이상 검수 대기 항목이 아니다.

1. **`Gold`, `Station`, `Market`은 일본어와 중국어에서 영어로 둔다.** 조각 파일과 데이터 번역 전체에서 `ゴールド`, `ステーション`, `マーケット`, `ショップ`, `金币`, `金幣`, `站点`, `站點`, `市场`, `市場`, `商店`을 영어로 맞췄다.
2. **일본어의 전투는 `バトル`다.** `戦闘`은 쓰지 않는다.
3. **중국어의 타일은 `牌`다.** `牌块`와 `牌塊`는 쓰지 않는다. `牌型`(족보)과 `牌组`·`牌組`(덱)은 그대로 둔다.
4. **영어 낱말 옆의 띄어쓰기**는 아래 규칙을 따른다.

### 영어 낱말 옆의 띄어쓰기

중국어(简体·繁體)는 한자와 영문·숫자 사이에 반각 공백을 한 칸 둔다. 문장부호와 맞닿은 쪽, 문자열의 처음과 끝, `{placeholder}` 안쪽에는 넣지 않는다. 수량사와 백분율 기호는 숫자에 붙인다(`{count}张`, `50%`).

일본어는 붙여 쓰는 것이 기본이다. 예외는 하나로, 영문 고유명사로 시작하는 짧은 라벨만 띄운다(`Station クリア`, `Gold タイル`). 문장 속에서는 붙인다(`Marketの所持エリア`). `得点 xN`과 `得点 x{value}`는 짝이 되는 `得点 +%`가 공백을 유지하므로 함께 띄운 채로 둔다.

### 결정과 근거

`バトル`와 중국어 `牌`는 **2차 의견**으로 TypeSafe Jev(`jev-1.13.0`)에게 물어본 결과를 참고했다. `バトル` 선택 확률은 0.93(confidence 0.91), 중국어 타일 `牌`는 0.76과 0.71이었고, 다만 `牌`가 다른 `牌` 낱말과 혼동될 수 있다는 판정도 0.69와 0.72로 함께 나왔다. 띄어쓰기는 confidence가 0.24에서 0.31로 판정 불가였다. Jev 결과는 확정 근거가 아니라 2차 의견이며, 최종 결정은 사용자가 조판 관례와 현재 다수 표기를 기준으로 내렸다.

### 타일 인장·에디션·기억

| 한국어 | English (초안) | 日本語 (초안) | 简体中文 (초안) | 繁體中文 (초안) |
|---|---|---|---|---|
| 붉은 인장 | Red Seal | 赤の印 | 红色印记 | 紅色印記 |
| 푸른 인장 | Blue Seal | 青の印 | 蓝色印记 | 藍色印記 |
| 성장 각인 | Growth Mark | 成長の刻印 | 成长刻印 | 成長刻印 |
| 라인 각인 | Line Mark | ラインの刻印 | 线刻印 | 線刻印 |
| 금빛 각인 | Gold Mark | 金の刻印 | 金色刻印 | 金色刻印 |
| 메아리 각인 | Echo Mark | 響きの刻印 | 回响刻印 | 迴響刻印 |
| 닻 각인 | Anchor Mark | 錨の刻印 | 锚刻印 | 錨刻印 |
| 균열 각인 | Crack Mark | 亀裂の刻印 | 裂纹刻印 | 裂紋刻印 |
| 은빛 판본 | Silver Edition | 銀の版 | 银版 | 銀版 |
| 빛무늬 판본 | Glow Edition | 光紋の版 | 光纹版 | 光紋版 |
| 다색 판본 | Polychrome Edition | 多色の版 | 多彩版 | 多彩版 |
| 기억 카드 | Memory Card | 記憶カード | 记忆卡 | 記憶卡 |
| 교차 기억 | Crossed Memory | 交差の記憶 | 交叉记忆 | 交叉記憶 |
| 다리 표식 | Bridge Mark | 橋の印 | 桥标记 | 橋標記 |
| 북마크 | Bookmark | ブックマーク | 书签 | 書籤 |

### 타일 색

색 이름은 화면 코드에 `빨간`, `파란`, `노란`, `검은`처럼 문장 안의 꾸밈말로 들어 있다. 단어만 떼어 번역하지 말고 문장 전체를 한 키로 옮긴다. 이유는 [I18N](../core/I18N.md)의 키 이름 규칙에 적혀 있다.

| 한국어 | English (초안) | 日本語 (초안) | 简体中文 (초안) | 繁體中文 (초안) |
|---|---|---|---|---|
| 빨강 | Red | 赤 | 红色 | 紅色 |
| 파랑 | Blue | 青 | 蓝色 | 藍色 |
| 노랑 | Yellow | 黄 | 黄色 | 黃色 |
| 검정 | Black | 黒 | 黑色 | 黑色 |

## 3. 검수할 때 볼 것

- 족보 이름이 포커의 통용 표기와 맞는지. 특히 `스티플`, `로우 스티플`, `크라운 포카드`, `프리즘 스트레이트`처럼 이 게임에만 있는 이름. 한국어 족보 이름의 정본은 `lib/logic/rummi_poker_grid/rummi_settlement_facade.dart`다.
- 희귀도 4단계의 영어 이름이 서로 겹치지 않는지.
- 일본어·중국어의 `Chips`와 `Jester`는 **결정됨: 영어 유지(2026-09-21 사용자 결정)**. `Gold`, `Station`, `Market`의 **결정됨: 영어 유지(2026-09-20 사용자 결정)**도 유지한다. 다섯 용어는 추가 검수 대상이 아니다.
- Item·Jester 이름을 영어 고유명으로 통일한 기존 방식을 유지할지.
