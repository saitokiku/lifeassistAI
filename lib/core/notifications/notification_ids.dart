/// The app's OS-notification id space, partitioned so that no two
/// owners can ever collide.
///
/// The previous scheme derived ids from `String.hashCode` and spaced
/// weekday variants by a large stride. Two problems: `String.hashCode`
/// is not stable across platforms or SDK versions (this repo already
/// knows that — see `stableHash` in `notes/graph/graph_model.dart`), so
/// a shifted hash orphaned pending notifications beyond cancellation;
/// and "reminders and habits have their own id spaces" was not true —
/// namespacing the hashed *input* does not partition the output range,
/// so a habit's weekday variant could silently cancel a reminder.
///
/// The layout below makes both problems structural rather than
/// probabilistic:
///
/// ```
/// bit 30 clear — schedules   base = slot * 8, weekday variant = base + 1..7
/// bit 30 set   — snoozes     snoozeFor(base) = base | snoozeFlag
/// ```
///
/// Every owner holds one aligned block of 8 consecutive ids, so its
/// seven weekday variants can never reach into another owner's block.
/// Ids are allocated once and **stored** (`reminders.notificationId`,
/// `habits.notificationId`), never re-derived.
class NotificationIds {
  NotificationIds._();

  /// Ids per owner: one base + seven weekday variants.
  static const int slotSize = 8;

  /// Snooze ids live above this bit; schedule ids live below it.
  static const int snoozeFlag = 0x40000000;

  /// Highest usable base (exclusive) — keeps every base and variant
  /// below [snoozeFlag].
  static const int maxBase = snoozeFlag;

  /// True for an id this scheme could have produced as a base.
  static bool isBase(int id) => id > 0 && id < maxBase && id % slotSize == 0;

  /// The id for [weekday] (`DateTime.monday`..`DateTime.sunday`) of the
  /// owner whose base is [base].
  static int weekdayId(int base, int weekday) => base + weekday;

  /// Every id an owner may occupy — what a resync must cancel.
  static Iterable<int> blockFor(int base) sync* {
    yield base;
    for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      yield weekdayId(base, weekday);
    }
  }

  /// The transient id a snoozed notification reschedules onto.
  static int snoozeFor(int id) => (id & (snoozeFlag - 1)) | snoozeFlag;

  /// The first base not in [taken], scanning up from slot 1 (slot 0 is
  /// reserved so that 0 always means "unassigned").
  static int allocate(Iterable<int> taken) {
    final used = taken.toSet();
    for (var slot = 1; slot * slotSize < maxBase; slot++) {
      final base = slot * slotSize;
      if (!used.contains(base)) return base;
    }
    throw StateError('Notification id space exhausted');
  }

  /// Allocates [count] distinct bases in one pass.
  static List<int> allocateMany(Iterable<int> taken, int count) {
    final used = taken.toSet();
    final out = <int>[];
    var slot = 1;
    while (out.length < count) {
      final base = slot * slotSize;
      if (base >= maxBase) throw StateError('Notification id space exhausted');
      if (used.add(base)) out.add(base);
      slot++;
    }
    return out;
  }
}
