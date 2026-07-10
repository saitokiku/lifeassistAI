import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validation.dart';
import '../../../../shared/haptics.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../application/accounts_controller.dart';
import '../../domain/account_kind.dart';
import 'money_field.dart';

/// Create or edit a tracked account.
class AccountEditor extends ConsumerStatefulWidget {
  const AccountEditor({super.key, this.account});

  final Account? account;

  static Future<void> show(BuildContext context, {Account? account}) =>
      showAppSheet<void>(
        context,
        builder: (_) => AccountEditor(account: account),
      );

  @override
  ConsumerState<AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<AccountEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.account?.name ?? '');
  late final _balance = TextEditingController(
      text: widget.account == null
          ? ''
          : Formatters.number(widget.account!.balance, maxDecimals: 2));
  late AccountKind _kind = widget.account == null
      ? AccountKind.checking
      : AccountKind.parse(widget.account!.kind);
  late bool _includeInNetWorth = widget.account?.includeInNetWorth ?? true;
  bool _busy = false;

  bool get _editing => widget.account != null;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    _busy = true;
    final controller = ref.read(accountsControllerProvider);
    final navigator = Navigator.of(context);
    final balance = Validators.parseNumber(_balance.text);
    try {
      if (widget.account == null) {
        await controller.createAccount(
          name: _name.text.trim(),
          kind: _kind,
          balance: balance,
          includeInNetWorth: _includeInNetWorth,
        );
      } else {
        await controller.updateAccount(
          widget.account!.copyWith(
            name: _name.text.trim(),
            kind: _kind.name,
            balance: balance,
            includeInNetWorth: _includeInNetWorth,
          ),
          balanceChanged: balance != widget.account!.balance,
        );
      }
    } catch (_) {
      _busy = false;
      if (mounted) showErrorSnack(context, "That didn't save. Try again.");
      return;
    }
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Saved.');
    navigator.pop();
  }

  Future<void> _delete() async {
    final account = widget.account!;
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${account.name}?',
      message: 'Its balance history goes too. Imported transactions stay, '
          'just without the account tag. No undo.',
      confirmLabel: 'Delete account',
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(accountsControllerProvider).deleteAccount(account.id);
    } catch (_) {
      if (mounted) showErrorSnack(context, "That didn't delete. Try again.");
      return;
    }
    Haptics.medium();
    if (!mounted) return;
    showSuccessSnack(context, 'Account deleted.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      title: _editing ? 'Edit account' : 'New account',
      subtitle: _editing
          ? null
          : 'A bank, card, cash stash, or investment pot to track.',
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSheetButton(label: 'Save', onPressed: _save),
          if (_editing) ...[
            const SizedBox(height: AppSpace.sm),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.critical),
              onPressed: _delete,
              child: const Text('Delete account'),
            ),
          ],
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                label: 'Name',
                hint: 'e.g. Chase checking',
                controller: _name,
                autofocus: !_editing,
                validator: (v) => Validators.required(v, label: 'Name'),
              ),
              const SizedBox(height: AppSpace.md),
              MoneyField(
                label: _kind == AccountKind.credit
                    ? 'Current balance owed'
                    : 'Current balance',
                controller: _balance,
                validator: (v) => Validators.number(v, label: 'Balance'),
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final kind in AccountKind.values)
                    ChoiceChip(
                      avatar: Icon(
                        kind.icon,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      label: Text(kind.label),
                      selected: _kind == kind,
                      showCheckmark: false,
                      onSelected: (_) {
                        Haptics.select();
                        setState(() => _kind = kind);
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Count toward net worth'),
                subtitle: Text(
                  _kind == AccountKind.credit
                      ? 'Credit balances subtract.'
                      : 'Assets add.',
                ),
                value: _includeInNetWorth,
                onChanged: (v) {
                  Haptics.select();
                  setState(() => _includeInNetWorth = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
