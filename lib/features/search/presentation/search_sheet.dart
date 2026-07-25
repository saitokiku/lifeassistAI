import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../data/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(databaseProvider)),
);

/// Everything-search: one field over transactions, ideas, milestones,
/// habits, reminders, time notes, and principles. A hit jumps to its tab.
class SearchSheet extends ConsumerStatefulWidget {
  const SearchSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showAppSheet<void>(context, builder: (_) => const SearchSheet());

  @override
  ConsumerState<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends ConsumerState<SearchSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  List<SearchHit> _hits = const [];
  bool _searched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  /// Monotonic id so a slow query for "co" can't overwrite the newer
  /// results for "coffee" when it finally resolves.
  int _requestId = 0;

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final request = ++_requestId;
      final hits = await ref.read(searchRepositoryProvider).search(text);
      if (!mounted || request != _requestId) return;
      setState(() {
        _hits = hits;
        _searched = text.trim().length >= 2;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final groups = <String, List<SearchHit>>{};
    for (final h in _hits) {
      groups.putIfAbsent(h.group, () => []).add(h);
    }

    return AppSheet(
      title: 'Search',
      subtitle: 'Everything you\'ve written, one field.',
      children: [
        TextField(
          controller: _query,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'coffee, stretch, rent…',
            prefixIcon: Icon(Icons.search_rounded, size: 20),
          ),
          onChanged: _onChanged,
        ),
        const SizedBox(height: AppSpace.md),
        if (_searched && _hits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: Text(
              'Nothing matches. Different word, maybe.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        for (final entry in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpace.md,
              bottom: AppSpace.xs,
            ),
            child: Text(
              entry.key.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.brandLabel,
              ),
            ),
          ),
          for (final hit in entry.value)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                hit.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                hit.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.textTertiary,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.textTertiary,
              ),
              onTap: () {
                Navigator.of(context).pop();
                context.go(hit.route);
              },
            ),
        ],
      ],
    );
  }
}
