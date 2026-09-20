// SemanticText measures the box it is given, so it uses a LayoutBuilder.
// A LayoutBuilder asserts in debug builds the moment an ancestor asks it for an
// intrinsic size, and the widgets below do exactly that. Material's AlertDialog
// and SimpleDialog are on the list because they wrap their content in an
// IntrinsicWidth.
//
// This is a per-file check, not a real widget-tree check. If one file both
// builds a SemanticText and builds one of these widgets, the two are close
// enough that someone has to look. Reading the actual tree would need the
// analyzer, and the cheap version already catches the mistake in the files that
// matter.
//
// A screen that needs both keeps a plain Text inside the intrinsic-size part,
// or moves onto this project's own GameModalCard dialogs.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _intrinsicSizeWidgets = <String>[
  'IntrinsicWidth',
  'IntrinsicHeight',
  'AlertDialog(',
  'SimpleDialog(',
];

/// Files that legitimately mention both. Add a line only after checking that
/// no SemanticText actually sits under the intrinsic-size widget, and say why.
const _allowList = <String, String>{
  'lib/views/game/game_view_battle_actions.dart':
      'SemanticText is only in the bounded plain Dialog; AlertDialog retains Text.',
  // The widget's own source names these in its documentation.
  'lib/widgets/semantic_text.dart': 'documentation only',
};

List<String> _libraryFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.path)
        .toList()
      ..sort();

void main() {
  test('no file builds a SemanticText next to an intrinsic-size widget', () {
    final offenders = <String, List<String>>{};
    for (final path in _libraryFiles()) {
      final source = File(path).readAsStringSync();
      if (!source.contains('SemanticText(')) continue;
      final found = _intrinsicSizeWidgets
          .where(source.contains)
          .toList(growable: false);
      if (found.isNotEmpty) offenders[path] = found;
    }

    final unexpected = offenders.keys.where(
      (path) => !_allowList.containsKey(path),
    );
    expect(
      unexpected,
      isEmpty,
      reason:
          'SemanticText uses a LayoutBuilder, which asserts under an '
          'intrinsic-size ancestor. Keep a plain Text there, or move the '
          'screen onto GameModalCard. See docs/core/I18N.md.',
    );

    final cleared = _allowList.keys.where(
      (path) => !offenders.containsKey(path),
    );
    expect(
      cleared,
      isEmpty,
      reason: 'These files no longer need their _allowList line. Remove it.',
    );
  });
}
