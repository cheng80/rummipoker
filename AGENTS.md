# Agent 코딩 가이드

> 이 파일을 프로젝트에 추가하여 코딩 에이전트가 따라야 할 규칙을 정의합니다.

## 1. 계획 먼저, 승인 후 코딩

- 코드를 작성하기 **전에** 접근 방식을 설명하고 승인을 기다리세요.
- 요구 사항이 모호한 경우, 모든 코드를 작성하기 전에 **반드시** 명확한 질문을 던지세요.
- GDD·체크리스트·`START_HERE.md` 등에 **미정**이거나 **실무적으로 갈래가 나는 스펙**은, 코드·문서에 반영하기 전에 **반드시 사용자에게 확인**받는다. (추측으로 잠정 구현만 하고 넘어가지 않는다. 잠정안이면 그 사실을 명시한다.)

### Goal 기반 자동 진행 예외

- 사용자가 `/goal` 또는 명시적인 장기 목표를 설정하고 **자동 진행**을 승인하면, 에이전트는 목표 달성에 필요한 코드 구현, 테스트, 관련 문서 동기화, 분석·빌드·QA를 매 단계 사전 승인 없이 진행할 수 있다.
- 자동 진행 중에도 큰 작업은 작은 단위로 나누고, 각 단위의 변경 요약·검증 결과·남은 리스크를 응답으로 보고한다.
- 단, 아래 항목은 자동 진행 중에도 사용자 확인을 받는다.
  - 저장 포맷·마이그레이션을 깨뜨릴 수 있는 변경
  - UI/UX 구조를 크게 바꾸는 변경
  - 레벨링·밸런스 핵심 정책 원칙 변경
  - 삭제·복원·force push 등 파괴적 작업
  - 비용이 큰 장기 실행 작업
  - 스펙이 실무적으로 두 갈래 이상으로 갈리는 경우

## 2. 큰 작업은 작게 분해

- 작업이 **3개 이상의 파일**을 변경해야 한다면, 먼저 멈추고 **작은 작업으로 분해**하세요.
- 각 단계를 순차적으로 진행하고, 필요 시 사용자 확인을 받으세요.

## 3. 코드 작성 후 영향 분석

- 코드를 작성한 후, **무엇이 깨질 수 있는지** 나열하세요.
- 이를 커버할 **테스트를 제안**하세요.

## 4. 버그 수정 시 테스트 우선

- 버그가 생기면 **재현하는 테스트를 먼저 작성**하세요.
- 테스트가 통과할 때까지 고치세요.

## 5. 교정 시 규칙 추가

