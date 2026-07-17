import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Future<ProcessResult> _runChecker([String? root]) {
  return Process.run('dart', [
    'run',
    'tools/check_docs_structure.dart',
    if (root != null) ...['--root', root],
  ]);
}

void main() {
  test('current documentation satisfies the structure contract', () async {
    final result = await _runChecker();
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('rejects a document outside the allowed document groups', () async {
    final root = Directory.systemTemp.createTempSync('docs_structure_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    final docs = Directory('${root.path}/docs')..createSync(recursive: true);
    File(
      '${docs.path}/00_docs_README.md',
    ).writeAsStringSync('# Documentation Boundaries\n');
    final experimental = Directory('${docs.path}/experimental')
      ..createSync(recursive: true);
    File('${experimental.path}/NOTE.md').writeAsStringSync('# Note\n');

    final result = await _runChecker(root.path);

    expect(result.exitCode, isNot(0));
    expect('${result.stdout}\n${result.stderr}', contains('허용되지 않은 문서 경로'));
  });

  test('rejects an allowed-path document missing from the registry', () async {
    final root = Directory.systemTemp.createTempSync('docs_registry_test_');
    addTearDown(() => root.deleteSync(recursive: true));

    final docs = Directory('${root.path}/docs')..createSync(recursive: true);
    File('${docs.path}/00_docs_README.md').writeAsStringSync(
      '# Documentation Boundaries\n\n'
      '<!-- DOCUMENT_REGISTRY_START -->\n'
      '| 경로 | 유형 | 역할 |\n'
      '|---|---|---|\n'
      '| `docs/00_docs_README.md` | governance | 규칙 |\n'
      '<!-- DOCUMENT_REGISTRY_END -->\n',
    );
    final core = Directory('${docs.path}/core')..createSync(recursive: true);
    File('${core.path}/NEW.md').writeAsStringSync('# New\n');

    final result = await _runChecker(root.path);

    expect(result.exitCode, isNot(0));
    expect(
      '${result.stdout}\n${result.stderr}',
      contains('문서 registry 미등록: docs/core/NEW.md'),
    );
  });

  test(
    'allows optional Superpowers specs and plans without registry entries',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'docs_superpowers_test_',
      );
      addTearDown(() => root.deleteSync(recursive: true));

      final docs = Directory('${root.path}/docs')..createSync(recursive: true);
      File('${docs.path}/00_docs_README.md').writeAsStringSync(
        '# Documentation Boundaries\n\n'
        '<!-- DOCUMENT_REGISTRY_START -->\n'
        '| 경로 | 유형 | 역할 |\n'
        '|---|---|---|\n'
        '| `docs/00_docs_README.md` | governance | 규칙 |\n'
        '<!-- DOCUMENT_REGISTRY_END -->\n',
      );
      final specs = Directory('${docs.path}/superpowers/specs')
        ..createSync(recursive: true);
      final plans = Directory('${docs.path}/superpowers/plans')
        ..createSync(recursive: true);
      File('${specs.path}/feature.md').writeAsStringSync('# Feature Design\n');
      File('${plans.path}/feature.md').writeAsStringSync('# Feature Plan\n');

      final result = await _runChecker(root.path);

      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    },
  );
}
