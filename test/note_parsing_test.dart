import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/features/notes/domain/note_parsing.dart';

void main() {
  group('NoteParsing.parse — links', () {
    test('finds plain wiki links in order', () {
      final p = NoteParsing.parse('See [[Alpha]] then [[Beta]].');
      expect(p.links, ['Alpha', 'Beta']);
    });

    test('alias and heading forms resolve to the bare target', () {
      final p = NoteParsing.parse(
        'A [[Deep Work|that book]] and [[Habits#Cues]] reference.',
      );
      expect(p.links, ['Deep Work', 'Habits']);
    });

    test('dedupes case-insensitively, keeps first spelling', () {
      final p = NoteParsing.parse('[[Apple]] and [[apple]] and [[APPLE]]');
      expect(p.links, ['Apple']);
    });

    test('ignores links inside fenced and inline code', () {
      final p = NoteParsing.parse(
        'Real [[One]].\n```\n[[Fenced]]\n```\nAnd `[[inline]]` too.',
      );
      expect(p.links, ['One']);
    });

    test('empty or bracket-only targets are skipped', () {
      final p = NoteParsing.parse('[[ ]] and [[|alias only]]');
      expect(p.links, isEmpty);
    });
  });

  group('NoteParsing.parse — tags', () {
    test('finds tags, lowercases, dedupes', () {
      final p = NoteParsing.parse('#Focus work and #focus again, #deep-work.');
      expect(p.tags, ['focus', 'deep-work']);
    });

    test('nested tags keep the slash', () {
      final p = NoteParsing.parse('Filed under #area/health today.');
      expect(p.tags, ['area/health']);
    });

    test('pure numbers and mid-word hashes are not tags', () {
      final p = NoteParsing.parse('Issue #123 and C#minor but #v2 is fine.');
      expect(p.tags, ['v2']);
    });

    test('markdown headings are not tags', () {
      final p = NoteParsing.parse('# Heading\n\nBody with #real tag.');
      expect(p.tags, ['real']);
    });

    test('tag at start of note and after parenthesis', () {
      final p = NoteParsing.parse('#first thing (#second)');
      expect(p.tags, ['first', 'second']);
    });
  });

  group('NoteParsing.parseLinkBody', () {
    test('plain, alias, heading, alias+heading', () {
      expect(NoteParsing.parseLinkBody('Target').target, 'Target');
      expect(NoteParsing.parseLinkBody('Target').display, 'Target');
      final aliased = NoteParsing.parseLinkBody('Target|Shown');
      expect(aliased.target, 'Target');
      expect(aliased.display, 'Shown');
      expect(NoteParsing.parseLinkBody('Target#Section').target, 'Target');
      final both = NoteParsing.parseLinkBody('Target#Section|Shown');
      expect(both.target, 'Target');
      expect(both.display, 'Shown');
    });
  });

  group('NoteParsing.zettelId', () {
    test('is the sortable timestamp form', () {
      expect(
        NoteParsing.zettelId(DateTime(2026, 7, 17, 9, 5, 3)),
        '20260717090503',
      );
    });
  });
}