- 사용자가 수정을 요청할 때마다, 이 **AGENTS.md** 파일에 새로운 규칙을 추가하세요.
- 동일한 실수가 다시 발생하지 않도록 하세요.
- 구현·레벨링·연출 방향을 잡을 때는 수정량 최소화보다 게임의 원래 목표에 가까워지는지를 우선한다. 먼저 현재 방향의 숨은 문제와 목표 대비 어긋나는 점을 짚고, 그 다음에 1차 안전 변경과 목표 달성을 위한 확장 실험을 분리해 설계한다.
- 1차 후보는 저장 포맷·UI 변경이 적은 안전한 안을 우선할 수 있지만, 최종 판단을 그 범위에 가두지 않는다. 게임 완성도, 재미의 다양성, 장기 확장성이 Goal에 중요하면 저장 포맷 변경, UI/피드백 변경, 신규 상태 추적이 필요한 과감한 후보도 실험·검증 대상으로 올린다.
- Boss pool, Jester, Item, 보스전, 마켓, 정산 룰을 확장할 때는 기존 family variant와 숫자 penalty 후보만 보지 말고, 파괴·변형·비활성·순서 변경·조건부 제약처럼 플레이 양상을 바꾸는 룰도 함께 검토한다. 단, 유저 선택 강제, 자동 지급, 특정 슬롯 고정 같은 금지 원칙은 유지하고, 필요한 저장/복원/표시/정산 검증 경로를 명시한다.
- 사용자가 **"특정 영역만 Git의 이전 상태와 비교/복원"** 하라고 지시하면, 그 범위만 `git show` 등으로 먼저 확인한 뒤 **지정된 파일/블록만** 되돌린다. 다른 최신 작업본은 추측으로 함께 건드리지 않는다.
- 문서 source-of-truth나 archive 후보를 정리할 때는 `START_HERE.md`의 새 세션 진입 경로와 먼저 읽을 문서 목록을 먼저 맞춘다. 진입 문서에서 아직 current로 읽는 문서를 archive 후보로 먼저 밀어 넣지 않는다.
- 사용자가 작업 순서를 명시했으면 전체 진행표와 응답에서 같은 순서를 유지한다. 특히 `ML 표현 감사/정정 -> 텍스트 자름/줄바꿈 정책 -> START_HERE 기준 문서 진입점/파편화 정리 -> 실제 ML 이행과 리포트 -> 경제 probe 마감 여부 정리 -> 공모전 기준 작업`처럼 gate가 정해진 경우, 뒤 작업을 먼저 진행하거나 실제 ML 이행을 목록에서 누락하지 않는다.
- planned transition scaffold, baseline model, exploratory probe, 연결 보고서는 gate 완료와 다르다. 실제 ML 이행은 모델 추천표와 fresh resimulation, 사람 승인 경계까지 닫혀야 완료로 본다. 경제 probe도 exploratory/not closed이면 공모전 기준 작업 재개 gate로 넘기지 않는다.
- 모든 작업의 “마감”은 런타임 반영과 런타임 검증까지 끝났을 때만 인정한다. 문서 정리, sim-only probe, ML 추천표, offline metric, 후보 설계, 사람 검토용 리포트는 중간 산출물이며, 실제 앱/runtime 동작에 적용되고 저장/복원/시뮬레이션/관련 테스트 경로가 확인되기 전에는 closed/done/완료로 표시하지 않는다. 런타임 적용이 의도적으로 보류된 경우에는 “보류/후보/탐색 완료”로만 적고 “마감”이라고 쓰지 않는다.
- ML 회귀 모델은 MAE, RMSE, R2 같은 평가 지표가 실무 사용 기준에 충분히 좋아야 후보 추천 gate로 인정한다. 현재처럼 R2가 낮거나 데이터가 작거나 RMSE가 빠진 리포트는 “ML 마감”이나 “추천 gate 완료”로 쓰지 않고, 데이터 증량·candidate grid 확장·모델 재평가가 필요한 진행 중 상태로 기록한다.
- ML 지표 점수를 제시할 때는 현재값만 쓰지 않는다. R2처럼 이상값이 명확한 지표는 이상값(예: 1.0)을 함께 쓰고, MAE/RMSE처럼 상한이 없거나 target scale에 의존하는 지표는 이론상 최선(0.0), target 범위, 실무 사용 가능 기준 또는 아직 기준 미정임을 함께 표기한다.
- 사람이 검토하는 ML/레벨링 리포트는 기본 언어를 한국어로 통일한다. 모델명, metric, feature id, 컬럼명, 파일 경로 같은 기술 식별자는 영어를 유지할 수 있지만, 제목·섹션명·판단 문장·결론 문단이 한글/영문/혼합 상태로 흩어지지 않게 생성 스크립트와 산출물을 함께 맞춘다.
- 분석/ML/레벨링 리포트는 Google NotebookLM 같은 외부 요약 도구의 source로 넣어도 바로 쓸 수 있게 작성한다. 항상 문서 최상단에 최종 결론 요약, 핵심 점수/지표, 사용 가능 여부, 다음 액션을 먼저 두고, 그 뒤에 일반 리포트 형식의 범위·데이터셋·방법·결과·해석·산출물·제한을 배치한다.
- NotebookLM용 보고서/인포그래픽 재생성은 ML 지표가 실무 사용 수준에 도달한 뒤에만 진행한다. 지표가 부족한 동안에는 canonical report에 “NotebookLM source로 쓰기 전 단계”임을 명시하고, 외부 발표용 재가공보다 데이터 증량·candidate grid 확장·모델 품질 개선을 우선한다.
- 레벨링·경제·ML 실험 결과를 보고할 때는 내부 약어만 나열하지 않는다. `r80`, `none`, `v9`, `balanced`, `power`, `S8 boss`, `candidate`, `gate`, `병목`, `흔들림` 같은 용어는 처음 참가자도 이해할 수 있게 “무엇을 뜻하는지”, “왜 비교하는지”, “실제 게임 플레이에서는 어떤 문제인지”, “그래서 다음 결정이 무엇인지”를 쉬운 문장으로 풀어 설명한다. 단, 설명은 장문으로 늘리지 말고 결론 1문장, 핵심 숫자 1~3개, 다음 판단 1문장 수준으로 최대한 짧게 정리한다.
- exploratory probe, r80/r120, scaffold, 문서 반영은 gate 완료가 아니다. 실제로 문제가 남아 있으면 `Done`, `[x]`, `closed`, `재개 조건 충족`처럼 읽히는 표시를 쓰지 않고 `open`, `not closed`, `보류`, `[ ]`로 남긴다.

---

## Flutter 앱 개발 원칙

- **간결함**: 요구 사항에 맞춰 작성하고, 오버스펙을 피한다.
- **초급자 관점**: 이 앱을 이어 받을 팀원이 초급이라고 가정한다. 복잡한 로직보다 **이해도와 가독성**을 우선한다.
- **한글 주석**: 핵심 기능에는 항상 간결한 한글 주석을 작성한다.
- **UI 모듈화**: 반복되거나 화면이 복잡해지는 부분은 모듈/클래스/함수로 분리한다.
- **MVVM 패턴**: `view`에는 UI 제어 로직만 둔다. 그 외 로직은 `vm` 폴더의 ViewModel로 분리한다.

---

## Flutter 실행 환경

- **우선 기기**: iOS 시뮬레이터 (모바일 앱 우선 개발)
- **우선 모드**: Debug (run보다 debug 우선)
- macOS/웹은 보조용

## 반응형 레이아웃 (세로·iPhone / iPad)

- **폰 기준 세로 UI + 태블릿에서 가로 여백·배경만 확장**하는 패턴은 `docs/OLD/DESIGN.md`의 responsive frame 규칙을 따른다.
- 새 화면·`GameWidget` 래퍼를 만들 때 배경과 콘텐츠 프레임을 분리하고, 논리 해상도·`FittedBox`·`MediaQuery` 덮어쓰기 적용 여부를 그 문서와 맞출 것.

---

## 네이밍 (vm 폴더)

- **Handler**: DB/저장소 접근 전담 (예: DatabaseHandler, TagHandler)
- **Notifier**: Riverpod 상태 관리 (예: TodoListNotifier, TagListNotifier)
- Repository 용어는 Git과 혼동되므로 사용하지 않는다.

## Riverpod

- **`riverpod_annotation` / `build_runner` 코드젠은 도입하지 않는다.** `Notifier`·`NotifierProvider` 등은 수동 선언한다.

---

## UI 코딩 규칙

