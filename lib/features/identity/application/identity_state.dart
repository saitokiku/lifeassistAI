import '../../../core/storage/app_database.dart';

/// Display-ready identity state.
class IdentityState {
  const IdentityState({
    required this.statements,
    required this.freedomTargets,
    required this.philosophyText,
  });

  final List<IdentityStatement> statements;
  final List<FreedomTarget> freedomTargets;
  final String philosophyText;

  FreedomTarget? get primaryFreedomTarget =>
      freedomTargets.isEmpty ? null : freedomTargets.first;
}
