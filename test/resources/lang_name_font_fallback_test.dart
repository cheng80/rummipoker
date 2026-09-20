import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rummipoker/app.dart';
import 'package:rummipoker/resources/asset_paths.dart';

/// 설정 화면의 언어 이름(日本語·简体中文·繁體中文)이 빈 네모로 보이지 않게 막는 회귀 테스트.
/// 기본 폰트에 없는 글자는 번들된 서브셋 fallback으로 그려야 한다. 글리프 포함 여부는
/// tools/build_lang_name_font_subset.py 의 자체 검사가 확인한다.
void main() {
  const subsetAsset = 'assets/fonts/NotoSansCjkLangNames-Regular.otf';

  test('pubspec에 언어 이름 fallback 폰트 family가 선언돼 있다', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('family: ${AssetPaths.fontNotoSansCjkLangNames}'));
    expect(pubspec, contains('asset: $subsetAsset'));
    expect(File(subsetAsset).existsSync(), isTrue);
    expect(
      File('assets/fonts/NotoSansCjkLangNames-OFL.txt').existsSync(),
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
        contains(AssetPaths.fontNotoSansCjkLangNames),
      );
    }
  });
}