- **Row/Column 동일 간격**: `SizedBox` 대신 `spacing` 파라미터를 사용한다. (위젯 태그 과다 방지)
- **게임 설명 텍스트 말줄임표 금지**: 전투/상점/정보 패널의 설명 문구는 `TextOverflow.ellipsis`로 숨기지 않는다. 문구를 줄이기 전에 리스트/보조 영역을 줄여 설명 공간을 먼저 확보하고, 긴 팝업 설명은 내부 스크롤로 읽을 수 있게 한다.
- **게임 UI 텍스트 숨김 금지**: 게임 화면에 들어가는 `Text`는 이름·라벨·숫자·설명 여부와 관계없이 `TextOverflow.ellipsis`나 `TextOverflow.clip`로 숨기지 않는다. 공간이 부족하면 먼저 레이아웃 공간을 더 확보하거나 공백 기준 줄바꿈·스크롤 가능한 상세 영역으로 처리한다. 단, HUD 숫자·짧은 버튼·상태 배지처럼 고정 면적에서 값이 흔들리는 UI는 의도를 확인하고 `FittedBox.scaleDown`을 사용할 수 있다. `FittedBox.scaleDown`을 쓴 구간이라도 실제 플레이/QA에서 시인성이 떨어지면 추후 폰트 축소가 아니라 레이아웃 공간 확보 방향으로 다시 수정한다.
- **상점 뱃지 중복·잘림 방지**: Offer 카드 상단 뱃지는 상세 패널 태그와 같은 정보를 반복하지 않는다. Q-Slot처럼 짧은 카드 뱃지도 `TextOverflow.ellipsis`로 줄이지 말고, 짧은 표기나 고정 폭 조정으로 전체가 보이게 한다. 패시브형은 `P` 슬롯 문맥과 연결되는 `PSV` 표기를 사용한다.
- **상점 카드 통일성**: Jester/Item offer 카드는 되도록 같은 카드 골격, 중앙 정렬, 같은 가격 위치를 사용한다. 구분은 카드 형태 자체가 아니라 타입 배지, rarity 색, 테두리/작은 점으로 처리한다.
- **콘텐츠 네이밍 독자성**: Jester/Item/Slot/Stage tier/Boss 같은 플레이어 노출 명칭은 참고작의 고유 명칭을 그대로 가져오지 않는다. 기존 저장 ID는 호환성 때문에 유지할 수 있지만, 표시명과 설명 문구는 게임의 룰·세계관·사용 맥락에 맞게 별도로 작성한다.
- **Jester 명칭 유지**: `Jester`는 이 게임의 고유 용어로 유지한다. IP/네이밍 정리 대상은 `Joker` 원명, `Green/Jolly/... Joker`에서 온 조합명, 또는 그 조합을 단순히 `Jester`로 치환한 표시명과 설명 문구다. `Jester` 단어 자체를 금지하거나 억지로 다른 말로 바꾸지 않는다.
- **효과 설명 명확성**: 카드·아이템·보스·정산 설명은 분위기 문구보다 실제 기능 이해를 우선한다. “언제 발동하는지”, “무엇이 얼마나 바뀌는지”, “이번 전투/이번 스테이션/다음 상점 중 어디까지 지속되는지”가 짧게 읽혀야 한다.
- **출품용 다국어 기준**: 플레이어에게 노출되는 카드명·아이템명·효과 설명·상점/전투/정산 문구는 출품 시점에 최소 한국어와 영어를 함께 지원할 수 있게 번역 키 기준으로 관리한다. 일본어·중국어는 시간이 허용되면 같은 키 구조로 확장하되, 먼저 한/영 문구의 의미와 길이를 잠근다.
- **상점 장착 카드 통일성**: 구매 후 Q-Slot/Passive/Tool/Gear 슬롯에 장착된 카드도 offer 카드와 같은 카드 골격을 유지한다. 슬롯 종류 구분은 기존 슬롯 상단 제목 바와 맞춘 라벨·색상으로만 표현하고, 장착 후 별도 박스 디자인으로 바꾸지 않는다.
- **상점 구매 비행 카드 통일성**: 구매 연출로 날아가는 카드도 납작한 임시 카드가 아니라 offer 카드와 같은 카드 골격을 사용한다. 이동·스케일·글로우는 허용하되, 카드 형태 자체를 바꾸지 않는다.
- **상점 구매 비행 중 빈 자리 표현**: 구매 비행 중에는 런타임 상태가 이미 다음 offer/장착 상태로 갱신됐더라도 출발 가판 칸과 도착 슬롯 칸을 presentation 상 빈 자리처럼 보여준다. 교체 offer나 장착 완료 카드는 비행 완료 후에만 보여준다.
- **상점 구매 비행 고스트 금지**: 구매 비행 카드는 하단 가판의 실제 카드가 이동하는 것처럼 끝까지 불투명하게 보여준다. 도착 전 fade-out, 반투명 잔상, 별도 고스트 복제처럼 보이는 연출은 쓰지 않는다.
- **상점 offer 종류 분리**: 하단 offer 가판은 구매 맥락이 다른 후보를 한 pager에 섞지 않는다. Jester/Q-Slot/Passive/Tool/Gear처럼 슬롯·구매 목적이 다른 offer는 탭 또는 lane으로 분리하고, 리롤도 유저가 보고 있는 offer 종류 기준으로 동작하게 한다.
- **상점 리롤 확인 대상 표시**: 상점 리롤 확인 dialog는 사용자가 현재 보고 있는 offer lane 이름(Jester/Q-Slot/Passive/Tool/Gear)을 문구에 명시해, 어떤 후보 묶음을 리롤하는지 혼동되지 않게 한다.
- **카드/아이템 이름 줄바꿈**: 상점·전투·보유 슬롯의 카드/Jester/아이템 이름은 공용 이름 텍스트 위젯을 사용해 공백 기준 자연 줄바꿈을 우선한다. 이름을 임의로 `\n` 삽입하거나 `TextOverflow.ellipsis`/`TextOverflow.clip`로 숨기지 않고, 공간 부족을 이유로 폰트를 자동 축소하지 않는다. 공간이 부족하면 카드 내부 이름 영역을 키운다.
- **상점 슬롯 상태 가시성**: 구매 후 배치되는 슬롯 칸 자체에는 타입 배경색을 강하게 깔지 않는다. 비어 있음/잠김/장착됨 상태가 우선이며, 타입 색은 슬롯 묶음 컨테이너의 제목 라벨처럼 상태와 충돌하지 않는 영역에만 사용한다.
- **상점 아이템 재판매**: 슬롯 수가 제한된 Q-Slot/Passive/Tool/Gear/Inventory 아이템은 Jester처럼 재판매할 수 있어야 한다. 사용 가능한 아이템도 `사용`만 노출하지 말고 `판매` 선택지를 함께 제공한다.
- **상점 아이템 판매 연출**: 아이템 판매 시 슬롯 카드가 즉시 사라지는 것만으로 끝내지 말고, 해당 카드가 슬롯에서 골드 HUD 쪽으로 이동하고 획득 골드가 표시되는 피드백을 제공한다.
- **정산 피드백 안정성**: Jester/Item 발동 callout은 타원형 pill보다 직사각형 패널을 우선하고, HUD container 자체를 scale/translate하지 않는다. 여러 발동 효과는 가능한 한 그룹으로 묶어 정산 시간이 선형으로 늘지 않게 한다.
- **보스/제약 표시 가시성**: 전투 중 제약 대상은 작은 점이나 단독 `!` 아이콘만으로 표시하지 않는다. 점수 영향이 즉시 읽히는 각진 배지와 높은 대비를 사용한다. 보스/제약 설명 문구도 `TextOverflow.ellipsis`로 숨기지 않는다.
- **타일 위 제약 배지 배치**: 보스/제약 배지는 보드·손패 타일의 숫자와 색상 바를 가리면 안 된다. 배지가 필요한 경우 타일 값 판독 영역을 피하거나, 상위 레이아웃 여백을 조정해 타일 자체 크기를 확보한다.
- **보스 제약 표시 범위**: 색상 타일 약화처럼 특정 타일에 직접 걸리는 제약만 타일 위에 표시한다. 가로줄·세로줄·대각선 약화처럼 라인 종류에 걸리는 제약은 개별 타일 배지로 표시하지 않고, 보스 팝업·라인/정산 표시에서 설명한다.
- **보스 preview 강조 범위**: 색상/그림 타일 약화가 포함된 족보 라인을 preview할 때, 약화 대상이 아닌 같은 라인의 다른 타일까지 제약 강조색으로 칠하지 않는다. 실제 약화 대상 타일만 강조하고 정산 penalty 계산은 별도로 유지한다.
- **웹 스크롤바 숨김**: 웹 빌드에서는 스크롤 가능한 화면이라도 기본 브라우저/Flutter 스크롤바가 보이지 않게 전역 ScrollBehavior에서 처리한다. 스크롤 자체와 마우스/터치 드래그 입력은 유지한다.
- **임시 디버그 픽스처 정리**: 특정 버그 확인용 임시 fixture를 제거할 때는 fixture 상수, registry 등록, builder, 해당 테스트를 함께 삭제한다. 다른 공용 디버그 fixture는 건드리지 않는다.
- **저장 상태와 연출 상태 분리**: Battle/Market/Settlement 모두 확정된 게임 결과와 저장 데이터가 정답이다. 애니메이션, HUD/골드 표시 지연값, reveal 상태, 선택/오버레이 상태는 transient presentation state로 두고 저장/이어하기 기준에 포함하지 않는다.
- **연출 timing 중앙화**: Battle/Market/Settlement 연출의 `Duration`, stagger, hold delay는 `lib/views/game/game_presentation_timings.dart`의 `GamePresentationTimings` 또는 `GamePresentationCue`에 먼저 이름 붙여 추가한다. 화면 파일에 `Duration(milliseconds: ...)`, `Duration(seconds: ...)`, `.ms` 숫자 literal을 새로 흩뿌리지 않는다.
- **전략 후보 노출 금지**: UI/UX 보강은 후보·추천·정답을 직접 알려주는 방식으로 하지 않는다. 마켓 후보, 성장 축, 필요한 선택지를 유저에게 알려주는 것은 시험 문제 유출처럼 전략성을 해치므로 금지한다. 보강은 타일 이동, 카드/아이템 구매 이동, 정산 액션, 보스 제약 발동처럼 게임적 애니메이션과 피드백으로 표현한다.
- **무료/할인 정책 표시**: 리롤·구매·보상 같은 경제 행동이 무료이거나 할인될 때는 UI 문구에서 이유와 조건을 짧게 보여준다. `리롤 0`처럼 이유 없는 무료로 보이게 하지 않고, “첫 리롤 무료”, “아이템 효과 할인”처럼 플레이어가 납득할 수 있는 맥락을 제공한다.
- **정산 완료 시트 라인 등장 방향**: 정산 완료 bottom sheet의 보상 라인은 위에서부터 순차적으로 생기게 한다. 아래에서 생겨 위로 올라가는 연출은 시선을 분산시키므로 쓰지 않는다.
- **정산 완료 시트 크기 안정성**: 정산 완료 bottom sheet는 표시 시작 시 최종 높이를 미리 잡아 둔다. 라인 reveal 때문에 시트 자체 높이가 커지거나 아래 내용이 위로 밀려 올라오는 연출처럼 보이면 안 된다.
- **정산 완료 시트 진입 안정성**: 정산 완료 bottom sheet route 자체도 아래에서 위로 밀고 올라오는 기본 진입 애니메이션을 쓰지 않는다. 시트는 최종 크기로 바로 자리 잡고, 내부 보상 라인만 위에서부터 순차적으로 나타난다.
- **진행 중 피드백 처리**: 사용자가 작업 중간에 새 의견을 주더라도 `우선`, `먼저`, `중단하고`, `이거부터`처럼 즉시 전환 의도가 분명하지 않으면 현재 작은 작업 단위를 먼저 마무리하고 새 의견은 다음 큐로 다룬다. 즉시 전환 여부가 애매하면 짧게 확인한다.
- **일시정지/옵션 창 닫힘 경로**: 게임 일시정지·옵션 dialog는 바깥 dim 영역 탭으로 닫히면 안 된다. 닫기 `X`, 설정/나가기/재시작 같은 명시 액션으로만 닫히게 한다.
- **손패 제거 연출 방향**: 손패에서 빠지는 타일은 아래로 떨어뜨리지 않는다. 보드가 손패 위에 있으므로 제거 피드백은 위쪽으로 살짝 떠오르며 fade-out 되는 방향을 우선한다.
- **손패 드로우 진입 방향**: 새로 드로우된 손패 타일은 기존처럼 손패 영역 오른쪽 바깥에서 슬롯으로 들어오게 한다. 드로우 버튼이 왼쪽에 있어도 왼쪽 진입으로 바꾸면 손패 정렬 흐름과 어긋나므로 사용하지 않는다.
- **플레이어 문구와 응답 언어**: 새로 쓰는 플레이어 노출 문구와 작업 설명에는 `압박`, `흔들림`처럼 내부 분석 리포트에서 쓰는 표현을 피한다. 기본 난이도 다음에 열리는 더 어려운 선택지는 `도전`처럼 자연스러운 플레이어 언어를 우선한다.
- **플레이어 표시명 자연어 우선**: 카드/아이템/도감/새 run 화면의 플레이어 노출 문구는 `계약`, `해금 요소`, `보강`, `감쇠`, `계수기`, `중계기`처럼 기획서·분석표·기계 장치 조합명처럼 읽히는 말을 피하고, 짧고 일반적인 게임 표현을 우선한다. 내부 id나 개발 문서 전용 용어는 플레이어에게 보이지 않으면 무리하게 바꾸지 않는다.
- **난이도 식별자 변경 호환성**: 사용자 배포 후 난이도 enum/id를 바꿀 때는 route 파서, 저장된 unlock/clear key, 시뮬 CLI 입력, 리포트 정렬/feature multiplier에서 기존 문자열 alias를 유지하거나 명시적으로 마이그레이션한다. 배포 전 정리라면 브라우저 저장을 지우고 새 canonical id로 통일할 수 있다.
- **체크리스트 완료 기준 분리**: static placeholder 화면, debug fixture 보조 QA, 실제 자연 플레이 흐름, 저장/복원까지 포함한 런타임 구현은 서로 다른 증거로 기록한다. 도감처럼 수집/발견/구매/보상/보스/스테이지 이력이 핵심인 기능은 임시 항목이 화면에 보인 것만으로 `[x]` 처리하지 않고, 실제 상태 저장과 복원 검증이 끝난 뒤에만 완료로 닫는다.
- **도감 수집 화면 기준**: 도감은 요약 기록 목록이 아니라 수집 공간이다. 이미 모은 Jester/Item/기억 카드 등은 실제 카드/아이템 face로 보여주고, 아직 모으지 못한 항목도 같은 위치와 크기의 빈칸으로 남겨 전체 중 얼마나 남았는지 한눈에 보이게 한다.
- **도감 배치 기준**: 도감 항목은 긴 세로 나열보다 페이지 단위 grid를 우선한다. 카드 칸은 중앙 정렬하고, 항목 사이 간격을 충분히 둬서 수집판처럼 읽히게 한다.
- **도감 플레이어 노출 범위**: 도감 화면에는 수집 대상과 수집 현황을 우선 노출한다. Boss/Station 클리어 id, 진행 기록, 내부 QA용 저장 검증 정보처럼 플레이어가 수집물로 느끼기 어려운 정보는 저장하더라도 도감 본문에 그대로 보이지 않게 한다.
- **도감 중복 요약 제거**: Jester/Item 구매 여부처럼 이미 수집 grid에서 실물 카드와 빈칸으로 읽히는 정보는 별도 텍스트 목록으로 반복하지 않는다.
- **도감 상세 정보 표시**: 도감 카드/아이템을 눌렀을 때는 팝업을 띄우지 말고, 해당 수집판 아래에 접을 수 있는 상세 패널을 펼친다. 다른 항목을 누르면 같은 패널의 내용이 바로 바뀌어야 한다.
- **페이지형 카드 정렬**: 도감과 마켓처럼 페이지 단위로 카드를 보여주는 UI는 전체 페이지 구역을 중앙에 두되, 페이지 안의 카드들은 중앙 몰림 없이 좌측 기준으로 채운다. 마지막 페이지에 1~2장만 남아도 카드가 가운데로 떠 보이면 안 된다.
- **도감 상태 표기**: 도감 항목은 `미발견`, `발견`, `획득`, `클리어` 같은 짧은 상태를 카드 칸과 상세 패널에서 구분한다. 상태 배지는 카드 face를 가리지 않게 카드 상단 또는 하단의 별도 라벨 영역에 둔다.
- **도감 상태 라벨 배치**: 도감 상태 라벨은 수집 카드 face 위에 오버레이하지 않는다. 카드 칸의 별도 상단/하단 라벨 영역에 두고, 라벨 폭은 긴 문구를 대비해 카드 폭보다 조금 짧은 고정 폭으로 잡으며 텍스트와 라벨 위치를 가운데 정렬한다.
- **도감 카드 선택 범위**: 도감 카드의 선택/탭 영역과 선택 테두리는 카드 face에만 적용한다. 상태 라벨은 카드 칸에 붙어 보이더라도 선택 대상에 포함하지 않는다.

