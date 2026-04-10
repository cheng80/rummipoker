import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../resources/asset_paths.dart';
import '../resources/sound_manager.dart';
import '../services/game_settings.dart';
import 'components/cube_button.dart';
import 'components/game_hud.dart';
import 'components/grid_bg.dart';
import 'components/space_bg.dart';

/// 순서 탭 게임의 메인 FlameGame.
/// 5×5 그리드에 첫 구간을 셔플해 배치하고, 정답을 맞추면 다음 구간이 셔플된 순서로 이어진다.
class BingoCardGame extends FlameGame with TapCallbacks {
  /// 게임 모드: 0 = 숫자(1~50), 1 = 알파벳(A~Z)
  final int gameMode;

  /// 게임 요소 배치에만 적용하는 SafeArea 패딩.
  final EdgeInsets safeAreaPadding;

  BingoCardGame({this.gameMode = 0, this.safeAreaPadding = EdgeInsets.zero});

  static const int colNum = 5;
  static const int rowNum = 5;
  static const int firstTableNum = colNum * rowNum;

  late int totalCount;
  late List<String> labels;

  int currentNumber = 1;
  int _nextSecondIndex = 0;
  bool isPlaying = false;

  late List<int> shuffledFirst;
  late List<int> shuffledSecond;

  final List<CubeButton> _cubes = [];
  GameHud? _hud;
  GridBg? _gridBg;

  double _elapsedTime = 0;
  double _hintTimer = 0;
  static const double hintDelay = 5.0;

  /// 다국어 문자열. 오버레이 빌드 시 context에서 주입.
  Map<String, String> _localeStrings = {};
  String localeString(String key, String fallback) =>
      _localeStrings[key] ?? fallback;

  void setLocaleStrings(Map<String, String> strings) {
    _localeStrings = strings;
    _hud?.onLocaleChanged();
  }

  /// 텍스트 외곽선(outline) 색상
  static const List<Color> outlineColors = [
    Color(0xFFAD2323), // 1~9
    Color(0xFF008444), // 10~19
    Color(0xFF0082CC), // 20~29
    Color(0xFF1565C0), // 30~39
    Color(0xFFC56600), // 40~49
    Color(0xFF0D47A1), // 50 / Z
  ];

  /// 큐브 배경색 (outline보다 밝은 톤)
  static const List<Color> bgColors = [
    Color(0xFFE05555), // 1~9
    Color(0xFF2DB872), // 10~19
    Color(0xFF3CAEE0), // 20~29
    Color(0xFF42A5F5), // 30~39
    Color(0xFFE8A020), // 40~49
    Color(0xFF1976D2), // 50 / Z
  ];

  /// 마지막 숫자(50/Z)용 그라데이션 색상
  static const List<Color> lastGradient = [
    Color(0xFFE05555),
    Color(0xFFE8A020),
    Color(0xFFE8D040),
    Color(0xFF2DB872),
    Color(0xFF3CAEE0),
    Color(0xFF1976D2),
  ];

  /// 큐브 배경색을 반환한다.
  /// 로직: 1~9→0, 10~19→1, … 40~49→4, 마지막(50/Z)은 별도 인덱스.
  static Color getBgColorForId(int id, int totalCount) {
    if (id == totalCount) return bgColors[bgColors.length - 1];
    return bgColors[(id - 1) ~/ 10];
  }

  /// 텍스트 외곽선 색상을 반환한다.
  /// 로직: getBgColorForId와 동일한 구간(10단위) 매핑.
  static Color getOutlineColorForId(int id, int totalCount) {
    if (id == totalCount) return outlineColors[outlineColors.length - 1];
    return outlineColors[(id - 1) ~/ 10];
  }

  /// 마지막 숫자인지에 따라 그라데이션 색상 리스트를 반환한다.
  static List<Color>? getGradientForId(int id, int totalCount) {
    if (id == totalCount) return lastGradient;
    return null;
  }

