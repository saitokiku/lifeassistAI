/// Identity statements and the fixed philosophy triad.
library;

export '../../../core/storage/app_database.dart' show IdentityStatement;

/// The triad the whole app is built around. The philosophy header text is
/// user-editable in settings; the triad itself is the product's spine.
class LifePhilosophy {
  LifePhilosophy._();

  static const scoreboard = 'Money = scoreboard';
  static const engine = 'Curiosity = engine';
  static const goal = 'Freedom = actual goal';

  static const triad = [scoreboard, engine, goal];
}