---

## 주석 규칙

- 주석은 **한글**로 작성한다.
- 코드가 하는 일을 그대로 옮기는 주석은 달지 않는다. ("이게 뭔가", "왜 이렇게 하나", "어떻게 동작하나"에 해당할 때만 작성)
- 클래스/mixin의 **역할과 존재 이유**를 간결하게 설명한다.
- 의도가 드러나지 않는 로직에는 **의도(why)**를 적는다.
- 그림 문자(이모지)는 사용하지 않는다. (디버깅 시 구분 용도로만 허용)
- "초보자용", "쉽게 설명하면" 같은 문구는 넣지 않는다.

---

## Flame 게임 성능 규칙

### 원칙

- Flame(`GameWidget`)과 Flutter 위젯은 **같은 프레임 예산을 공유**한다. 한쪽이 무거우면 다른 쪽도 FPS가 떨어진다.
- 사용자가 지시한 내용이 **성능 하락을 유발할 수 있는 구조**라면, 바로 작업하지 말고 **문제점과 개선책을 먼저 제안**한다.

### Flutter 위젯 + GameWidget 혼용 시 주의사항

- **정적 위젯**(AppBar, 고정 버튼 등)은 GameWidget과 함께 써도 성능 영향 없다.
- **실시간 갱신 위젯**(매 프레임 setState/rebuild)을 GameWidget 위에 올리면 성능 저하 원인이 된다.
  - 실시간 HUD(점수, 체력 등)는 Flame 내부 `TextComponent`/`SpriteComponent`로 처리하거나 오버레이로 분리한다.