  /// 백그라운드 진입 시: 게임 BGM만 일시정지. 플레이 중이면 PauseMenu 표시.
  /// detached는 GameWidget 제거(메뉴로 나가기) 시에도 호출되므로 BGM pause 제외.
  /// 복귀 시: PauseMenu면 사용자가 "계속하기"로 재개, Clear 팝업이면 BGM 자동 재개.
  @override
  void lifecycleStateChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        // PauseMenu: 사용자가 "계속하기"로 재개. Clear 팝업: BGM 자동 재개.
        if (overlays.isActive('Clear')) {
          SoundManager.resumeBgm(onlyIfCurrent: AssetPaths.bgmMain);
        }
        return;
      case AppLifecycleState.detached:
        // 메뉴로 나갈 때 GameWidget dispose 시 호출됨. pauseBgm 호출 시 메뉴 BGM이 멈춤.
        super.lifecycleStateChange(state);
        return;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        super.lifecycleStateChange(state);
        // 라우트 전환 경쟁 상태에서 메뉴 BGM까지 멈추지 않도록 game BGM일 때만 pause.
        SoundManager.pauseBgm(onlyIfCurrent: AssetPaths.bgmMain);
        if (isPlaying) {
          isPlaying = false;
          overlays.add('PauseMenu');
        }
        break;
    }
  }

  /// 게임 초기화: 배경, HUD, 그리드 생성 후 카운트다운 오버레이 표시.
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initLabels();
    camera.viewfinder
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();

    camera.backdrop.add(SpaceBg());

    _hud = GameHud();
    camera.viewport.add(_hud!);

    _prepareGrid();
    overlays.remove('Countdown');
    overlays.add('Countdown', priority: 1); // HUD 위에 카운트다운 표시
  }

  /// gameMode에 따라 labels와 totalCount를 설정한다. 0=숫자(1~50), 1=알파벳(A~Z).
  void _initLabels() {
    if (gameMode == 0) {
      totalCount = 50;
      labels = List.generate(50, (i) => '${i + 1}');
    } else {
      totalCount = 26;
      labels = List.generate(
        26,
        (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
      );
    }
  }

  /// 그리드를 셔플하고 배치한다. 카운트다운 뒤에 큐브가 보이도록 미리 호출된다.
  void _prepareGrid() {
    _clearCubes();

    currentNumber = 1;
    _nextSecondIndex = 0;
    _elapsedTime = 0;
    _hintTimer = 0;

    // 1차: 1~25(또는 A~Y), 2차: 26~50(또는 Z) 순서를 셔플.
    final secondTableNum = totalCount - firstTableNum;
    shuffledFirst = _shuffle(List.generate(firstTableNum, (i) => i + 1));
    if (secondTableNum > 0) {
      shuffledSecond = _shuffle(
        List.generate(secondTableNum, (i) => firstTableNum + i + 1),
      );
    } else {
      shuffledSecond = [];
    }

    _createGrid();
    _hud?.updateHint(labels[currentNumber - 1]);
    _hud?.updateTime(0);
  }

  /// 다시하기 시: 그리드를 새로 배치하고 카운트다운을 띄운다.
  void prepareAndCountdown() {
    _prepareGrid();
    overlays.add('Countdown', priority: 1); // HUD 위에 카운트다운 표시
  }

  /// 카운트다운 완료 후 호출. 게임 플레이를 시작한다.
  void startGame() {
    isPlaying = true;
  }

  /// 일시정지: BGM 멈추고 오버레이를 띄운다.
  void pauseGame() {
    if (!isPlaying) return;
    isPlaying = false;
    // 사용자가 직접 일시정지를 누른 경우에는 현재 BGM을 항상 멈춘다.
    SoundManager.pauseBgm();
    pauseEngine();
    overlays.add('PauseMenu');
  }

  /// 상단 HUD 비율 기준. min(가로,세로)의 23% → 아이패드에서도 적절한 크기.
  static const double _hudScaleRatio = 0.23;
  double get _hudScale =>
      (size.x < size.y ? size.x : size.y) * _hudScaleRatio;

  /// 타임 패널↔힌트↔그리드 사이 여백. 비율로 계산.
  double get _gap => _hudScale * 0.4;

  /// 타임 패널 높이. HUD와 공유.
  double get _panelH => _hudScale * 0.95;

  /// 힌트 원 반지름.
  double get _hintR => _hudScale * 0.4;

  double get _hintRowH => _hintR * 2;

  /// 타임 패널 높이. HUD와 공유.
  double get panelH => _panelH;

  /// HUD 비율 기준값. GameHud에서 패널 너비·버튼 크기 등 계산용.
  double get hudScale => _hudScale;

  /// 힌트 원 반지름. HUD와 공유.
  double get hintR => _hintR;

  /// 안전영역 안쪽에서 게임 요소를 배치할 좌우 기준선.
  double get safeContentLeft => safeAreaPadding.left + size.x * 0.03;

  double get safeContentRight => size.x - safeAreaPadding.right - size.x * 0.03;

  double get safeContentWidth =>
      (safeContentRight - safeContentLeft).clamp(0.0, double.infinity);

  double get safeContentCenterX => safeContentLeft + safeContentWidth / 2;

  /// 타임 패널 중심 Y.
  double get panelCenterY => safeAreaPadding.top + _gap + _panelH / 2;

  /// 힌트 말풍선 중심 Y. (패널 아래 gap + 힌트 행 절반)
  double get hintCenterY =>
      safeAreaPadding.top + 2 * _gap + _panelH + _hintR;

  /// 그리드 상단 Y. (HUD 아래 gap 후 그리드)
  double get gridTopY =>
      safeAreaPadding.top + _gap + _panelH + _gap + _hintRowH + _gap;

  /// 레이아웃 기준. 상단 HUD 고정 후 남은 공간에 그리드 크기 결정.
  double get layoutRef {
    final availW = safeContentWidth;
    final maxGridH = (size.y - safeAreaPadding.bottom - gridTopY - _gap)
        .clamp(0.0, double.infinity);
    return availW < maxGridH ? availW : maxGridH;
  }

  /// 창 크기 변경 시 호출. 그리드·HUD·배경은 각 컴포넌트의 onGameResize에서 처리.
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateGridLayout();
  }

  /// 그리드 레이아웃만 갱신. 게임 상태(숫자 배치)는 유지.
  void _updateGridLayout() {
    if (!hasLayout) return;
    const spacingRatio = 0.08;
    final gridTop = gridTopY;
    final ref = layoutRef;

    final cubeSize = ref / (colNum + spacingRatio * (colNum + 1));
    final spacing = cubeSize * spacingRatio;
    final step = cubeSize + spacing;
    final gridWidth = colNum * cubeSize + (colNum + 1) * spacing;
    final contentLeft = safeContentLeft + (safeContentWidth - gridWidth) / 2;
    final gridLeft = contentLeft + spacing;

    final bgPadding = spacing * 0.5;
    final bgTop = gridTop + spacing - bgPadding;
    final bgHeight = step * rowNum + bgPadding * 2;
    final bgWidth = gridWidth + bgPadding * 2;

    if (_gridBg != null && _gridBg!.isMounted) {
      _gridBg!.position = Vector2(contentLeft - bgPadding, bgTop);
      _gridBg!.size = Vector2(bgWidth, bgHeight);
    }

    for (final cube in _cubes) {
      if (!cube.isMounted) continue;
      final row = cube.gridIndex ~/ colNum;
      final col = cube.gridIndex % colNum;
      cube.position = Vector2(
        gridLeft + col * step + cubeSize / 2,
        gridTop + spacing + row * step + cubeSize / 2,
      );
      cube.size = Vector2.all(cubeSize);
      cube.refreshForResize();
    }

    _gridCubeSize = cubeSize;
  }

  /// 5×5 그리드. 세로 간격 일정화 후 남은 공간에 맞춰 크기 결정.
  void _createGrid() {
    const spacingRatio = 0.08;
    final gridTop = gridTopY;
    final ref = layoutRef;

    final cubeSize = ref / (colNum + spacingRatio * (colNum + 1));
    final spacing = cubeSize * spacingRatio;
    final step = cubeSize + spacing;
    final gridWidth = colNum * cubeSize + (colNum + 1) * spacing;
    final contentLeft = safeContentLeft + (safeContentWidth - gridWidth) / 2;
    final gridLeft = contentLeft + spacing;

    final bgPadding = spacing * 0.5;
    final bgTop = gridTop + spacing - bgPadding;
    final bgHeight = step * rowNum + bgPadding * 2;
    final bgWidth = gridWidth + bgPadding * 2;

    if (_gridBg != null && _gridBg!.isMounted) _gridBg!.removeFromParent();
    _gridBg = GridBg(
      position: Vector2(contentLeft - bgPadding, bgTop),
      size: Vector2(bgWidth, bgHeight),
    )..priority = 0;
    world.add(_gridBg!);

    for (var i = 0; i < firstTableNum; i++) {
      final row = i ~/ colNum; // 0~4
      final col = i % colNum;  // 0~4
      final id = shuffledFirst[i];

      final cube = CubeButton(
        id: id,
        label: labels[id - 1],
        btnColor: getBgColorForId(id, totalCount),
        outlineColor: getOutlineColorForId(id, totalCount),
        gradientColors: getGradientForId(id, totalCount),
        // position: Anchor.center 기준이므로 중심 좌표 계산.
        position: Vector2(
          gridLeft + col * step + cubeSize / 2,
          gridTop + spacing + row * step + cubeSize / 2,
        ),
        size: Vector2.all(cubeSize),
        onTap: _onCubeTap,
        gridIndex: i,
      );
      _cubes.add(cube);
      world.add(cube);
    }

    _gridCubeSize = cubeSize;
  }

  double _gridCubeSize = 0;

  /// 큐브 탭 처리: 정답이면 다음 숫자로 진행·교체, 오답이면 흔들림 애니메이션.
  void _onCubeTap(CubeButton cube) {
    SoundManager.unlockForWeb(); // 웹: 탭 시점에 unlock → BGM 재생
    if (!isPlaying) return;

    if (cube.id == currentNumber) {
      // 정답
      SoundManager.playSfx(AssetPaths.sfxCollect);
      _hintTimer = 0;
      _cancelHint();

      if (currentNumber == totalCount) {
        // 게임 클리어
        isPlaying = false;
        GameSettings.saveBestScoreIfBetter(gameMode, _elapsedTime);
        cube.animateCorrect(() {
          SoundManager.playSfx(AssetPaths.sfxClear);
          overlays.add('Clear');
        });
      } else {
        currentNumber++;
        _hud?.updateHint(labels[currentNumber - 1]);

        cube.animateCorrect(() {
          // 2차 테이블(shuffledSecond)에서 셔플된 순서대로 다음 숫자/알파벳 교체.
          if (_nextSecondIndex < shuffledSecond.length) {
            final nextId = shuffledSecond[_nextSecondIndex];
            _nextSecondIndex++;

            final newCube = CubeButton(
              id: nextId,
              label: labels[nextId - 1],
              btnColor: getBgColorForId(nextId, totalCount),
              outlineColor: getOutlineColorForId(nextId, totalCount),
              gradientColors: getGradientForId(nextId, totalCount),
              position: cube.position.clone(),
              size: Vector2.all(_gridCubeSize),
              onTap: _onCubeTap,
              gridIndex: cube.gridIndex,
            );
            _cubes.add(newCube);
            world.add(newCube);
            newCube.animateFadeIn();
          }
        });
      }
    } else {
      // 오답
      SoundManager.playSfx(AssetPaths.sfxFail);
      cube.animateWrong();
    }
  }

  /// 매 프레임: 경과 시간 갱신, hintDelay마다 힌트 표시.
  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying) return;

    _elapsedTime += dt;
    _hud?.updateTime(_elapsedTime);

    // hintDelay(5초)마다 현재 찾을 숫자에 힌트(깜박임) 표시.
    _hintTimer += dt;
    if (_hintTimer >= hintDelay) {
      _hintTimer = 0;
      _showHint();
    }
  }

  /// 현재 찾을 숫자에 해당하는 큐브에 깜박임(힌트)을 시작한다.
  void _showHint() {
    for (final cube in _cubes) {
      if (cube.id == currentNumber && cube.isMounted) {
        cube.startBlink();
        break;
      }
    }
  }

  /// 모든 큐브의 깜박임을 중지한다.
  void _cancelHint() {
    for (final cube in _cubes) {
      cube.stopBlink();
    }
  }

  /// 그리드의 모든 큐브를 제거하고 _cubes 리스트를 비운다.
  void _clearCubes() {
    for (final cube in _cubes) {
      if (cube.isMounted) cube.removeFromParent();
    }
    _cubes.clear();
  }

  /// 경과 시간을 조건에 따라 포맷한다.
  /// 60초 미만: 50.33 | 1분 이상: 34m 50.33 | 1시간 이상: 13h 20m 51.22
  String get formattedTime => formatTime(_elapsedTime);

  /// [seconds]를 조건부 포맷: 60초 미만(초.밀리), 분(34m 50.33), 시간(13h 20m 51.22).
  /// 베스트 스코어·타임 패널 공용.
  static String formatTime(double seconds) {
    if (seconds < 60) {
      return seconds.toStringAsFixed(2); // 50.33
    }
    if (seconds < 3600) {
      final m = (seconds ~/ 60).toInt();
      final s = seconds % 60;
      return '${m}m ${s.toStringAsFixed(2)}'; // 34m 50.33
    }
    final h = (seconds ~/ 3600).toInt();
    final m = ((seconds % 3600) ~/ 60).toInt();
    final s = seconds % 60;
    return '${h}h ${m}m ${s.toStringAsFixed(2)}'; // 13h 20m 51.22
  }

  /// 현재 모드의 베스트 스코어(초). 없으면 null.
  double? get bestScore => GameSettings.getBestScore(gameMode);

  /// 베스트 스코어 포맷 문자열. 없으면 null.
  String? get formattedBestScore =>
      bestScore != null ? formatTime(bestScore!) : null;

  /// Fisher-Yates 셔플: O(n)으로 균등 무작위.
  List<int> _shuffle(List<int> list) {
    final random = Random();
    for (var i = list.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }
    return list;
  }
}
