import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/capture/capture_launcher.dart';
import '../core/capture/capture_parser.dart';
import '../core/capture/capture_request.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../features/dashboard/application/dashboard_controller.dart';
import '../features/focus/application/focus_controller.dart';
import '../features/focus/presentation/widgets/growth_metric_entry_form.dart';
import '../shared/haptics.dart';
import '../shared/widgets/app_sheet.dart';
import '../shared/widgets/loading_view.dart';
import 'app_icons.dart';
import 'pressable.dart';

/// The Universal Capture Inbox: speak, type, paste, or drop a photo of
/// anything — a receipt, a bank line, "2h deep work and coffee 4.50" —
/// and it gets sorted into typed capture chips that save through the
/// same forms Siri and deep links use. Voice via on-device speech
/// recognition; photos via the Vision OCR bridge (iOS). Everything
/// parses deterministically on-device — no cloud, ever.
class CaptureInbox extends ConsumerStatefulWidget {
  const CaptureInbox({super.key});

  static Future<void> show(BuildContext context) =>
      showAppSheet<void>(context, builder: (_) => const CaptureInbox());

  @override
  ConsumerState<CaptureInbox> createState() => _CaptureInboxState();
}

sealed class _Entry {}

class _UserEntry extends _Entry {
  _UserEntry(this.text, {this.fromPhoto = false});
  final String text;
  final bool fromPhoto;
}

class _ItemsEntry extends _Entry {
  _ItemsEntry(this.items);
  final List<ParsedCapture> items;
  final Set<int> saved = {};
}