- 복잡한 위젯(블러, 그라데이션 애니메이션 등)이 매 프레임 repaint되지 않도록 한다.

### 권장 패턴

| 패턴 | 설명 |
|------|------|
| 정적 레이어 | 자주 바뀌지 않는 UI는 Flutter 위젯으로 (rebuild 최소화) |
| Flame 오버레이 | 게임 위 팝업/메뉴는 `overlayBuilderMap`으로 관리 |
| RepaintBoundary | Flame 영역과 UI 영역을 분리해 불필요한 repaint 차단 |
| 게임 내부 HUD | 실시간 정보는 Flame 컴포넌트로 처리, 앱 UI는 Flutter로 |

---

## 문서화

- 사용자가 **문서화해 달라고 요청하기 전까지** `.md` 파일을 작성하지 않는다.
- 설계, 플랜, 요약 등은 응답으로만 보여주고, 파일로 저장하지 않는다.
- 여러 PC에서 같은 repo를 관리하므로, 문서와 응답의 repo 내부 파일 경로는 **repo root 기준 상대경로**로 적는다. 절대경로는 사용자가 명시했거나 로컬 실행 명령에 꼭 필요할 때만 쓴다.
- repo 외부 참고 프로젝트는 PC마다 위치가 다를 수 있으므로 문서에 사용자 홈·바탕화면·드라이브 문자로 시작하는 로컬 절대경로를 고정하지 않는다.

