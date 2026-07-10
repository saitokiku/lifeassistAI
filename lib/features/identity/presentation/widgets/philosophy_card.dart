import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../settings/application/settings_controller.dart';

/// The user's personal line — a short reminder of how they want to live.
/// Tap anywhere (or the pencil) to edit; it saves via settings.
class PhilosophyCard extends ConsumerWidget {
  const PhilosophyCard({super.key, required this.philosophyText});

  final String philosophyText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final line = philosophyText.trim();
    final hasLine = line.isNotEmpty;

    return AppCard(
      tinted: true,
      onTap: () => _edit(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'YOUR LINE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Edit your line',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => _edit(context),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: theme.colorScheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            hasLine
                ? line
                : 'A short line that reminds you what this is all for. '
                    'Optional.',
            style: hasLine
                ? theme.textTheme.titleMedium?.copyWith(height: 1.4)
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final saved = await showAppSheet<bool>(
      context,
      builder: (_) => _PhilosophyEditor(initial: philosophyText),
    );
    if (saved == true && context.mounted) {
      showSuccessSnack(context, 'Saved.');
    }
  }
}

class _PhilosophyEditor extends ConsumerStatefulWidget {
  const _PhilosophyEditor({required this.initial});

  final String initial;

  @override
  ConsumerState<_PhilosophyEditor> createState() => _PhilosophyEditorState();
}

class _PhilosophyEditorState extends ConsumerState<_PhilosophyEditor> {
  late final _line = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(settingsControllerProvider)
          .setPhilosophyText(_line.text.trim());
      Haptics.medium();
      navigator.pop(true);
    } catch (_) {
      if (mounted) {
        showErrorSnack(context, "That didn't save. Try again.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: 'Your line',
      subtitle: 'A sentence that keeps you pointed the right way.',
      footer: AppSheetButton(label: 'Save', onPressed: _save),
      children: [
        AppTextField(
          label: 'Your line',
          controller: _line,
          maxLines: 2,
          autofocus: true,
        ),
      ],
    );
  }
}
