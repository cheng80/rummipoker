import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/app.dart';
import 'package:rummipoker/resources/asset_paths.dart';

/// 화면의 한자가 빈 네모로 보이지 않게 막는 회귀 테스트.
/// 기본 폰트(NEXON Lv2 Gothic)에 없는 글자는 번들된 서브셋 fallback으로 그려야 한다.
///
/// 번역 파일에 새 글자가 들어오면 마지막 테스트가 실패한다. 그때는
/// `tools/build_ui_font_subset.py`를 다시 돌려 서브셋과 글자 목록을 갱신한다.
void main() {
  const subsetAsset = 'assets/fonts/NotoSansCjkUiSubset-Regular.otf';
  const coveragePath = 'tools/ui_font_subset_coverage.txt';

  test('pubspec에 UI fallback 폰트 family가 선언돼 있다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('family: ${AssetPaths.fontNotoSansCjkUiSubset}'));
    expect(pubspec, contains('asset: $subsetAsset'));
    expect(File(subsetAsset).existsSync(), isTrue);
    expect(
      File('assets/fonts/NotoSansCjkUiSubset-OFL.txt').existsSync(),
      isTrue,
      reason: 'OFL 라이선스 원문을 폰트와 함께 둔다.',
    );
  });

  test('테마의 textTheme이 fallback 폰트를 포함한다', () {
    final theme = buildAppTheme();

    for (final style in <TextStyle?>[
      theme.textTheme.bodyMedium,
      theme.textTheme.bodyLarge,
      theme.textTheme.titleMedium,
      theme.primaryTextTheme.bodyMedium,
    ]) {
      expect(style?.fontFamily, AssetPaths.fontNexonLv2Gothic);
      expect(
        style?.fontFamilyFallback,
        contains(AssetPaths.fontNotoSansCjkUiSubset),
      );
    }
  });

  test('번역 파일의 모든 글자를 기본 폰트나 서브셋이 덮는다', () {
    final coverage = _readCoverage(File(coveragePath).readAsStringSync());
    final subsetChars = coverage['subset'];
    final bundledChars = coverage['bundled'];
    expect(subsetChars, isNotNull, reason: '$coveragePath 에 subset 목록이 없다.');
    expect(bundledChars, isNotNull, reason: '$coveragePath 에 bundled 목록이 없다.');

    final covered = <int>{...subsetChars!, ...bundledChars!};
    final uncovered = <int>{};
    for (final file in _translationFiles()) {
      final data = jsonDecode(file.readAsStringSync());
      for (final text in _strings(data)) {
        for (final rune in text.runes) {
          if (_isWhitespace(rune)) continue;
          if (!covered.contains(rune)) uncovered.add(rune);
        }
      }
    }

    expect(
      uncovered,
      isEmpty,
      reason:
          '번역 파일에 새 글자가 들어왔다: ${String.fromCharCodes(uncovered.toList()..sort())}\n'
          'tools/build_ui_font_subset.py 를 다시 돌려 서브셋과 $coveragePath 를 갱신한다.',
    );
  });
}

/// `# 이름` 헤더로 구분된 글자 목록을 읽는다. 주석 줄은 헤더로만 쓰인다.
Map<String, Set<int>> _readCoverage(String raw) {
  final result = <String, Set<int>>{};
  String? section;
  for (final line in const LineSplitter().convert(raw)) {
    if (line.startsWith('# subset')) {
      section = 'subset';
    } else if (line.startsWith('# bundled')) {
      section = 'bundled';
    } else if (line.startsWith('#')) {
      continue;
    } else if (section != null && line.isNotEmpty) {
      result.putIfAbsent(section, () => <int>{}).addAll(line.runes);
    }
  }
  return result;
}

List<File> _translationFiles() {
  final files = <File>[
    ...Directory('assets/translations')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json')),
    ...Directory('assets/translations/data')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json')),
  ];
  expect(files, isNotEmpty);
  return files;
}

Iterable<String> _strings(Object? node) sync* {
  if (node is String) {
    yield node;
  } else if (node is Map) {
    for (final value in node.values) {
      yield* _strings(value);
    }
  } else if (node is List) {
    for (final value in node) {
      yield* _strings(value);
    }
  }
}

bool _isWhitespace(int rune) {
  return rune == 0x20 || rune == 0x09 || rune == 0x0a || rune == 0x0d || rune == 0xa0;
}