## 분석 노트북/리포트

- 노트북에서 Markdown 리포트를 인라인 표시할 때, 이미지 링크는 저장 파일 기준이 아니라 **노트북 파일 위치 기준**으로 다시 매핑해 깨지지 않게 한다.
- 규칙 기반 라벨링·휴리스틱 리포트에는 “ML 학습/검증”처럼 오해될 이름을 쓰지 않는다. train/test/validation split, 모델, metric이 없으면 그 사실을 리포트와 노트북에 명시한다.
- 레벨링 ML을 만들 때는 규칙 label 모방이 아니라 피처, supervised target, train/test split, metric, 모델 선택 근거, 데이터 부족 시 추가 실험안을 함께 설계한다.
- 규칙 기반 휴리스틱 라벨링이나 시뮬레이션 리포트를 실제 머신러닝 적용처럼 표현하지 않는다. 학습 모델, train/test split, metric, feature importance가 없는 단계는 “시뮬레이션 기반 분석” 또는 “휴리스틱 진단”으로 부른다.
- 실제 ML 전환 시에도 모델 추천은 런타임 자동 적용이 아니라 후보 추천, 재시뮬레이션 검증, 사람 승인 후 적용 순서로 다룬다.
- 레벨링 sweep 데이터는 특정 병목(예: Boss)만 보지 말고, 기존 기준값을 만든 과정의 station curve, small/big/boss tier, difficulty, loadout, market profile 맥락을 함께 보존한다.
- 초반 보정은 무료 아이템이나 숨은 기본값 하향으로 처리하지 않는다. 필요하면 시스템 명분이 있는 첫 클리어 골드 보상처럼, 유저가 이후 상점에서 직접 성장 선택을 할 수 있는 자원으로 표현한다.
- 레벨링은 특정 성장 루트를 유저에게 보장하거나 강제하는 작업이 아니다. 우리가 정할 수 있는 것은 target score, 등장 weight, 범위, 병목 허용치이며, 테스트한 성장은 유저가 그 성장 방식을 선택했을 때의 best-case 후보로만 해석한다.
- 레벨링 압박은 어느 정도 필요하지만, 이상적인 플레이와 좋은 구매 선택을 한 proxy가 같은 조건의 none/control보다 손해를 보면 안 된다. market 후보 조정은 압박 제거가 아니라 좋은 선택의 통과 가능성을 확보하는 방향으로 검증한다.
- S1~S8 난이도 곡선은 초반 전체를 쉽게 만드는 것이 아니라 단계별 역할을 분명히 한다. S1은 거의 누구나 깨는 입구, S2는 성장이 있으면 쉽고 성장이 없으면 간신히 통과하는 구간, S3부터는 성장이 없으면 확실히 막히는 구간, S4~S6은 성장 선택 검증이 점차 강해지는 구간, S7~S8은 깨는 비중이 더 낮아야 하는 고난도 후반 구간으로 본다.
- 로그라이트 영구 성장에 맞춰 목표 점수와 보상도 조정할 수 있다. 단, 숨은 자동 완화/강화가 아니라 플레이어가 선택한 난이도, 계약, 시작 변형, 해금된 pool 같은 명시적 run modifier로 target score와 reward formula가 함께 움직여야 한다.
- 전체 레벨링 기준값 재검증은 사용자가 명시하지 않는 한 기존 장기 sweep 수준의 runs를 임의로 줄이지 않는다. 빠른 probe가 필요하면 “판단용이 아닌 탐색용”임을 문서와 응답에 분리해 적는다.
- board discard, hand discard, max hand size 같은 자원 +1은 자동 보정이나 무료 지급 기준 후보로 삼지 않는다. 그런 수치가 필요하다는 sweep 결과는 “유저가 상점에서 구매해야 할 성장 수요”로 해석하고, 실제 적용 방향은 market weight, 가격, 후보 노출, bot/user 선택 proxy로 검증한다.
- 아이템/Jester/Pack/Tarot/Planet 후보는 마켓에 등장 가능하게 만드는 것이 레벨링의 역할이다. 게임이 직접 구매·장착·사용을 대신해 유저를 돕지 않는다. 시뮬 bot 선택은 유저 선택 성향을 재현하는 proxy일 뿐이며, 실제 적용 기준은 candidate availability와 등장 weight다.
- S1 첫 클리어 보너스 골드 외에는 유저에게 공짜 지급이 없다. 레벨링은 특정 단계에서 위로 올라갈 수 있는 상점 후보의 가중치와 노출 가능성을 조정할 수 있지만, 아이템·카드·덱 타일·보드/손패 버리기·손패 크기·슬롯을 자동 지급하거나 숨은 기본값으로 보정하지 않는다.
- 게임은 유저의 선택을 대신하지 않는다. 구매·판매·장착·사용은 모두 유저의 선택이며, 시스템의 역할은 어떤 선택을 하더라도 게임이 무너지지 않도록 target score, boss constraint, market candidate availability, rarity/tag/category/slot weight, 병목 허용치로 받치는 것이다.
- 필요한 후보가 마켓에 등장했다면, 기존 아이템을 팔고 슬롯을 비워 구매할지는 유저 선택으로 본다. 슬롯 부족 자체를 레벨링 병목으로 해석하지 않고, 분석 기준은 후보 노출 여부와 가격/골드 구매 가능성까지로 제한한다.
- 해당 구간까지 유저가 필요한 성장 축을 아직 얻지 못한 경우 확률 보정은 허용한다. 단, 보정은 직접 지급이 아니라 마켓 등장 확률·슬롯 노출 확률 조정으로만 구현한다.
- 마켓 확률 보정이 특정 슬롯 위치를 고정해서는 안 된다. 필요한 후보 노출을 보정하더라도 offer slot 위치는 stage/reroll/rng에 따라 흔들어, 유저에게 “항상 같은 자리에 뜬다”는 인상을 주지 않는다.
- 실험은 목표를 좁혀 완성하기 위한 수단이다. 새 실험을 추가할 때는 어떤 판단을 닫기 위한 것인지, 어느 정도 runs/샘플이면 방향과 규모를 판가름할지, 결과 후 어떤 구현 결정으로 돌아갈지 먼저 정한다. 실험이 계속 늘어나 완성에서 멀어지면 안 된다.
- 장기 목표 작업에는 상세 문서와 별도로 전체 진도표를 유지한다. 전체 진도표에는 경제/레벨링뿐 아니라 UI/UX/연출, 로그라이트 메타 성장, 게임오버 보상 루프, QA/릴리즈 gate를 포함해 현재 작업이 전체 완성에서 어디에 해당하는지 보이게 한다.

