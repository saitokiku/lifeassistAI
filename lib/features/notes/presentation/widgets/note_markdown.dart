import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/note_parsing.dart';

/// Rendered note body: full markdown plus the vault's own inline
/// grammar — `[[wiki links]]` open (or create) their note, `#tags` wear
/// the brand tint. One widget so preview, and later graph previews,
/// render identically.
class NoteMarkdown extends StatelessWidget {
  const NoteMarkdown({super.key, required this.data, this.onOpenLink});

  final String data;

  /// Called with the raw link target (`[[target|alias]]` → `target`).
  final ValueChanged<String>? onOpenLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return MarkdownBody(
      data: data,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [_WikiLinkSyntax(), _NoteTagSyntax()],
      builders: {
        'wikilink': _WikiLinkBuilder(onOpen: onOpenLink),
        'notetag': _NoteTagBuilder(),
      },
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        blockquoteDecoration: BoxDecoration(
          color: scheme.primaryTint,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border(
            left: BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
        codeblockDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: scheme.outlineVariant),
          ),
        ),
      ),
    );
  }
}

/// `[[target]]` / `[[target|alias]]` / `[[target#heading]]` — must sit
/// ahead of the standard link syntax, which flutter_markdown guarantees
/// for custom inline syntaxes.
class _WikiLinkSyntax extends md.InlineSyntax {
  _WikiLinkSyntax() : super(NoteParsing.wikiLinkPattern.pattern);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final link = NoteParsing.parseLinkBody(match[1]!);
    if (link.target.isEmpty) return false;
    final element = md.Element.text('wikilink', link.display);
    element.attributes['target'] = link.target;
    parser.addNode(element);
    return true;
  }
}

class _WikiLinkBuilder extends MarkdownElementBuilder {
  _WikiLinkBuilder({this.onOpen});

  final ValueChanged<String>? onOpen;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final target = element.attributes['target'] ?? element.textContent;
    final style = (parentStyle ?? preferredStyle);
    return GestureDetector(
      onTap: onOpen == null ? null : () => onOpen!(target),
      child: Text(
        element.textContent,
        style: (style ?? const TextStyle()).copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

/// `#tag` — worn quietly inline; tag pages arrive with the graph.
class _NoteTagSyntax extends md.InlineSyntax {
  _NoteTagSyntax() : super(NoteParsing.tagPattern.pattern);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.text('notetag', '#${match[1]!}');
    parser.addNode(element);
    return true;
  }
}

class _NoteTagBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final style = (parentStyle ?? preferredStyle);
    return Text(
      element.textContent,
      style: (style ?? const TextStyle()).copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
