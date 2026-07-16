import 'dart:io';

const _allowedGroups = <String>{
  'archive',
  'core',
  'generated',
  'planning',
  'release',
  'tools',
};

void main(List<String> args) {
  final root = _parseRoot(args);
  if (root == null) {
    stderr.writeln(
      'Usage: dart run tools/check_docs_structure.dart [--root <path>]',
    );
    exitCode = 2;
    return;
  }

  final errors = <String>[];
  final docsReadme = File('${root.path}/docs/00_docs_README.md');
  final markdownPaths = _markdownPaths(root);
  final registryPaths = docsReadme.existsSync()
      ? _registryPaths(docsReadme.readAsStringSync(), errors)
      : <String>{};

  if (!docsReadme.existsSync()) {
    errors.add('docs/00_docs_README.md가 없습니다.');
  }

  for (final path in markdownPaths) {
    final group = _groupOf(path);
    if (path != 'docs/00_docs_README.md' &&
        (group == null || !_allowedGroups.contains(group))) {
      errors.add('허용되지 않은 문서 경로: $path');
    }
    if (!registryPaths.contains(path)) {
      errors.add('문서 registry 미등록: $path');
    }

    final content = File('${root.path}/$path').readAsStringSync();
    if (!_hasTitle(content)) {
      errors.add('H1 제목 누락: $path');
    }
    if (group == 'planning' && !content.contains('> 역할:')) {
      errors.add('planning 문서 역할 누락: $path');
    }
    if (group == 'generated' &&
        (!content.contains('DO NOT EDIT') ||
            !content.contains('tools/generate_docs.dart'))) {
      errors.add('generated 문서 보호 헤더 누락: $path');
    }
  }

  for (final path in registryPaths) {
    if (!File('${root.path}/$path').existsSync()) {
      errors.add('registry 경로가 존재하지 않음: $path');
    }
  }

  final missingFromRegistry = markdownPaths
      .where((path) => !registryPaths.contains(path))
      .toSet();
  final missingFromDisk = registryPaths
      .where((path) => !markdownPaths.contains(path))
      .toSet();
  if (missingFromRegistry.isNotEmpty || missingFromDisk.isNotEmpty) {
    errors.add('문서 registry와 실제 Markdown 파일 목록이 일치하지 않습니다.');
  }

  if (errors.isEmpty) {
    stdout.writeln(
      'Documentation structure OK (${markdownPaths.length} Markdown files).',
    );
    return;
  }

  stderr.writeln('Documentation structure check failed:');
  for (final error in errors) {
    stderr.writeln('- $error');
  }
  exitCode = 1;
}

Directory? _parseRoot(List<String> args) {
  if (args.isEmpty) return Directory.current;
  if (args.length == 2 && args[0] == '--root') {
    final root = Directory(args[1]);
    return root.existsSync() ? root : null;
  }
  return null;
}

List<String> _markdownPaths(Directory root) {
  final docs = Directory('${root.path}/docs');
  if (!docs.existsSync()) return const [];
  return docs
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.md'))
      .map((file) => _relativePath(root, file))
      .toList()
    ..sort();
}

Set<String> _registryPaths(String content, List<String> errors) {
  const startMarker = '<!-- DOCUMENT_REGISTRY_START -->';
  const endMarker = '<!-- DOCUMENT_REGISTRY_END -->';
  final start = content.indexOf(startMarker);
  final end = content.indexOf(endMarker);
  if (start < 0 || end <= start) {
    errors.add('문서 registry marker가 없습니다.');
    return <String>{};
  }

  final body = content.substring(start + startMarker.length, end);
  final paths = RegExp(
    r'^\| `([^`]+\.md)` \|',
    multiLine: true,
  ).allMatches(body).map((match) => match.group(1)!).toList(growable: false);
  final unique = paths.toSet();
  if (paths.length != unique.length) {
    errors.add('문서 registry에 중복 경로가 있습니다.');
  }
  return unique;
}

String? _groupOf(String path) {
  final parts = path.split('/');
  return parts.length >= 3 && parts[0] == 'docs' ? parts[1] : null;
}

String _relativePath(Directory root, File file) {
  final prefix = '${root.absolute.path}${Platform.pathSeparator}';
  return file.absolute.path
      .substring(prefix.length)
      .replaceAll(Platform.pathSeparator, '/');
}

bool _hasTitle(String content) {
  final firstContentLine = content
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => '');
  return firstContentLine.startsWith('# ');
}
