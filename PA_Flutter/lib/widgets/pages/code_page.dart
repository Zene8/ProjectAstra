import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:highlight/languages/dart.dart';

class CodePage extends StatefulWidget {
  const CodePage({super.key});

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  final CodeController _controller = CodeController(
    text: '// Welcome to the code editor!\n',
    language: dart,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // TODO: Add a toolbar for language selection, etc.
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: monokaiSublimeTheme),
            child: CodeField(
              controller: _controller,
            ),
          ),
        ),
      ],
    );
  }
}