class _CaptureInboxState extends ConsumerState<CaptureInbox> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _entries = <_Entry>[];
  final _speech = stt.SpeechToText();
  bool _listening = false;
  bool _ocrBusy = false;

  static const _vision = MethodChannel('lifeassist/vision');

  bool get _canListen => !kIsWeb;
  bool get _canOcr => !kIsWeb && Platform.isIOS;

  @override
  void dispose() {
    _speech.stop();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!available) {
      if (mounted) {
        showErrorSnack(
            context, 'Speech recognition is not available on this device.');
      }
      return;
    }
    Haptics.medium();
    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(partialResults: true),
      onResult: (result) {
        _input.text = result.recognizedWords;
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          setState(() => _listening = false);
          _send();
        }
      },
    );
  }

  Future<void> _pickImage() async {
    if (_ocrBusy) return;
    setState(() => _ocrBusy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final bytes = result?.files.single.bytes;
      if (bytes == null) return;
      final text = await _vision.invokeMethod<String>(
          'recognizeText', Uint8List.fromList(bytes));
      if (!mounted) return;
      if (text == null || text.trim().isEmpty) {
        showErrorSnack(context, 'No readable text in that image.');
        return;
      }
      _send(prefill: text, fromPhoto: true);
    } catch (_) {
      if (mounted) {
        showErrorSnack(context, "Couldn't read that image. Try another.");
      }
    } finally {
      if (mounted) setState(() => _ocrBusy = false);
    }
  }

  void _send({String? prefill, bool fromPhoto = false}) {
    final text = (prefill ?? _input.text).trim();
    if (text.isEmpty) return;
    if (prefill == null) _input.clear();
    final items = CaptureParser.parse(text);
    setState(() {
      _entries.add(_UserEntry(text, fromPhoto: fromPhoto));
      _entries.add(_ItemsEntry(items));
    });
    Haptics.light();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: AppMotion.standard,
          curve: AppMotion.easeOut,
        );
      }
    });
  }

  Future<void> _saveItem(_ItemsEntry entry, int index) async {
    final item = entry.items[index];
    await CaptureLauncher.open(context, ref, item.request);
    if (!mounted) return;
    setState(() => entry.saved.add(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
          const SizedBox(height: AppSpace.md),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: Row(
              children: [
                const Icon(AppIcons.sparkle,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text('Capture', style: theme.textTheme.titleLarge),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xs),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Speak, type, paste, or drop a photo — it gets sorted.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Expanded(
            child: _entries.isEmpty
                ? _Shortcuts(onDone: () {})
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen,
                      AppSpace.sm,
                      AppSpace.screen,
                      AppSpace.md,
                    ),
                    itemCount: _entries.length,
                    itemBuilder: (context, i) => switch (_entries[i]) {
                      final _UserEntry e => _UserBubble(entry: e),
                      final _ItemsEntry e => _ItemsBubble(
                          entry: e,
                          onSave: (index) => _saveItem(e, index),
                        ),
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.md,
              AppSpace.sm,
              AppSpace.md,
              AppSpace.lg,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_canOcr)
                  Tooltip(
                    message: 'Read a photo',
                    child: Pressable(
                      onTap: _ocrBusy ? null : _pickImage,
                      semanticLabel: 'Read a photo',
                      dense: true,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpace.sm),
                        child: _ocrBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Icon(AppIcons.image,
                                size: 22, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: _listening
                          ? 'Listening…'
                          : 'coffee 4.50 · 2h deep work · remind me…',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                if (_canListen)
                  Tooltip(
                    message: _listening ? 'Stop listening' : 'Speak',
                    child: Pressable(
                      onTap: _toggleMic,
                      haptic: PressHaptic.medium,
                      semanticLabel: _listening ? 'Stop listening' : 'Speak',
                      dense: true,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _listening
                              ? AppColors.critical.withValues(alpha: 0.18)
                              : scheme.primaryTint,
                        ),
                        child: Icon(
                          AppIcons.mic,
                          size: 20,
                          color: _listening
                              ? AppColors.critical
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpace.xs),
                Tooltip(
                  message: 'Sort it',
                  child: Pressable(
                    onTap: _send,
                    haptic: PressHaptic.light,
                    semanticLabel: 'Sort it',
                    dense: true,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: const Icon(AppIcons.send,
                          size: 20, color: AppColors.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

/// The one-tap manual paths (the old quick-add grid), shown until the
/// first message — familiar, and the fallback when typing feels slower.
class _Shortcuts extends ConsumerWidget {
  const _Shortcuts({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(dashboardStateProvider);
    final entries = <(String, IconData, Future<void> Function())>[
      if (state?.goalActive ?? false)
        (
          'Goal step',
          AppIcons.focus,
          () => CaptureLauncher.open(context, ref,
              const CaptureRequest(type: CaptureType.step)),
        ),
      (
        'Add expense',
        AppIcons.money,
        () => CaptureLauncher.open(context, ref,
            const CaptureRequest(type: CaptureType.expense)),
      ),
      (
        'Log time',
        AppIcons.time,
        () => CaptureLauncher.open(
            context, ref, const CaptureRequest(type: CaptureType.time)),
      ),
      if (state?.goalActive ?? false)
        (
          'Measure value',
          AppIcons.review,
          () async {
            final metric = ref.read(focusStateProvider)?.activeMetric;
            if (metric == null) return;
            await GrowthMetricEntryForm.show(context, metric: metric);
          },
        ),
      (
        'Park an idea',
        AppIcons.ideas,
        () => CaptureLauncher.open(
            context, ref, const CaptureRequest(type: CaptureType.idea)),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      children: [
        Text(
          'Quick add',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final (label, icon, action) in entries)
              Pressable(
                onTap: () => action(),
                haptic: PressHaptic.select,
                semanticLabel: label,
                dense: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.md,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.elevated,
                    borderRadius: BorderRadius.circular(AppRadius.tile),
                    border:
                        Border.all(color: theme.colorScheme.outlineFaint),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpace.sm),
                      Text(label, style: theme.textTheme.labelLarge),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.entry});

  final _UserEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.sm, left: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.tile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (entry.fromPhoto)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'from photo',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Text(
              entry.text.length > 400
                  ? '${entry.text.substring(0, 400)}…'
                  : entry.text,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemsBubble extends StatelessWidget {
  const _ItemsBubble({required this.entry, required this.onSave});

  final _ItemsEntry entry;
  final ValueChanged<int> onSave;

  IconData _icon(CaptureType type) => switch (type) {
        CaptureType.expense => AppIcons.money,
        CaptureType.time => AppIcons.time,
        CaptureType.step => AppIcons.focus,
        CaptureType.idea => AppIcons.ideas,
        CaptureType.reminder => AppIcons.reminders,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpace.md, right: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.items.length == 1
                  ? 'Sorted — tap to confirm:'
                  : 'Sorted into ${entry.items.length} — tap each to confirm:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Wrap(
              spacing: AppSpace.xs,
              runSpacing: AppSpace.xs,
              children: [
                for (final (i, item) in entry.items.indexed)
                  Pressable(
                    onTap: entry.saved.contains(i) ? null : () => onSave(i),
                    haptic: PressHaptic.select,
                    semanticLabel: item.summary,
                    dense: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.sm,
                      ),
                      decoration: BoxDecoration(
                        color: entry.saved.contains(i)
                            ? scheme.primaryTint
                            : scheme.elevated,
                        borderRadius: BorderRadius.circular(AppRadius.chip),
                        border: Border.all(
                          color: entry.saved.contains(i)
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : scheme.outlineFaint,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            entry.saved.contains(i)
                                ? AppIcons.done
                                : _icon(item.request.type),
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpace.xs),
                          Flexible(
                            child: Text(
                              item.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