---

## 추가 참고

- **언어**: 모든 응답은 한국어로 작성합니다.
- **출처**: [@svpino - X/Twitter](https://x.com/svpino/status/2018682144361734368)

<!-- BEGIN GSTACK-CODEX MANAGED BLOCK -->
## gstack — AI Engineering Workflow

This block is managed by `gstack-codex`. Do not edit inside this block.

Skills live in `.agents/skills`. Invoke them by name, e.g. `/office-hours`.
Refresh with `npx gstack-codex init --project`.
This repo currently has the `full` pack installed.

## Available skills

| Skill | What it does |
|-------|-------------|
| `/office-hours` | YC Office Hours — two modes. Startup mode: six forcing questions that expose demand reality, status quo, desperate specificity, narrowest wedge, observation, and future-fit. |
| `/plan-ceo-review` | CEO/founder-mode plan review. Rethink the problem, find the 10-star product, challenge premises, expand scope when it creates a better product. |
| `/plan-eng-review` | Eng manager-mode plan review. Lock in the execution plan — architecture, data flow, diagrams, edge cases, test coverage, performance. |
| `/plan-design-review` | Designer's eye plan review — interactive, like CEO and Eng review. |
| `/design-consultation` | Design consultation: understands your product, researches the landscape, proposes a complete design system (aesthetic, typography, color, layout, spacing, motion), and generates font+color preview pages. |
| `/review` | Pre-landing PR review. Analyzes diff against the base branch for SQL safety, LLM trust boundary violations, conditional side effects, and other structural issues. |
| `/investigate` | Systematic debugging with root cause investigation. Four phases: investigate, analyze, hypothesize, implement. |
| `/design-review` | Designer's eye QA: finds visual inconsistency, spacing issues, hierarchy problems, AI slop patterns, and slow interactions — then fixes them. |
| `/qa` | Systematically QA test a web application and fix bugs found. |
| `/qa-only` | Report-only QA testing. Systematically tests a web application and produces a structured report with health score, screenshots, and repro steps — but never fixes anything. |
| `/ship` | Ship workflow: detect + merge base branch, run tests, review diff, bump VERSION, update CHANGELOG, commit, push, create PR. |
| `/document-release` | Post-ship documentation update. Reads all project docs, cross-references the diff, updates README/ARCHITECTURE/CONTRIBUTING/CLAUDE.md to match what shipped, polishes CHANGELOG voice, cleans up TODOS, and optionally bumps VERSION. |
| `/retro` | Weekly engineering retrospective. Analyzes commit history, work patterns, and code quality metrics with persistent history and trend tracking. |
| `/browse` | Fast headless browser for QA testing and site dogfooding. Navigate any URL, interact with elements, verify page state, diff before/after actions, take annotated screenshots, check responsive layouts, test forms and uploads, handle dialogs, and assert element states. |
| `/setup-browser-cookies` | Import cookies from your real Chromium browser into the headless browse session. |
| `/careful` | Safety guardrails for destructive commands. Warns before rm -rf, DROP TABLE, force-push, git reset --hard, kubectl delete, and similar destructive operations. |
| `/freeze` | Restrict file edits to a specific directory for the session. |
| `/guard` | Full safety mode: destructive command warnings + directory-scoped edits. |
| `/unfreeze` | Clear the freeze boundary set by /freeze, allowing edits to all directories again. |
| `/gstack-upgrade` | Upgrade gstack to the latest version. Detects global vs vendored install, runs the upgrade, and shows what's new. |
| `/autoplan` | Auto-review pipeline — reads the full CEO, design, eng, and DX review skills from disk and runs them sequentially with auto-decisions using 6 decision principles. |
| `/benchmark` | Performance regression detection using the browse daemon. Establishes baselines for page load times, Core Web Vitals, and resource sizes. |
| `/benchmark-models` | Cross-model benchmark for gstack skills. Runs the same prompt through Claude, GPT (via Codex CLI), and Gemini side-by-side — compares latency, tokens, cost, and optionally quality via LLM judge. |
| `/canary` | Post-deploy canary monitoring. Watches the live app for console errors, performance regressions, and page failures using the browse daemon. |
| `/context-restore` | Restore working context saved earlier by /context-save. Loads the most recent saved state (across all branches by default) so you can pick up where you left off — even across Conductor workspace handoffs. |
| `/context-save` | Save working context. Captures git state, decisions made, and remaining work so any future session can pick up without losing a beat. |
| `/cso` | Chief Security Officer mode. Infrastructure-first security audit: secrets archaeology, dependency supply chain, CI/CD pipeline security, LLM/AI security, skill supply chain scanning, plus OWASP Top 10, STRIDE threat modeling, and active verification. |
| `/design-html` | Design finalization: generates production-quality Pretext-native HTML/CSS. |
| `/design-shotgun` | Design shotgun: generate multiple AI design variants, open a comparison board, collect structured feedback, and iterate. |
| `/devex-review` | Live developer experience audit. Uses the browse tool to actually TEST the developer experience: navigates docs, tries the getting started flow, times TTHW, screenshots error messages, evaluates CLI help text. |
| `/health` | Code quality dashboard. Wraps existing project tools (type checker, linter, test runner, dead code detector, shell linter), computes a weighted composite 0-10 score, and tracks trends over time. |
| `/land-and-deploy` | Land and deploy workflow. Merges the PR, waits for CI and deploy, verifies production health via canary checks. |
| `/learn` | Manage project learnings. Review, search, prune, and export what gstack has learned across sessions. |
| `/make-pdf` | Turn any markdown file into a publication-quality PDF. Proper 1in margins, intelligent page breaks, page numbers, cover pages, running headers, curly quotes and em dashes, clickable TOC, diagonal DRAFT watermark. |
| `/open-gstack-browser` | Launch GStack Browser — AI-controlled Chromium with the sidebar extension baked in. |
| `/pair-agent` | Pair a remote AI agent with your browser. One command generates a setup key and prints instructions the other agent can follow to connect. |
| `/plan-devex-review` | Interactive developer experience plan review. Explores developer personas, benchmarks against competitors, designs magical moments, and traces friction points before scoring. |
| `/plan-tune` | Self-tuning question sensitivity + developer psychographic for gstack (v1: observational). |
| `/setup-deploy` | Configure deployment settings for /land-and-deploy. Detects your deploy platform (Fly.io, Render, Vercel, Netlify, Heroku, GitHub Actions, custom), production URL, health check endpoints, and deploy status commands. |

Repo installs include the full generated skill pack. Heavy browser/runtime binaries stay machine-local in v1.
Installed release: `0.2.0`
<!-- END GSTACK-CODEX MANAGED BLOCK -->
