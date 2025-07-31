// lib/features/chat/widgets/code_element_highlighter.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart' as md;
import 'package:highlight/highlight.dart' as hl;

// Default Dark Theme for Code Blocks
const Map<String, TextStyle> kDefaultDarkCodeTheme = {
  'root': TextStyle(
    backgroundColor: Color(0xFF2B2B2B),
    color: Color(0xFFA9B7C6),
    fontSize: 13,
    height: 1.4,
  ),
  // ... rest of your kDefaultDarkCodeTheme definition ...
  'comment': TextStyle(color: Color(0xFF808080)),
  'quote': TextStyle(color: Color(0xFF808080)),
  'keyword': TextStyle(color: Color(0xFFCC7832)),
  'selector-tag': TextStyle(color: Color(0xFFCC7832)),
  'subst': TextStyle(color: Color(0xFFA9B7C6)),
  'number': TextStyle(color: Color(0xFF6897BB)),
  'literal': TextStyle(color: Color(0xFF6897BB)),
  'variable': TextStyle(color: Color(0xFF629755)),
  'template-variable': TextStyle(color: Color(0xFF629755)),
  'string': TextStyle(color: Color(0xFF6A8759)),
  'doctag': TextStyle(color: Color(0xFF6A8759)),
  'title': TextStyle(color: Color(0xFFFFC66D)),
  'section': TextStyle(color: Color(0xFFFFC66D)),
  'type': TextStyle(color: Color(0xFFFFC66D)),
  'name': TextStyle(color: Color(0xFFE8BF6A)),
  'built_in': TextStyle(color: Color(0xFFE8BF6A)),
  'tag': TextStyle(color: Color(0xFFE8BF6A)),
  'attr': TextStyle(color: Color(0xFFBABABA)),
  'attribute': TextStyle(color: Color(0xFFBABABA)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'formula': TextStyle(color: Color(0xFFA9B7C6)),
  'link': TextStyle(color: Color(0xFF6897BB)),
  'bullet': TextStyle(color: Color(0xFF6897BB)),
  'code': TextStyle(color: Color(0xFFA9B7C6)),
  'meta': TextStyle(color: Color(0xFFBBB529)),
  'regexp': TextStyle(color: Color(0xFF9876AA)),
  'deletion': TextStyle(color: Color(0xFFFF5252)),
  'addition': TextStyle(color: Color(0xFF629755)),
  'punctuation': TextStyle(color: Color(0xFFA9B7C6)),
  'params': TextStyle(color: Color(0xFFA9B7C6)),
};

// Default Light Theme for Code Blocks
const Map<String, TextStyle> kDefaultLightCodeTheme = {
  'root': TextStyle(
    backgroundColor: Color(0xFFF6F8FA),
    color: Color(0xFF24292E),
    fontSize: 13,
    height: 1.4,
  ),
  // ... rest of your kDefaultLightCodeTheme definition ...
  'comment': TextStyle(color: Color(0xFF6A737D)),
  'quote': TextStyle(color: Color(0xFF6A737D)),
  'keyword': TextStyle(color: Color(0xFFD73A49)),
  'selector-tag': TextStyle(color: Color(0xFFD73A49)),
  'subst': TextStyle(color: Color(0xFF24292E)),
  'number': TextStyle(color: Color(0xFF005CC5)),
  'literal': TextStyle(color: Color(0xFF005CC5)),
  'variable': TextStyle(color: Color(0xFFE36209)),
  'template-variable': TextStyle(color: Color(0xFFE36209)),
  'string': TextStyle(color: Color(0xFF032F62)),
  'doctag': TextStyle(color: Color(0xFF032F62)),
  'title': TextStyle(color: Color(0xFF6F42C1)),
  'section': TextStyle(color: Color(0xFF6F42C1)),
  'type': TextStyle(color: Color(0xFF6F42C1)),
  'name': TextStyle(color: Color(0xFF22863A)),
  'built_in': TextStyle(color: Color(0xFF22863A)),
  'tag': TextStyle(color: Color(0xFF22863A)),
  'attr': TextStyle(color: Color(0xFF6F42C1)),
  'attribute': TextStyle(color: Color(0xFF6F42C1)),
  'emphasis': TextStyle(fontStyle: FontStyle.italic),
  'strong': TextStyle(fontWeight: FontWeight.bold),
  'formula': TextStyle(color: Color(0xFF24292E)),
  'link': TextStyle(color: Color(0xFF005CC5)),
  'bullet': TextStyle(color: Color(0xFF005CC5)),
  'code': TextStyle(color: Color(0xFF24292E)),
  'meta': TextStyle(color: Color(0xFF005CC5)),
  'regexp': TextStyle(color: Color(0xFF032F62)),
  'deletion': TextStyle(color: Color(0xFFB31D28)),
  'addition': TextStyle(color: Color(0xFF22863A)),
  'punctuation': TextStyle(color: Color(0xFF24292E)),
  'params': TextStyle(color: Color(0xFF24292E)),
};

class CodeElementHighlighter extends md.SyntaxHighlighter {
  final Map<String, TextStyle> _theme; // This remains private

  CodeElementHighlighter({Map<String, TextStyle>? theme})
    : _theme = theme ?? kDefaultDarkCodeTheme;

  // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  // ADD THESE PUBLIC GETTERS:
  // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  /// Provides access to the root background color of the current theme.
  Color? get rootBackgroundColor => _theme['root']?.backgroundColor;

  /// Provides access to the full current theme map (e.g., for inline code styling).
  Map<String, TextStyle> get currentTheme => _theme;
  // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  @override
  TextSpan format(String source) {
    final result = hl.highlight.parse(source, autoDetection: true);
    return _convert(result.nodes, _theme);
  }

  TextSpan formatWithLanguage(String source, String? language) {
    final String lang = language ?? 'plaintext';
    final result = hl.highlight.parse(
      source,
      language: lang,
      autoDetection: language == null || language.isEmpty,
    );
    return _convert(result.nodes, _theme);
  }

  TextSpan _convert(List<hl.Node>? nodes, Map<String, TextStyle> theme) {
    List<TextSpan> spans = <TextSpan>[];
    if (nodes != null) {
      _traverse(nodes, theme['root'], spans, theme);
    }
    return TextSpan(children: spans, style: theme['root']);
  }

  void _traverse(
    List<hl.Node> nodes,
    TextStyle? parentStyle,
    List<TextSpan> spans,
    Map<String, TextStyle> theme,
  ) {
    for (final hl.Node node in nodes) {
      final TextStyle? style = theme[node.className] ?? parentStyle;
      if (node.children != null && node.children!.isNotEmpty) {
        _traverse(node.children!, style, spans, theme);
      } else if (node.value != null) {
        spans.add(TextSpan(text: node.value, style: style));
      }
    }
  }
}
